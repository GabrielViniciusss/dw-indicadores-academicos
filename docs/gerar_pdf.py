#!/usr/bin/env python3
"""Gera docs/entrega_03_11.pdf."""
from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import KeepTogether, Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle

SAIDA = Path(__file__).resolve().parent / "entrega_03_11.pdf"

corpo = ParagraphStyle("corpo", fontName="Helvetica", fontSize=9.5, leading=13, spaceAfter=5, alignment=TA_LEFT)
titulo = ParagraphStyle("titulo", parent=corpo, fontName="Helvetica-Bold", fontSize=16, leading=20, spaceAfter=2)
sub = ParagraphStyle("sub", parent=corpo, textColor=colors.HexColor("#555555"), spaceAfter=12)
secao = ParagraphStyle("secao", parent=corpo, fontName="Helvetica-Bold", fontSize=12, leading=16, spaceBefore=10, spaceAfter=5)
pergunta = ParagraphStyle("pergunta", parent=corpo, fontName="Helvetica-Bold", spaceAfter=2)
celula = ParagraphStyle("celula", parent=corpo, fontSize=9, leading=12, spaceAfter=0)
cabecalho = ParagraphStyle("cabecalho", parent=celula, fontName="Helvetica-Bold")
codigo = ParagraphStyle("codigo", parent=corpo, fontName="Courier", fontSize=8.5, leading=12, spaceAfter=0)

