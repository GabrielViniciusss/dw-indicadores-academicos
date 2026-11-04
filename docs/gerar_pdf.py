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
    ("C1. Considerando as matrículas de 2023.1 a 2025.2, para cada disciplina com pelo menos 100 matrículas, quantas reprovações houve, qual foi a taxa de reprovação, que parte dessas reprovações foi por falta e que parte das matrículas era de alunos repetindo a disciplina?",
     "A coordenação decide onde colocar as vagas de monitoria. O número de reprovações mostra quantos alunos a monitoria pode atingir, e a taxa mostra a gravidade. Quando a maior parte é por falta, reforço de conteúdo pode não bastar.",
     "Agregada e por aluno", "Dispersão de matrículas por taxa de reprovação, com linhas nas medianas",
     "Duas medidas precisam ser lidas juntas: um ranking só pela taxa destacaria disciplinas pequenas, e só por volume, as grandes. O quadrante de muitas matrículas e taxa alta é a prioridade."),
    ("C2. Considerando os alunos ativos ao fim de 2025.2, para cada disciplina, quantos já a cursaram sem aprovação e ainda a devem, separados por curso, quantos deles já reprovaram duas vezes ou mais, e a quantas turmas esse total equivale, usando a média de alunos por turma de 2025.1 e 2025.2? Mostrar as 10 disciplinas com mais pendentes.",
     "O departamento decide em quais disciplinas abrir ou ampliar turmas no próximo semestre. Esses alunos se somam à demanda regular de quem ainda vai cursar pela primeira vez, que fica fora desta conta.",
     "Por aluno e agregada", "Barras horizontais empilhadas por curso",
     "O comprimento mostra o total a absorver, e os segmentos mostram quais cursos pressionam a oferta. As turmas equivalentes entram como rótulo no fim de cada barra."),
    ("C3. Entre os alunos que ingressaram de 2018.1 a 2023.2 e chegaram ao fim do 2º semestre sem evadir, separados por curso e pelo número de reprovações nesses dois semestres (0, 1, 2, 3, 4 ou mais), que parte evadiu depois?",
     "A coordenação define o critério de entrada na tutoria: a partir de quantas reprovações o aluno é chamado. Só entra quem ainda estava no curso ao fim do 1º ano, porque é nesse momento que a decisão seria tomada.",
     "Por aluno", "Colunas por número de reprovações, um painel por curso",
     "As categorias são ordenadas e o que importa é onde a evasão salta. Painéis separados evitam misturar 15 colunas. O número de alunos aparece em cada coluna, porque alguns grupos são pequenos."),
    ("C4. Entre os alunos que ingressaram de 2018.1 a 2020.1, que já têm 12 semestres de histórico, que parte de cada curso já tinha evadido até cada semestre, do 1º ao 12º?",
     "A coordenação decide em que momento do curso concentrar as ações de permanência: onde a curva sobe mais rápido, a ação tende a chegar a tempo de mais alunos.",
     "Por aluno", "Linhas acumuladas, uma por curso",
     "O eixo é uma sequência de tempo, e a inclinação da linha mostra quando a evasão acontece. Usar sempre as mesmas turmas impede que a curva mude só porque os alunos observados mudaram."),
    ("C5. Ao fim de 2025.2, comparando o tempo de curso com o prazo previsto, quantos alunos ativos de cada curso estão no prazo, com até 2 semestres de atraso, com 3 a 4 e com 5 ou mais, e qual é a carga horária média já cursada em cada grupo?",
     "A coordenação dimensiona o plano de integralização: quantos alunos atender e por onde começar. Muito atraso com carga horária alta sugere um aluno perto de concluir.",
     "Por aluno", "Barras horizontais empilhadas por curso, com a carga horária em tabela",
     "Os grupos de atraso são partes ordenadas do total de ativos de cada curso. A carga horária é outra medida, então fica na tabela, sem eixo duplo."),
    ("C6. Para cada faixa econômica, considerando os ingressantes de 2018.1 a 2023.2, que parte evadiu? E, nas matrículas a partir do 2º período, que parte tinha assistência estudantil, e qual foi a taxa de aprovação com e sem o benefício?",
     "A gestão da assistência estudantil decide para quais faixas direcionar o benefício. Evasão alta com pouca cobertura aponta onde ampliar. A comparação começa no 2º período porque, nos dados sintéticos, calouros não recebem o benefício.",
     "Por aluno", "Colunas agrupadas (com e sem benefício) por faixa, com evasão e cobertura em tabela",
     "As faixas são ordenadas, e a distância entre as colunas é a informação. Evasão e cobertura ficam na tabela para evitar um segundo eixo. O resultado mostra associação: não prova efeito do benefício."),
    ("C7. Considerando de 2023.1 a 2025.2 e só professores com pelo menos 30 matrículas na disciplina, para cada disciplina com dois professores ou mais, quais são a menor e a maior taxa de reprovação entre eles, e qual é a diferença em pontos percentuais? Mostrar as 10 maiores diferenças.",
     "A coordenação pedagógica decide em quais disciplinas reunir os professores para alinhar plano de ensino e critérios de avaliação. A consulta aponta disciplinas, não serve para avaliar professores, e não mede as diferenças entre as turmas de cada um.",
     "Agregada e view de professores", "Intervalo (menor e maior taxa ligadas por um segmento), por disciplina",
     "O segmento mostra ao mesmo tempo o nível da disciplina e a distância entre os extremos, o que uma barra só com a diferença esconderia. Turmas com mais de um professor contam para todos eles."),
]

