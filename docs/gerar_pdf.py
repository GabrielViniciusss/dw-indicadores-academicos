#!/usr/bin/env python3
"""Gera docs/entrega_03_11.pdf a partir do documento do grupo e de docs/graficos."""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import Image, KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

DOCS = Path(__file__).resolve().parent
SAIDA = DOCS / "entrega_03_11.pdf"

corpo = ParagraphStyle("corpo", fontName="Helvetica", fontSize=9.5, leading=13, spaceAfter=5, alignment=TA_LEFT)
titulo = ParagraphStyle("titulo", parent=corpo, fontName="Helvetica-Bold", fontSize=16, leading=20, spaceAfter=2)
sub = ParagraphStyle("sub", parent=corpo, textColor=colors.HexColor("#555555"), spaceAfter=12)
secao = ParagraphStyle("secao", parent=corpo, fontName="Helvetica-Bold", fontSize=12, leading=16, spaceBefore=10, spaceAfter=5)
pergunta = ParagraphStyle("pergunta", parent=corpo, fontName="Helvetica-Bold", spaceAfter=4)
celula = ParagraphStyle("celula", parent=corpo, fontSize=9, leading=12, spaceAfter=0)
cabecalho = ParagraphStyle("cabecalho", parent=celula, fontName="Helvetica-Bold")
codigo = ParagraphStyle("codigo", parent=corpo, fontName="Courier", fontSize=8.5, leading=12, spaceAfter=0)

