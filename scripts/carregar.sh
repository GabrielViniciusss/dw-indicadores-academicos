#!/usr/bin/env bash
# Uso: ./scripts/carregar.sh [opcoes do cliente mysql], ex.: -uroot -p
set -euo pipefail
cd "$(dirname "$0")/.."

python3 gerador/gerar_dados.py
for arquivo in 01_ddl 02_dados_sinteticos 03_carga_fato_agregada 04_views; do
  echo "Executando $arquivo"
  mysql --default-character-set=utf8mb4 "$@" < "sql/$arquivo.sql"
done
mysql --default-character-set=utf8mb4 --table "$@" < sql/06_validacao.sql
