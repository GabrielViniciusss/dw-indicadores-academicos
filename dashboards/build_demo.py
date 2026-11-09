#!/usr/bin/env python3
"""Empacota os CSVs existentes em um HTML offline. Não gera outra população."""
import csv
import json
import re
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent


def read_table(name):
    with (ROOT / 'dados/csv' / f'{name}.csv').open(encoding='utf-8', newline='') as stream:
        rows = list(csv.DictReader(stream))
    for row in rows:
        for key, value in row.items():
            if value in ('', 'NULL'):
                row[key] = None
            elif key.startswith(('id_', 'qtd_', 'quantidade_', 'periodo_', 'semestres_')) or key in ('ano', 'semestre', 'ano_ingresso', 'semestre_ingresso', 'bolsista_no_semestre', 'nota_final'):
                row[key] = float(value) if '.' in value else int(value)
    return rows


def main():
    names = ['dim_data', 'dim_curso', 'dim_disciplina', 'curso_disciplina', 'dim_professor',
             'dim_turma_aluno', 'dim_aluno', 'dim_turma_disciplina', 'fato_professor_aluno',
             'vw_turma_professor']
    data = {name: read_table(name) for name in names}
    template = (HERE / 'template.html').read_text(encoding='utf-8')
    payload = json.dumps(data, ensure_ascii=False, separators=(',', ':')).replace('<', '\\u003c')
    output = template.replace('/* EMBED_DATA */', f'const DATA = {payload};')
    app = (HERE / 'painel.js').read_text(encoding='utf-8')
    app = app.replace('/* EXPLORATION_HELPERS */', (HERE / 'exploracao.js').read_text(encoding='utf-8'))
    output = output.replace('/* EMBED_APP */', app)
    (HERE / 'painel_academico_interativo.html').write_text(output, encoding='utf-8')
    # Cada arquivo contém uma consulta do SQL original, sem o comando USE.
    sql = (ROOT / 'sql/05_consultas.sql').read_text(encoding='utf-8')
    for number, body in re.findall(r'-- C(\d+)\. (.*?)(?=\n-- C\d+\.|\Z)', sql, re.S):
        title, query = body.split('\n', 1)
        (HERE / 'metabase' / f'C{int(number):02}.sql').write_text(
            f'-- C{number}. {title}\n-- DADOS SINTÉTICOS; não representam a UFPE.\n{query.strip()}\n', encoding='utf-8')
    print(f'HTML offline: {HERE / "painel_academico_interativo.html"}')
    print(f'{len(data["dim_aluno"])} alunos; {len(data["fato_professor_aluno"])} matrículas sintéticas.')


if __name__ == '__main__':
    main()