CONSULTAS = [
    ("C1", "Como a taxa de aprovação de cada disciplina crítica (as 10 com maiores taxas de reprovação) mudou de um semestre para outro?",
     "mostra se uma disciplina crítica está melhorando, piorando ou continua igual. Se a aprovação cai vários semestres seguidos, ou muda de repente, a coordenação sabe que precisa investigar e, se for o caso, agir, por exemplo oferecendo monitoria ou revendo a forma de ensinar.",
     "estrela agregada, com os aprovados e os reprovados por nota e por falta de cada turma, em cada semestre.",
     "linhas, com os semestres no eixo horizontal e a taxa de aprovação no eixo vertical. Cada linha é uma disciplina, com filtros de disciplina, curso e turma. A dica de cada ponto mostra as reprovações por nota e por falta.",
     "os semestres seguem uma ordem, e a linha mostra com facilidade se a taxa está subindo, caindo ou mudando de repente. Em colunas, seriam 160 barras (16 semestres vezes 10 disciplinas)."),
    ("C2", "Em cada semestre, quais são as 10 disciplinas com maior taxa de reprovação, e quanto dessa taxa vem de nota e de falta?",
     "indica onde concentrar monitoria e apoio em cada semestre. Separar nota e falta ajuda a escolher a ação, pois reforço de conteúdo pode não resolver um problema de faltas.",
     "estrela agregada, com as reprovações por nota e por falta, as matrículas e os trancamentos de cada turma.",
     "barras horizontais ordenadas e empilhadas (nota e falta), com filtros de semestre e curso.",
     "as disciplinas não têm uma ordem própria, e os nomes longos cabem melhor na horizontal. A ordenação já mostra o ranking. Pizza não serve, porque as taxas não somam 100%."),
    ("C3", "Em cada semestre, como as matrículas das disciplinas críticas se dividem entre aprovação por nota, aprovação na final, reprovação por nota, reprovação por falta e trancamento?",
     "mostra o tipo de problema de cada disciplina. Muita reprovação por nota aponta dificuldade com o conteúdo, enquanto muita reprovação por falta aponta abandono da disciplina.",
     "estrela agregada, com as contagens de cada situação por turma.",
     "barras empilhadas em 100%, uma por disciplina, com filtros de semestre, curso e turma.",
     "cada barra é um total dividido em partes, o que facilita comparar disciplinas. Várias pizzas seriam difíceis de comparar."),
    ("C4", "Em um curso, quais professores têm taxa de reprovação mais distante da média das disciplinas que ministram?",
     "mostra onde a reprovação de um professor foge do padrão daquela disciplina. Isso ajuda a coordenação a investigar a causa, alinhar critérios de avaliação e identificar boas práticas. O resultado não prova que o professor causou a diferença e não deve ser usado sozinho para avaliá-lo.",
     "estrela agregada, com as reprovações por nota e por falta de cada turma, e a lista de professores por turma.",
     "barras divergentes em torno de zero, uma por professor, com filtros de curso e semestre. A dica mostra as disciplinas e o número de alunos.",
     "o zero representa a média das disciplinas. Assim, fica fácil ver quem está acima ou abaixo do esperado e por quanto. Mostrar o número de alunos evita tirar conclusões de turmas pequenas."),
    ("C5", "Como a taxa de reprovação das disciplinas críticas evoluiu por semestre e período curricular?",
     "mostra quando e onde ocorreram os piores resultados, sem misturar semestres diferentes. Isso permite investigar o que aconteceu naquele semestre.",
     "estrela agregada e o período curricular da disciplina em cada curso (tabela curso_disciplina).",
     "mapa de calor, com as disciplinas nas linhas, ordenadas pelo período curricular, os semestres nas colunas e a taxa de reprovação na cor, com filtro de curso.",
     "são até 160 valores (10 disciplinas vezes 16 semestres). A cor destaca os piores casos de imediato, enquanto 10 linhas sobrepostas ficariam difíceis de ler. O filtro é necessário porque o período de uma disciplina pode mudar de um curso para outro."),
    ("C6", "Em cada oferta de disciplina, como a taxa de reprovação se relaciona com a média de faltas?",
     "ajuda a identificar turmas em que as faltas acompanham as reprovações e onde pode valer agir sobre frequência. O gráfico mostra uma relação, não a causa.",
     "estrela agregada, com as faltas e as reprovações de cada turma.",
     "dispersão, com um ponto por turma, média de faltas em um eixo e taxa de reprovação no outro, e filtros de semestre e curso.",
     "é o gráfico indicado para ver a relação entre duas medidas numéricas, e cada ponto mantém a turma visível. Usamos a média de faltas porque a soma cresce com o tamanho da turma."),
    ("C7", "Em uma mesma disciplina, qual é a relação da taxa de aprovação, da nota média e do número de alunos com os diferentes professores e turmas?",
     "mostra em quais disciplinas vale reunir os professores para alinhar plano de ensino e critérios de avaliação. A consulta não serve para ranquear professores.",
     "estrela agregada e a lista de professores por turma.",
     "tabela com barra de dados, filtrada por disciplina e semestre.",
     "aqui o valor exato e o número de alunos importam. O filtro compara professores só dentro da mesma disciplina, porque um ranking geral prejudicaria quem ensina as matérias mais difíceis."),
    ("C8", "Como as reprovações por nota e por falta se distribuem conforme o período em que os alunos estão no curso, em cada semestre?",
     "mostra em que momento do curso os alunos têm mais dificuldade, para concentrar o acompanhamento nesses períodos.",
     "estrela por aluno, com o resultado de cada matrícula e o período do aluno naquele semestre.",
     "colunas empilhadas (nota e falta) por período do aluno, com filtros de semestre, curso e turma de ingresso.",
     "os períodos são separados e seguem uma ordem, então a coluna deixa claro onde está o pico. Há mais matrículas nos primeiros períodos, por isso a dica também mostra o total."),
    ("C9", "Em cada turma de ingresso, qual é a proporção de alunos que concluíram, que seguem ativos e que evadiram?",
     "permite comparar as turmas de ingresso e identificar aquelas com evasão mais alta, para investigar a causa e planejar ações de permanência.",
     "estrela por aluno, com a situação do aluno no curso e a turma de ingresso.",
     "barras empilhadas em 100%, uma por turma de ingresso, com filtro de curso.",
     "toda turma soma 100%. A parte de ativos evita uma leitura errada: as turmas mais novas concluíram pouco porque ainda estão no curso, e a evasão delas ainda pode subir."),
    ("C10", "Em cada turma de ingresso, como as taxas de reprovação e de evasão variam entre os tipos de cota e as faixas econômicas?",
     "ajuda a decidir quais grupos priorizar em acolhimento, nivelamento e assistência estudantil. O resultado mostra onde há mais dificuldade, não a causa.",
     "estrela por aluno, com o resultado das matrículas, a situação do aluno, o tipo de cota, a faixa econômica e a turma de ingresso.",
     "dois gráficos de barras horizontais, um de reprovação e outro de evasão, com filtros de faixa econômica, curso e turma de ingresso.",
     "gráficos separados evitam um eixo duplo, que sugeriria relações que dependem só da escala. O número de alunos aparece junto, porque grupos pequenos oscilam muito."),
    ("C11", "Em cada turma de ingresso, quanto o tempo de conclusão se afasta do prazo previsto do curso?",
     "mostra quais turmas e cursos levam mais tempo para concluir, o que ajuda a planejar a oferta de disciplinas e o acompanhamento de alunos atrasados.",
     "estrela por aluno, com a turma de ingresso, o semestre de saída dos alunos que concluíram e o prazo previsto do curso.",
     "barras com um marcador do prazo previsto, uma por turma de ingresso, com filtro de curso. Sem ferramenta para isso, colunas agrupadas (previsto e real) cumprem o papel.",
     "o marcador compara cada barra com a meta do próprio curso, já que os prazos são diferentes. Só entram alunos que concluíram, então as turmas mais novas ainda podem mudar."),
    ("C12", "Em cada disciplina, como a taxa de aprovação muda da 1ª para a 2ª tentativa, e para a 3ª ou mais?",
     "mostra se repetir a disciplina tem ajudado os alunos e em quais casos eles precisam de apoio específico ao voltar a cursá-la.",
     "estrela por aluno, com o número da tentativa e o resultado de cada matrícula.",
     "colunas (1ª, 2ª, 3ª ou mais), com filtros de disciplina, curso e semestre.",
     "são só três categorias em ordem e uma medida, então o gráfico mais simples basta."),
    ("C13", "Como as taxas de reprovação e de evasão de beneficiários da assistência estudantil se comparam com as de não beneficiários, em cada curso e semestre?",
     "ajuda a gestão a acompanhar se os alunos atendidos estão reprovando e evadindo menos ou mais do que os demais do mesmo curso, e a planejar a assistência. A diferença entre os grupos não prova que o benefício causou o resultado, porque beneficiários e não beneficiários podem ter perfis diferentes.",
     "estrela por aluno, com o curso, o semestre, o resultado de cada matrícula, a indicação de benefício no semestre, a situação do aluno e o semestre de saída.",
     "dois gráficos de linhas, um de reprovação e outro de evasão. Os semestres ficam no eixo horizontal, com uma linha para beneficiários e outra para não beneficiários, e filtro de curso. A dica mostra o número de alunos.",
     "os semestres seguem uma ordem, e a distância entre as linhas é a informação principal. Reprovação e evasão ficam em gráficos separados para evitar dois eixos. O filtro mantém a comparação dentro do mesmo curso, e o número de alunos evita tirar conclusões de grupos pequenos."),
]