CONSULTAS = [
    ("C1. Como a taxa de aprovação de cada disciplina evoluiu ao longo dos 16 semestres?", "Agregada", "Linhas, uma por disciplina, com filtro de disciplina",
     "O tempo é contínuo e ordenado, e a linha mostra tendência e mudança de patamar. Em colunas, 16 semestres vezes 42 disciplinas dariam 672 barras. Mesmo em linhas, 42 juntas ficariam ilegíveis, então o filtro deixa comparar poucas disciplinas por vez."),
    ("C2. Quais são as 10 disciplinas com maior taxa de reprovação, e qual é a taxa de cada uma?", "Agregada", "Barras horizontais ordenadas (10 maiores)",
     "Compara valores entre categorias sem ordem própria. Os nomes longos cabem na horizontal e a ordenação já entrega o ranking. Pizza não serve, porque as taxas não somam 100%."),
    ("C3. Nas disciplinas críticas, como as matrículas se dividem entre aprovação por nota, aprovação na final, reprovação por nota, reprovação por falta e trancamento?", "Agregada", "Barras empilhadas em 100%",
     "Cada barra é um todo dividido em partes, e várias pizzas seriam difíceis de comparar. Separar reprovação por nota e por falta importa, porque a primeira aponta dificuldade de conteúdo e a segunda, abandono da disciplina."),
    ("C4. Como as notas finais de cada curso se distribuem entre as faixas da regra de avaliação?", "Agregada", "Colunas por faixa, em % do curso",
     "As faixas têm ordem, então colunas lado a lado funcionam, e o percentual evita que o curso maior pareça pior. Não é um histograma: as faixas seguem a regra da disciplina, e não uma largura fixa. A de 0 a 2,9 é de quem não chega à final, e a de 3 a 6,9 concentra quem vai para ela. Essa faixa tem 4 pontos e a de 7 a 7,9 tem 1, então parte da altura vem da largura. Vale deixar isso escrito no painel."),
    ("C5. Como a taxa de reprovação de cada disciplina crítica variou de um semestre para outro, e como essa variação acompanha o professor que deu a disciplina?", "Agregada + ponte", "Mapa de calor (disciplina x semestre), com o professor na dica",
     "São duas dimensões e 128 valores. A cor em um só tom destaca os pontos fora do padrão, enquanto 8 linhas sobrepostas ficariam ilegíveis. A dica de cada célula mostra quem deu a disciplina naquele semestre, para ver se as piores células coincidem com a troca de professor. Uma célula pode ter mais de uma turma e mais de um professor, e a coincidência não prova que o professor causou a variação."),
    ("C6. Como a taxa de reprovação de cada oferta se relaciona com a média de faltas dessa oferta?", "Agregada", "Dispersão, um ponto por oferta",
     "É a relação entre duas medidas numéricas, e cada ponto mantém a oferta visível. Usamos a média de faltas, e não a soma, porque a soma cresce com o tamanho da turma. O gráfico mostra associação, não causa."),
    ("C7. Dentro de uma mesma disciplina, como a taxa de aprovação, a nota média e o número de alunos variam entre os professores?", "Agregada + ponte", "Tabela com barra de dados, filtrada por disciplina",
     "Aqui o valor exato e o número de alunos importam. O filtro compara professores só dentro da mesma disciplina, porque um ranking geral puniria quem ensina as matérias difíceis."),
    ("C8. Como as reprovações se distribuem conforme o período em que os alunos estão no curso?", "Por aluno", "Colunas por período",
     "Os períodos são discretos e ordenados, e a coluna deixa claro onde está o pico. A base é maior nos primeiros períodos, então convém mostrar o total de matrículas na dica do gráfico."),
    ("C9. Em cada turma de ingresso, qual é a proporção de alunos que concluíram, que seguem ativos e que evadiram?", "Por aluno", "Barras empilhadas em 100% (concluiu, ativo, evadiu)",
     "Toda turma de ingresso soma 100%. A parte de ativos evita uma leitura errada: as turmas que entraram há pouco concluíram pouco porque ainda estão no curso, e a evasão delas ainda pode subir."),
    ("C10. Como as taxas de reprovação e de evasão variam entre os tipos de cota em cada faixa econômica?", "Por aluno", "Dois gráficos de barras horizontais, com filtro de faixa",
     "Reprovação e evasão ficam em gráficos separados, sem eixo duplo, que sugeriria relações que dependem só da escala. O número de alunos aparece junto, porque alguns grupos são pequenos e oscilam muito."),
    ("C11. Quanto o tempo de conclusão de cada curso se afasta do prazo previsto?", "Por aluno", "Barras com marcador do prazo previsto",
     "O marcador compara cada curso com a própria meta, já que os prazos são diferentes. Sem ferramenta para isso, colunas agrupadas (previsto e real) cumprem o papel. A base são só os alunos que concluíram."),
    ("C12. Como a taxa de aprovação muda da 1ª para a 2ª tentativa, e para a 3ª ou mais, na mesma disciplina?", "Por aluno", "Colunas (1ª, 2ª, 3ª ou mais)",
     "São só três categorias ordenadas e uma medida, então o gráfico mais simples basta."),
    ("C13. Como a taxa de aprovação de beneficiários e de não beneficiários de assistência estudantil evoluiu ao longo dos semestres?", "Agregada", "Duas linhas",
     "Pelo mesmo motivo de C1, e a distância entre as linhas é a informação. Atenção: no gerador só há benefício a partir do 2º período, então o grupo sem benefício inclui calouros e a diferença não prova efeito da assistência estudantil."),
]

AJUSTES = [
    ("<b>situacao_vinculo</b> e <b>id_data_saida</b> em dim_aluno", "O esquema registrava matrículas, mas não dizia quem concluiu ou evadiu, nem quando.", "C9, C10, C11"),
    ("<b>semestres_previstos</b> em dim_curso", "Sem o prazo de cada curso, não há com o que comparar o tempo de conclusão.", "C11"),
    ("<b>periodo_aluno</b> em fato_professor_aluno", "Guarda quantos semestres se passaram desde o ingresso. Calculado na carga, dispensa uma tabela de matriz curricular por curso.", "C8"),
    ("<b>qtd_trancamentos</b> em fato_professor_disciplina", "As quatro contagens de situação não fechavam com qtd_matriculados quando havia trancamento, e as taxas ficavam com a base errada.", "C1, C2, C3, C5, C6, C7, C13"),
    ("View <b>vw_turma_professor</b>", "Transforma os três papéis de professor em linhas, sem alterar as tabelas. Evita três joins em cada consulta. O peso reparte turmas com mais de um professor em somas gerais.", "C5, C7"),
]

