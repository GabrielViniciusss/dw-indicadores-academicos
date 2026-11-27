# DW de indicadores acadêmicos

Trabalho da disciplina de Data Warehouse (UFPE): um esquema MySQL com três tabelas fato (duas estrelas e um snapshot do vínculo) que compartilham dimensões, 15 consultas analíticas e painéis de indicadores. Todos os dados são sintéticos e não descrevem a UFPE.

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

## Entregas

**30/11, relatório final.** O [relatório final](docs/relatorio_final.pdf) segue as seis seções do roteiro do professor: contexto e perguntas de negócio, fatos e tipos de medida, dimensões com valores especiais e SCD, técnicas de projeto, as 15 consultas em SQL e os gráficos. A fonte é [`docs/relatorio_final/relatorio.html`](docs/relatorio_final/relatorio.html). O SQL entra no PDF direto de `sql/05_consultas.sql`, e as figuras são capturadas do painel. Para esta entrega, o modelo ganhou o snapshot `fato_vinculo_semestre` e as consultas C13 (atraso na matriz curricular), C14 (Taxa de Sucesso na Graduação) e C15 (TAP, TCA e TDA do INEP).

**03/11, construção dos esquemas.** O [PDF da entrega](docs/entrega_05_11.pdf), atualizado em 05/11, traz as 12 consultas em ordem de prioridade, com o gráfico escolhido para cada uma e o porquê, os ajustes no esquema e os dados sintéticos. As consultas estão em [`sql/05_consultas.sql`](sql/05_consultas.sql), com a mesma numeração.

**05/11, visualização dos dados.** Três protótipos de painel, todos sobre os mesmos dados:

- **Painel interativo:** funciona offline: baixe [`dashboards/painel_academico_interativo.html`](dashboards/painel_academico_interativo.html) e abra no navegador (o GitHub mostra apenas o código). São cinco páginas: visão geral (C1, C6, C7), desempenho acadêmico (C4, C5, C9), permanência e equidade (C2, C3, C8, C11), turmas e docência (C10, C12) e trajetória e indicadores INEP (C13, C14, C15). A [prévia em PDF](dashboards/previa_paineis.pdf) mostra as cinco páginas sem filtros. A versão publicada em https://painel-dw-academico.vercel.app é a anterior, com C1 a C12, até ser republicada.
- **Looker Studio:** https://datastudio.google.com/u/0/reporting/71ecbe69-ab26-4506-abd8-6cea87179df2/page/hvDDG. Montado direto na plataforma, fora deste repositório.
- **Metabase:** as 15 consultas em `dashboards/metabase/` e um importador que cria os dashboards por API. Em 27/11/2026 o importador foi executado no Metabase v0.64.1 com MySQL 8: criou as 15 perguntas e os cinco dashboards, e todas as perguntas devolveram o mesmo número de linhas do MySQL (a C9 é cortada em 2.000 linhas, o limite padrão do Metabase).

Detalhes de uso, cálculos e montagem estão em [`dashboards/LEIA-ME.md`](dashboards/LEIA-ME.md). O roteiro da apresentação está em [`docs/apresentacao.md`](docs/apresentacao.md).

## Como rodar

Precisa de MySQL 8 e Python 3, sem bibliotecas extras. A validação do painel e o relatório precisam de Node.js; o relatório também precisa de um Chromium (o do cache do Playwright serve, ou indique o caminho em `CHROME`).

```bash
./scripts/carregar.sh -uroot -p                     # gera os dados, cria o banco, deriva agregada e snapshot e roda os 19 testes
mysql -uroot -p --table < sql/05_consultas.sql      # roda as 15 consultas
python3 scripts/exportar_csv.py -uroot -p           # atualiza dados/csv
python3 dashboards/build_demo.py                    # remonta o painel e os SQLs do Metabase
python3 dashboards/validar.py                       # compara o painel com as 15 consultas
node scripts/gerar_relatorio.mjs                    # figuras, relatório final, prévia do painel e diagrama do esquema em PDF
```

Sem senha no MySQL, tire o `-p`. No WSL, instale o banco com `sudo apt install mysql-server` e inicie com `sudo service mysql start`. Nesse caso, use `sudo` antes de `./scripts/carregar.sh` e dos comandos `mysql`.

Se a porta 3306 já estiver em uso, por exemplo por um contêiner Docker, a instalação do MySQL falha. Para usar outra porta, crie o arquivo de configuração abaixo e repita a configuração do pacote:

```bash
printf '[mysqld]\nport = 3310\n' | sudo tee /etc/mysql/mysql.conf.d/zz-porta-dw.cnf
sudo dpkg --configure -a
```

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `docs/relatorio_final.pdf` | Relatório final, nas seis seções do roteiro |
| `docs/relatorio_final/` | Fonte HTML do relatório e as figuras capturadas do painel |
| `docs/entrega_05_11.pdf` | Entrega da aula de 03/11, atualizada em 05/11; os números são da população anterior à correção do gerador |
| `docs/ciclo_23_11.pdf` | Relatório interno do ciclo de 23/11: correção do gerador e curadoria |
| `docs/apresentacao.md` | Roteiro para quem vai apresentar |
| `docs/mudancas_esquemas.md` | O que mudou em relação aos diagramas do DrawSQL |
| `docs/dbml/v2_esquema.dbml` | O esquema atual em DBML, com as três fatos; `v2_esquema.pdf` é o diagrama, gerado do DBML por `node scripts/gerar_relatorio.mjs diagrama` |
| `docs/dbml/v1_*` | Versão anterior, com os dois esquemas separados |
| `sql/01_ddl.sql` | Tabelas, com os ajustes marcados como `[AJUSTE]` |
| `sql/02_dados_sinteticos.sql` | Dados gerados; não editar à mão |
| `sql/03_carga_fato_agregada.sql` | Deriva a fato agregada da fato por aluno |
| `sql/04_views.sql` | Ponte entre professor e turma |
| `sql/05_consultas.sql` | Consultas C1 a C15 |
| `sql/06_validacao.sql` | 19 testes, todos devem dar zero erros |
| `sql/07_snapshot_vinculo.sql` | Deriva o snapshot `fato_vinculo_semestre` de `dim_aluno` |
| `gerador/gerar_dados.py` | Gerador dos dados, com semente fixa |
| `scripts/` | Carga do banco, exportação dos CSVs e geração do relatório (`gerar_relatorio.mjs`) |
| `specs/` | Planejamento do ciclo final: lacunas, requisitos, decisões e tarefas |
| `dados/csv/` | Tabelas em CSV, usadas pelo painel |
| `dashboards/` | Painel interativo, prévia PDF, validação e preparação para Metabase |