# consultas marcadas pelo grupo para discutir com o professor
A_DISCUTIR = {"C2", "C12"}

AJUSTES = [
    ("<b>situacao_vinculo</b> e <b>id_data_saida</b> em dim_aluno", "O esquema registrava matrículas, mas não dizia quem concluiu ou evadiu, nem quando.", "C9, C10, C11, C13"),
    ("<b>semestres_previstos</b> em dim_curso", "Sem o prazo de cada curso, não há com o que comparar o tempo de conclusão.", "C11"),
    ("<b>periodo_aluno</b> em fato_professor_aluno", "Guarda quantos semestres se passaram desde o ingresso, calculado na carga.", "C8"),
    ("<b>qtd_trancamentos</b> em fato_professor_disciplina", "As quatro contagens de situação não fechavam com qtd_matriculados quando havia trancamento, e as taxas ficavam com a base errada.", "C1, C2, C3, C4, C5, C6, C7"),
    ("Tabela <b>curso_disciplina</b>", "Guarda o período curricular de cada disciplina em cada curso, porque ele pode variar entre os cursos.", "C5"),
    ("View <b>vw_turma_professor</b>", "Transforma os três papéis de professor em linhas, sem alterar as tabelas. Evita três joins em cada consulta. O peso reparte turmas com mais de um professor em somas gerais.", "C4, C7"),
]

