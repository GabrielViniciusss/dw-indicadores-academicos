# Fonte dos dados sintéticos

Os painéis reutilizam os arquivos em [`../../dados/csv/`](../../dados/csv/), sem criar uma população paralela ou duplicar os CSVs.

- `dim_aluno.csv`: 1.433 alunos fictícios e sua situação final de vínculo.
- `fato_professor_aluno.csv`: 30.992 matrículas, notas, faltas, tentativas e benefício por semestre.
- As demais dimensões, a fato agregada e a ponte de docentes estão na mesma pasta.

O gerador original é [`../../gerador/gerar_dados.py`](../../gerador/gerar_dados.py).
`build_demo.py` empacota esses CSVs no HTML: não sorteia dados e não atualiza a base.
Para atualizar: gere e carregue o DW, exporte os CSVs com o script do repositório e reconstrua o HTML.
