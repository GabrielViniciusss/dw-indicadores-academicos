# DW de indicadores acadêmicos

Trabalho da disciplina de Data Warehouse (UFPE), sobre o esquema do projeto, com duas estrelas. Todos os dados são fictícios.

## Segunda parte — visualização dos dados (05/11)

O [painel interativo](dashboards/painel_academico_interativo.html) funciona offline no navegador e usa os dados sintéticos de `dados/csv`. Baixe o arquivo para abri-lo; o GitHub exibe apenas seu código.

São quatro páginas: visão geral (C1–C3), desempenho acadêmico (C5, C6, C8, C12), permanência e equidade (C9–C11, C13) e turmas e docência (C4, C7). Há modo de foco por consulta, filtros globais e específicos, alternância gráfico/tabela, comparação semestral, investigação por disciplina e links que preservam o recorte, além de CSV e PDF.

Consulte a [prévia PDF](dashboards/previa_paineis.pdf) e as [instruções de reprodução e montagem no Metabase](dashboards/LEIA-ME.md). O HTML é um protótipo independente. O ambiente Docker e o importador do Metabase foram testados: criam quatro dashboards e 13 perguntas nativas. As instruções explicam como reproduzir essa configuração inicial e ajustar os filtros e gráficos no editor.

## Como rodar

Precisa de MySQL 8 e Python 3, sem bibliotecas extras.

```bash
./scripts/carregar.sh -uroot -p                     # cria o banco, gera os dados e valida
mysql -uroot -p --table < sql/05_consultas.sql      # roda as 13 consultas
python3 scripts/exportar_csv.py -uroot -p           # atualiza dados/csv
```

Sem senha no MySQL, tire o `-p`. No WSL, instale o banco com `sudo apt install mysql-server` e inicie com `sudo service mysql start`. Nesse caso, use `sudo` antes de `./scripts/carregar.sh` e dos outros comandos.

Se a porta 3306 já estiver em uso, por exemplo por um contêiner Docker, a instalação do MySQL falha. Para usar outra porta, crie o arquivo de configuração abaixo e repita a configuração do pacote:

```bash
printf '[mysqld]\nport = 3310\n' | sudo tee /etc/mysql/mysql.conf.d/zz-porta-dw.cnf
sudo dpkg --configure -a
```

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `docs/entrega_05_11.pdf` | Entrega da aula de 03/11, atualizada para 05/11 |
| `docs/graficos/` | Exemplos ilustrativos de cada consulta |
| `docs/apresentacao.md` | Roteiro para quem vai apresentar |
| `docs/mudancas_esquemas.md` | O que mudou em relação aos diagramas do DrawSQL |
| `docs/dbml/v2_esquema.dbml` | O esquema completo em DBML, com as duas estrelas |
| `sql/01_ddl.sql` | Tabelas, com os ajustes marcados como `[AJUSTE]` |
| `sql/02_dados_sinteticos.sql` | Dados gerados |
| `sql/03_carga_fato_agregada.sql` | Deriva a fato agregada da fato por aluno |
| `sql/04_views.sql` | Ponte entre professor e turma |
| `sql/05_consultas.sql` | Consultas da entrega, C1 a C13 |
| `sql/06_validacao.sql` | Testes, todos devem dar zero erros |
| `gerador/gerar_dados.py` | Gerador dos dados |
| `dados/csv/` | Tabelas em CSV para importar no painel |
| `dashboards/` | Protótipo interativo, prévia PDF, fontes e preparação para Metabase |
