#!/usr/bin/env python3
"""Exporta as tabelas para dados/csv. Uso: python3 scripts/exportar_csv.py -uroot -p"""
import csv
import subprocess
import sys
from pathlib import Path

TABELAS = ["dim_data", "dim_curso", "dim_disciplina", "curso_disciplina", "dim_professor", "dim_turma_aluno", "dim_aluno",
           "dim_turma_disciplina", "fato_professor_aluno", "fato_professor_disciplina", "vw_turma_professor"]
destino = Path(__file__).resolve().parent.parent / "dados" / "csv"
destino.mkdir(parents=True, exist_ok=True)

for tabela in TABELAS:
    saida = subprocess.run(["mysql", *sys.argv[1:], "--batch", "--default-character-set=utf8mb4", "dw_academico",
                            "-e", f"SELECT * FROM {tabela}"], capture_output=True, text=True, check=True).stdout
    with (destino / f"{tabela}.csv").open("w", newline="", encoding="utf-8") as f:
        escritor = csv.writer(f)
        for linha in saida.splitlines():
            escritor.writerow("" if c == "NULL" else c for c in linha.split("\t"))
