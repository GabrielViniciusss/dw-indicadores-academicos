#!/usr/bin/env python3
"""Confere os cálculos JavaScript contra as 13 consultas SQL em SQLite em memória."""
import json
import re
import sqlite3
import subprocess
from collections import defaultdict
from html.parser import HTMLParser
from pathlib import Path
from build_demo import read_table

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


class ScriptParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.scripts = []
        self.in_script = False
        self.body_closed = False

    def handle_starttag(self, tag, attrs):
        if tag == 'script':
            self.in_script = True
            self.scripts.append('')

    def handle_endtag(self, tag):
        if tag == 'script':
            self.in_script = False
        elif tag == 'body':
            self.body_closed = True

    def handle_data(self, content):
        if self.in_script:
            self.scripts[-1] += content


# Live Server precisa de </body> fora dos scripts para inserir a atualização.
# Sem ele, usa </svg>, que neste protótipo também existe em strings JavaScript.
html = (HERE / 'painel_academico_interativo.html').read_text(encoding='utf-8')
parser = ScriptParser()
parser.feed(html)
assert parser.body_closed, 'O HTML deve fechar explicitamente o body para suportar Live Server.'
with_live_server = html.replace('</body>', '<script>window.__live_server_probe = true;</script></body>', 1)
parser = ScriptParser()
parser.feed(with_live_server)
assert len(parser.scripts) == 3, 'A injeção do Live Server deve ficar fora dos scripts do painel.'
subprocess.run(['node', '-e', "const vm=require('node:vm');let s='';process.stdin.on('data',c=>s+=c);process.stdin.on('end',()=>JSON.parse(s).forEach(code=>new vm.Script(code)));"],
               input=json.dumps(parser.scripts), text=True, capture_output=True, check=True)
print('HTML com injeção de atualização do Live Server: scripts íntegros e sintaxe válida.')

names = [p.stem for p in (ROOT / 'dados/csv').glob('*.csv')]
data = {name: read_table(name) for name in names}
connection = sqlite3.connect(':memory:')
connection.row_factory = sqlite3.Row
for name, rows in data.items():
    columns = list(rows[0])
    numeric = {key for r in rows for key, v in r.items() if isinstance(v, (float, int))}
    types = {k: ('INTEGER' if k == 'qtd_tentativas' else 'REAL') if k in numeric else 'TEXT' for k in columns}
    schema = ','.join(f'"{k}" {types[k]}' for k in columns)
    connection.execute(f'CREATE TABLE "{name}" ({schema})')
    connection.executemany(f'INSERT INTO "{name}" VALUES ({",".join("?" for _ in columns)})',
                           [[r[k] for k in columns] for r in rows])
# O CSV da fato agregada traz contagens como strings: SQLite aplica afinidade REAL nas somas.
actual = json.loads(subprocess.run(['node', str(HERE / 'validar_modelo.cjs')], input=json.dumps(data), text=True,
                                capture_output=True, check=True, cwd=HERE).stdout)
print('Modelo: filtros combinados, docente, períodos, cota/renda e comparação semestral com bases ausentes: OK.')
sql = (ROOT / 'sql/05_consultas.sql').read_text()
for number, body in re.findall(r'-- C(\d+)\. (.*?)(?=\n-- C\d+\.|\Z)', sql, re.S):
    query = body.split('\n', 1)[1].strip().replace('100 *', '100.0 *')
    # ROW_NUMBER original não desempata taxas iguais. Usa ID para reproduzir a escolha do protótipo.
    if number == '2':
        query = query.replace('ORDER BY p.por_nota + p.por_falta DESC)', 'ORDER BY ROUND(p.por_nota + p.por_falta, 9) DESC, p.id_disciplina)')
    expected = [dict(r) for r in connection.execute(query)]
    result = actual['C'+number]
    assert len(result) == len(expected), (number, len(result), len(expected))
    textkeys = [k for k, v in (expected[0] if expected else {}).items() if isinstance(v, str)]
    def index(rows):
        groups = defaultdict(list)
        for row in rows:
            groups[tuple(row[k] for k in textkeys)].append(row)
        return groups
    # Algumas linhas diferem apenas em medidas; ordenar resolve multiplicidades.
    a, b = index(expected), index(result)
    assert a.keys() == b.keys(), (number, 'chaves')
    for key in a:
        order = lambda row: tuple(-1e30 if row[k] is None else row[k] for k in row if k not in textkeys)
        for want, got in zip(sorted(a[key], key=order), sorted(b[key], key=order)):
            assert want.keys() == got.keys(), (number, 'colunas')
            for k, v in want.items():
                if isinstance(v, (float, int)):
                    assert got[k] is not None and abs(v-got[k]) <= .051, (number, key, k, v, got[k])
                else:
                    assert v == got[k], (number, key, k, v, got[k])
    print(f'C{number}: {len(expected)} linhas conferem com SQL (tolerância de arredondamento: 0,051).')
print('Recorte vazio e filtros combinados: OK. SQLite verifica semântica; execução nativa requer MySQL 8.')
