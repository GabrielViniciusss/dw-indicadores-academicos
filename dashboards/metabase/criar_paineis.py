#!/usr/bin/env python3
"""Cria uma coleção nova, 13 perguntas e quatro dashboards pela API do Metabase.
Não configura usuários nem altera perguntas preexistentes. Reexecutar cria outra coleção.
"""
import argparse
import getpass
import json
import urllib.error
import urllib.request
from pathlib import Path

HERE = Path(__file__).resolve().parent
PANELS = [
    ('1. Visão geral', [1, 2, 3]),
    ('2. Desempenho acadêmico', [5, 6, 8, 12]),
    ('3. Permanência e equidade', [9, 10, 11, 13]),
    ('4. Turmas e docência', [4, 7]),
]
# Primeira configuração de gráficos. As dimensões do SQL permanecem na pergunta.
CHARTS = {
    1: ('line', ['ano_semestre', 'nome_disciplina'], ['taxa_aprovacao']),
    2: ('bar', ['nome_disciplina', 'ano_semestre'], ['reprovacao_nota', 'reprovacao_falta']),
    3: ('bar', ['nome_disciplina', 'ano_semestre'], ['aprovado_nota', 'aprovado_final', 'reprovado_nota', 'reprovado_falta', 'trancado']),
    4: ('bar', ['nome_professor', 'codigo_curso'], ['diferenca_pontos']),
    5: ('table', [], []),  # mapa de calor: aplicar formatação condicional no editor
    6: ('scatter', ['media_faltas'], ['taxa_reprovacao']),
    7: ('table', [], []),
    8: ('bar', ['periodo_aluno', 'ano_semestre'], ['reprovacoes_nota', 'reprovacoes_falta']),
    9: ('bar', ['ano_semestre_ingresso', 'codigo_curso'], ['concluiu', 'ativo', 'evadiu']),
    10: ('table', [], []),  # dois gráficos separados: reprovação e evasão
    11: ('bar', ['ano_semestre_ingresso', 'codigo_curso'], ['media_semestres', 'semestres_previstos']),
    12: ('bar', ['tentativa', 'nome_disciplina'], ['taxa_aprovacao']),
    13: ('line', ['ano_semestre', 'grupo'], ['taxa_reprovacao']),
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--url', default='http://localhost:3033')
    parser.add_argument('--database-id', type=int, required=True, help='ID do banco dw_academico conectado no Metabase')
    parser.add_argument('--email', required=True)
    args = parser.parse_args()
    base = args.url.rstrip('/')
    if not base.startswith(('http://localhost:', 'http://127.0.0.1:', 'https://')):
        parser.error('Use localhost ou HTTPS para transmitir a autenticação.')
    session = None

    def api(method, path, payload=None):
        headers = {'Content-Type': 'application/json'}
        if session:
            headers['X-Metabase-Session'] = session
        request = urllib.request.Request(base+'/api'+path, method=method, headers=headers,
                                         data=json.dumps(payload).encode() if payload is not None else None)
        with urllib.request.urlopen(request, timeout=120) as response:
            body = response.read()
            return json.loads(body) if body else None

    password = getpass.getpass('Senha do Metabase (não será salva): ')
    session = api('POST', '/session', {'username': args.email, 'password': password})['id']
    password = None
    try:
        database = api('GET', f'/database/{args.database_id}')
        if database['engine'] != 'mysql':
            raise ValueError('O banco selecionado precisa ser MySQL 8.')
        collection = api('POST', '/collection', {'name': 'Indicadores acadêmicos · SINTÉTICOS',
                                              'description': 'Demonstração da aula de 05/11/2026; não representa dados reais da UFPE.'})
        for name, numbers in PANELS:
            dashboard = api('POST', '/dashboard', {'name': name+' · SINTÉTICOS', 'collection_id': collection['id'],
                            'description': 'Dados sintéticos. Configuração inicial; revisar filtros e gráficos conforme LEIA-ME.'})
            dashcards = []
            for position, number in enumerate(numbers):
                sql = (HERE / f'C{number:02}.sql').read_text(encoding='utf-8')
                title = sql.splitlines()[0].removeprefix('-- ')
                display, dimensions, metrics = CHARTS[number]
                settings = {'graph.dimensions': dimensions, 'graph.metrics': metrics} if dimensions else {}
                if number in (2, 3, 8, 9):
                    settings['stackable.stack_type'] = 'stacked'
                card = api('POST', '/card', {'name': title, 'collection_id': collection['id'],
                           'type': 'question', 'display': display, 'visualization_settings': settings,
                           'description': 'Dados sintéticos. Fonte: sql/05_consultas.sql. Revisar recorte antes da apresentação.',
                           'dataset_query': {'database': args.database_id, 'type': 'native', 'native': {'query': sql}}})
                dashcards.append({'id': -(position+1), 'card_id': card['id'], 'row': position//2*8,
                                  'col': position%2*12, 'size_x': 12, 'size_y': 8})
            api('PUT', f'/dashboard/{dashboard["id"]}', {'dashcards': dashcards})
            print(f'{name}: {base}/dashboard/{dashboard["id"]}')
    finally:
        api('DELETE', '/session', {'session_id': session})


if __name__ == '__main__':
    try:
        main()
    except (urllib.error.URLError, ValueError, KeyError) as error:
        raise SystemExit(f'Não foi possível concluir: {error}. Consulte a coleção antes de repetir; podem existir itens parciais.')