AJUSTES = [
    ("<b>situacao_vinculo</b> e <b>id_data_saida</b> em dim_aluno", "O esquema registrava matrículas, mas não dizia quem concluiu ou evadiu, nem quando.", "C2, C3, C4, C5, C6"),
    ("<b>semestres_previstos</b> em dim_curso", "Sem o prazo de cada curso, não há como saber quem está atrasado.", "C5"),
    ("<b>periodo_aluno</b> em fato_professor_aluno", "Guarda quantos semestres se passaram desde o ingresso. Calculado na carga, dispensa uma tabela de matriz curricular por curso.", "C3, C6"),
    ("<b>qtd_trancamentos</b> em fato_professor_disciplina", "As quatro contagens de situação não fechavam com qtd_matriculados quando havia trancamento, e as taxas ficavam com a base errada.", "C1, C7"),
    ("View <b>vw_turma_professor</b>", "Transforma os três papéis de professor em linhas, sem alterar as tabelas. Evita três joins em cada consulta. O peso reparte turmas com mais de um professor em somas gerais.", "C7"),
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
    h.append(Paragraph("Data Warehouse, UFPE. Entrega da aula de 03/11/2026, revisada depois do retorno do professor.<br/>Equipe: jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb.", sub))
    h.append(Paragraph(
        "Reduzimos as consultas de 13 para 7, cada uma ligada a uma decisão de gestão acadêmica e descrita com população, "
        "período, medidas e agrupamentos. Escolhemos o gráfico de cada uma, ajustamos o que faltava nos esquemas e povoamos "
        "tudo com dados sintéticos. Os scripts rodaram no MySQL 8, o banco definido nos diagramas, e as 7 consultas "
        "executaram sem erro. Partimos das questões do TCC de Espíndola (UFPE, 2025) e as adaptamos aos campos que temos.", corpo))

    h.append(Paragraph("1. Consultas e escolha dos gráficos", secao))
    h.append(Paragraph(
        "\"Agregada\" é a estrela de fato_professor_disciplina, e \"por aluno\" é a de fato_professor_aluno. "
        "O SQL de cada consulta está em sql/05_consultas.sql.", corpo))
    for perg, decisao, estrela, grafico, porque in CONSULTAS:
        h.append(KeepTogether([
            Paragraph(perg, pergunta.clone("pergunta_consulta", spaceAfter=3)),
            Paragraph(f"<b>Decisão:</b> {decisao}", corpo.clone("decisao", spaceAfter=3)),
            Paragraph(f"<b>Estrela:</b> {estrela}. <b>Gráfico:</b> {grafico}. {porque}", corpo.clone("porque", spaceAfter=10)),
        ]))
    h.append(Paragraph(
        "Duas regras valem para todas as consultas. As taxas são calculadas a partir das contagens, nunca como média de "
        "taxas de turmas, porque turmas pequenas pesariam igual às grandes. E a evasão de turmas recentes ainda pode "
        "subir, por isso C3, C4 e C6 limitam o período de ingresso.", corpo))

    h.append(KeepTogether([
        Paragraph("2. Ajustes nos esquemas", secao),
        Paragraph("Mantivemos os grãos, as chaves e as dimensões compartilhadas. Foram cinco acréscimos:", corpo),
        tabela(AJUSTES, [5 * cm, 8.1 * cm, 3 * cm], ["Ajuste", "Por que", "Consultas"]),
    ]))
    h.append(Spacer(1, 8))
    h.append(Paragraph(
        "<b>Pendências do grupo.</b> Ainda falta confirmar se a situação de vínculo e o semestre de saída estão nos PDFs de "
        "origem. Isso pesa em 5 das 7 consultas: C2, C3, C4, C5 e C6 dependem da situação, e C3 e C4 também do semestre de saída. Só C1 e C7 funcionam sem esses campos. Sexo e faixa etária, usados no TCC, não "
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
        "gerador. O risco de evasão no gerador cresce com as reprovações, o que alimenta C3. O benefício e o professor não têm efeito no gerador, então as diferenças em C6 e C7 são acaso. Qualquer padrão nos resultados reflete essas escolhas, não uma descoberta. Alunos e professores são "
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