VOLUMES = [
    ("dim_data", "16", "2018.1 a 2025.2"), ("dim_curso", "3", "CC, EC e SI"),
    ("dim_disciplina", "42", "Currículo fictício"), ("dim_professor", "40", "Pseudônimos"),
    ("dim_turma_aluno", "72", "Coortes de ingresso"), ("dim_aluno", "1.433", "433 concluíram, 619 evadiram, 381 ativos"),
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
    h.append(Paragraph("Data Warehouse, UFPE. Entrega da aula de 03/11/2026, sobre os esquemas PDFs e PDFs 2.<br/>Equipe: jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb.", sub))
    h.append(Paragraph(
        "Levantamos 13 consultas sobre as duas estrelas, escolhemos o gráfico de cada uma, ajustamos o que faltava nos "
        "esquemas e povoamos tudo com dados sintéticos. Os scripts rodaram no MySQL 8, o banco definido nos diagramas, "
        "e as 13 consultas executaram sem erro. Partimos das questões do TCC de Espíndola (UFPE, 2025) e as adaptamos "
        "aos campos que temos, como turma, professor, assistência estudantil e faixa econômica.", corpo))

    h.append(Paragraph("1. Consultas e escolha dos gráficos", secao))
    h.append(Paragraph(
        "\"Agregada\" é a estrela de fato_professor_disciplina, e \"Por aluno\" é a de fato_professor_aluno. "
        "O SQL de cada consulta está em sql/05_consultas.sql.", corpo))
    for perg, estrela, grafico, porque in CONSULTAS:
        h.append(KeepTogether([
            Paragraph(perg, pergunta),
            Paragraph(f"Estrela: {estrela}. Gráfico: {grafico}.", corpo.clone("meta", spaceAfter=2)),
            Paragraph(porque, corpo.clone("porque", spaceAfter=9)),
        ]))
    h.append(Paragraph(
        "Três regras valem para todo o painel. As taxas devem ser calculadas a partir das contagens, nunca como média de "
        "taxas de turmas, porque turmas pequenas pesariam igual às grandes. A média de notas agregada é "
        "soma_notas_finais / qtd_notas_validas, e a mediana não se agrega, como o próprio diagrama já avisa. "
        "Por fim, os indicadores gerais (taxa de aprovação, nota média, evasão) ficam em cartões no topo, porque são um "
        "número só e pedem leitura imediata.", corpo))

    h.append(KeepTogether([
        Paragraph("2. Ajustes nos esquemas", secao),
        Paragraph("Mantivemos os grãos, as chaves e as dimensões compartilhadas. Foram cinco acréscimos:", corpo),
        tabela(AJUSTES, [5 * cm, 8.1 * cm, 3 * cm], ["Ajuste", "Por que", "Consultas"]),
    ]))
    h.append(Spacer(1, 8))
    h.append(Paragraph(
        "<b>Pendências do grupo.</b> Ainda falta confirmar se a situação de vínculo e o semestre de saída estão nos PDFs de "
        "origem. Se não estiverem, C9, C10 e C11 perdem a base com os dados reais. Sexo e faixa etária, usados no TCC, não "
        "foram incluídos porque não sabemos se a fonte traz esses dados. Os ajustes nos diagramas do DrawSQL estão listados "
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
        "<b>O que estes dados não são.</b> Nenhum número aqui descreve a UFPE. Colocamos de propósito alguns efeitos para o "
        "painel ter o que mostrar: disciplinas com dificuldades diferentes, primeiros períodos mais duros, notas maiores "
        "em 2020 e 2021 e uma pequena vantagem nas faixas de renda mais altas. O tipo de cota não tem efeito direto no "
        "gerador. Qualquer padrão nos gráficos reflete essas escolhas, não uma descoberta. Alunos e professores são "
        "pseudônimos, e os anos de 2014 a 2017 foram simulados só para 2018 não começar apenas com calouros.", corpo))
    h.append(Paragraph(
        "<b>Verificação.</b> Os 15 testes de sql/06_validacao.sql retornaram zero erros. Eles conferem, entre outras coisas, "
        "se as duas estrelas têm as mesmas matrículas, notas e faltas, se as situações e as faixas fecham com os totais, "
        "se a nota combina com a situação e se não há matrícula antes do ingresso ou depois da saída.", corpo))

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