VOLUMES = [
    ("dim_data", "16", "2018.1 a 2025.2"), ("dim_curso", "3", "CC, EC e SI"),
    ("dim_disciplina", "42", "Currículo fictício"), ("curso_disciplina", "104", "Período curricular por curso"),
    ("dim_professor", "40", "Pseudônimos"), ("dim_turma_aluno", "72", "Coortes de ingresso"),
    ("dim_aluno", "1.433", "433 concluíram, 619 evadiram, 381 ativos"),
    ("dim_turma_disciplina", "875", "197 turmas com mais de um professor"),
    ("fato_professor_aluno", "30.992", "Uma linha por matrícula"),
    ("fato_professor_disciplina", "2.211", "Derivada da fato por aluno"),
]


def tabela(linhas, larguras, titulos):
    dados = [[Paragraph(t, cabecalho) for t in titulos]]
    dados += [[Paragraph(str(c), celula) for c in l] for l in linhas]
    t = Table(dados, colWidths=larguras, repeatRows=1, hAlign="LEFT")
    t.setStyle(TableStyle([
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LINEBELOW", (0, 0), (-1, 0), 0.8, colors.black),
        ("LINEBELOW", (0, 1), (-1, -1), 0.3, colors.HexColor("#BBBBBB")),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
        ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 8),
    ]))
    return t


def rodape(canvas, doc):
    canvas.setFont("Helvetica", 8)
    canvas.setFillColor(colors.HexColor("#555555"))
    canvas.drawRightString(A4[0] - 2.2 * cm, 1.2 * cm, str(doc.page))


