# DW de indicadores acadêmicos

Trabalho da disciplina de Data Warehouse (UFPE), sobre os esquemas PDFs e PDFs 2. Todos os dados são fictícios.

## Como rodar

Precisa de MySQL 8 e Python 3, sem bibliotecas extras.

```bash
./scripts/carregar.sh -uroot -p                     # cria o banco, gera os dados e valida
mysql -uroot -p --table < sql/05_consultas.sql      # roda as 13 consultas
python3 scripts/exportar_csv.py -uroot -p           # atualiza dados/csv
```

Sem senha no MySQL, tire o `-p`. No WSL, instale o banco com `sudo apt install mysql-server` e inicie com `sudo service mysql start`. Nesse caso, use `sudo` antes de `./scripts/carregar.sh` e dos outros comandos.

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `docs/entrega_03_11.pdf` | Entrega da aula de 03/11 |
| `sql/01_ddl.sql` | Tabelas, com os ajustes marcados como `[AJUSTE]` |
| `sql/02_dados_sinteticos.sql` | Dados gerados |
| `sql/03_carga_fato_agregada.sql` | Deriva a fato agregada da fato por aluno |
| `sql/04_views.sql` | Ponte entre professor e turma |
| `sql/05_consultas.sql` | Consultas analíticas C1 a C13 |
| `sql/06_validacao.sql` | Testes, todos devem dar zero erros |
| `gerador/gerar_dados.py` | Gerador dos dados |
| `dados/csv/` | Tabelas em CSV para importar no painel |
