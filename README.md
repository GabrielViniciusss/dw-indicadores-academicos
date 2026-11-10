# DW de indicadores acadêmicos

Trabalho da disciplina de Data Warehouse (UFPE): um esquema MySQL com duas estrelas que compartilham dimensões, 12 consultas analíticas e painéis de indicadores. Todos os dados são sintéticos e não descrevem a UFPE.

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

## Entregas

**03/11, construção dos esquemas.** O [PDF da entrega](docs/entrega_05_11.pdf), atualizado em 05/11, traz as 12 consultas em ordem de prioridade, com o gráfico escolhido para cada uma e o porquê, os ajustes no esquema e os dados sintéticos. As consultas estão em [`sql/05_consultas.sql`](sql/05_consultas.sql), com a mesma numeração.

**05/11, visualização dos dados.** Três protótipos de painel, todos sobre os mesmos dados:

- **Painel interativo:** publicado em https://painel-dw-academico.vercel.app. Também funciona offline: baixe [`dashboards/painel_academico_interativo.html`](dashboards/painel_academico_interativo.html) e abra no navegador (o GitHub mostra apenas o código). São quatro páginas: visão geral (C1, C6, C7), desempenho acadêmico (C4, C5, C9), permanência e equidade (C2, C3, C8, C11) e turmas e docência (C10, C12). A [prévia em PDF](dashboards/previa_paineis.pdf) mostra as quatro páginas sem filtros.
- **Looker Studio:** https://datastudio.google.com/u/0/reporting/71ecbe69-ab26-4506-abd8-6cea87179df2/page/hvDDG. Montado direto na plataforma, fora deste repositório.
- **Metabase:** as 12 consultas em `dashboards/metabase/` e um importador que cria os dashboards por API. O importador foi testado na versão anterior, com 13 consultas; a versão atual ainda não foi reexecutada no Metabase.

Detalhes de uso, cálculos e montagem estão em [`dashboards/LEIA-ME.md`](dashboards/LEIA-ME.md). O roteiro da apresentação está em [`docs/apresentacao.md`](docs/apresentacao.md).

## Como rodar

Precisa de MySQL 8 e Python 3, sem bibliotecas extras. A validação do painel também precisa de Node.js.

```bash
./scripts/carregar.sh -uroot -p                     # gera os dados, cria o banco e roda os 16 testes
mysql -uroot -p --table < sql/05_consultas.sql      # roda as 12 consultas
python3 scripts/exportar_csv.py -uroot -p           # atualiza dados/csv
python3 dashboards/build_demo.py                    # remonta o painel e os SQLs do Metabase
python3 dashboards/validar.py                       # compara o painel com as 12 consultas
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
| `docs/entrega_05_11.pdf` | Entrega da aula de 03/11, atualizada em 05/11 |
| `docs/apresentacao.md` | Roteiro para quem vai apresentar |
| `docs/mudancas_esquemas.md` | O que mudou em relação aos diagramas do DrawSQL |
| `docs/dbml/v2_esquema.dbml` | O esquema atual em DBML, com as duas estrelas; `v2_esquema.pdf` é o diagrama |
| `docs/dbml/v1_*` | Versão anterior, com os dois esquemas separados |
| `sql/01_ddl.sql` | Tabelas, com os ajustes marcados como `[AJUSTE]` |
| `sql/02_dados_sinteticos.sql` | Dados gerados; não editar à mão |
| `sql/03_carga_fato_agregada.sql` | Deriva a fato agregada da fato por aluno |
| `sql/04_views.sql` | Ponte entre professor e turma |
| `sql/05_consultas.sql` | Consultas da entrega, C1 a C12 |
| `sql/06_validacao.sql` | 16 testes, todos devem dar zero erros |
| `gerador/gerar_dados.py` | Gerador dos dados, com semente fixa |
| `scripts/` | Carga do banco e exportação dos CSVs |
| `dados/csv/` | Tabelas em CSV, usadas pelo painel |
| `dashboards/` | Painel interativo, prévia PDF, validação e preparação para Metabase |