def main():
    h = []
    h.append(Paragraph("Construção dos esquemas", titulo))
    h.append(Paragraph("Data Warehouse, UFPE. Entrega da aula de 03/11/2026, atualizada para o dia 05/11/2026, sobre o esquema do projeto, com duas estrelas.<br/>Equipe: jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb.", sub))
    h.append(Paragraph("<b>Estrela por aluno:</b> tabela com uma linha por matrícula de aluno (fato_professor_aluno).", corpo))
    h.append(Paragraph("<b>Estrela agregada:</b> tabela com os totais de cada turma por curso e semestre (fato_professor_disciplina).", corpo))

    h.append(Paragraph("1. Consultas e escolha dos gráficos", secao))
    largura = 12.5 * cm
    for num, perg, serve, dados, grafico, porque in CONSULTAS:
        h.append(KeepTogether([
            Paragraph(f"{'#' if num in A_DISCUTIR else ''}{num}. {perg}", pergunta),
            Paragraph(f"<b>Para que serve:</b> {serve}", corpo),
            Paragraph(f"<b>Dados usados:</b> {dados}", corpo),
            Paragraph(f"<b>Gráfico:</b> {grafico}", corpo),
            Paragraph(f"<b>Por que esse gráfico:</b> {porque}", corpo),
            Image(str(DOCS / "graficos" / f"{num}.png"), width=largura, height=largura * 820 / 1400, hAlign="LEFT"),
            Spacer(1, 12),
        ]))

    h.append(KeepTogether([
        Paragraph("2. Ajustes no esquema", secao),
        Paragraph("Mantivemos os grãos, as chaves e as dimensões compartilhadas. Foram seis acréscimos:", corpo),
        tabela(AJUSTES, [5 * cm, 8 * cm, 3 * cm], ["Ajuste", "Por que", "Consultas"]),
    ]))
    h.append(Spacer(1, 8))
    h.append(Paragraph(
        "<b>Pendências do grupo.</b> Ainda falta confirmar se a situação de vínculo e o semestre de saída estão nos PDFs de "
        "origem. Se não estiverem, C9, C10, C11 e C13 perdem a base com os dados reais. Sexo e faixa etária, usados no TCC, "
        "não foram incluídos porque não sabemos se a fonte traz esses dados. Os ajustes para o diagrama do DrawSQL estão listados "
        "em docs/mudancas_esquemas.md, e o arquivo sql/01_ddl.sql já tem a versão final.", corpo))

    h.append(Paragraph("3. Dados sintéticos", secao))
    h.append(Paragraph(
        "O gerador (gerador/gerar_dados.py) simula cada aluno semestre a semestre: escolhe disciplinas pendentes, sorteia o "
        "resultado, repete o que reprovou e decide se ele conclui ou evade. A semente é fixa, então o resultado é "
        "sempre igual. A fato agregada não é sorteada: sai da fato por aluno em SQL, então as duas estrelas sempre fecham.",
        corpo))
    h.append(tabela(VOLUMES, [5.5 * cm, 1.8 * cm, 8.8 * cm], ["Tabela", "Linhas", "Conteúdo"]))
    h.append(Spacer(1, 8))
    h.append(Paragraph(
        "<b>Regras usadas.</b> Nota a partir de 7 aprova por nota. Abaixo de 3, o aluno reprova sem ir para a final. De 3 a "
        "6,99, ele faz a final e precisa de média final de pelo menos 5. Mais de 25% da carga horária em faltas reprova "
        "por falta. Trancamento fica sem nota e sem faltas, e só aprovação soma carga horária. O gerador não simula a prova "
        "final em separado: guarda apenas a nota final, e as aprovadas na final ficam entre 5 e 6,99.", corpo))
    h.append(Paragraph(
        "<b>O que estes dados não são.</b> Nenhum número aqui descreve a UFPE. Os gráficos acima são exemplos ilustrativos, "
        "com valores fictícios, e não saem da base. Na base sintética, colocamos de propósito alguns efeitos para o painel ter "
        "o que mostrar: disciplinas com dificuldades diferentes, primeiros períodos mais duros, notas maiores em 2020 e 2021 e "
        "uma pequena vantagem nas faixas de renda mais altas. O tipo de cota, o professor e o benefício não têm efeito direto "
        "no gerador, e calouros não recebem o benefício. Qualquer padrão nos resultados reflete essas escolhas, não uma "
        "descoberta. Alunos e professores são pseudônimos, e os anos de 2014 a 2017 foram simulados só para 2018 não começar "
        "apenas com calouros.", corpo))
    h.append(Paragraph(
        "<b>Verificação.</b> As 13 consultas rodaram sem erro no MySQL 8, e os 16 testes de sql/06_validacao.sql retornaram "
        "zero erros. Eles conferem, entre outras coisas, se as duas estrelas têm as mesmas matrículas, notas e faltas, se as "
        "situações e as faixas fecham com os totais, se a nota combina com a situação e se não há matrícula antes do ingresso "
        "ou depois da saída.", corpo))

    h.append(Paragraph("4. Como reproduzir", secao))
    h.append(Paragraph("Com um MySQL 8 em execução, na raiz do repositório:", corpo))
    h.append(Paragraph("./scripts/carregar.sh -uroot -p<br/>mysql -uroot -p --table &lt; sql/05_consultas.sql", codigo))
    h.append(Spacer(1, 6))
    h.append(Paragraph("A pasta dados/csv traz as mesmas tabelas em CSV para quem preferir importar no painel.", corpo))

    doc = SimpleDocTemplate(str(SAIDA), pagesize=A4, leftMargin=2.2 * cm, rightMargin=2.2 * cm, topMargin=1.8 * cm,
                            bottomMargin=1.8 * cm, title="Construção dos esquemas", author="Grupo de Data Warehouse")
    doc.build(h, onFirstPage=rodape, onLaterPages=rodape)


if __name__ == "__main__":
    main()
