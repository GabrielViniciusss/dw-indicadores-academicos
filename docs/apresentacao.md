# Guia da apresentação

Roteiro para quem vai apresentar os esquemas, as consultas e o painel. O enunciado não define tempo nem formato, então a divisão abaixo é uma sugestão para cerca de 12 minutos. Se o tempo for menor, mantenha as partes 1, 2 e 5.

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

**Repositório:** https://github.com/GabrielViniciusss/dw-indicadores-academicos

**Painel publicado:** https://painel-dw-academico.vercel.app

**Looker Studio:** https://datastudio.google.com/u/0/reporting/71ecbe69-ab26-4506-abd8-6cea87179df2/page/hvDDG

## Antes da aula

- [ ] Abrir o PDF `docs/entrega_05_11.pdf`.
- [ ] Abrir o diagrama `docs/dbml/v2_esquema.pdf`. Ele ainda não mostra a tabela `curso_disciplina`; se perguntarem, ela está no DBML e no `sql/01_ddl.sql`.
- [ ] Abrir o painel publicado e conferir se carrega. Sem internet, use o arquivo `dashboards/painel_academico_interativo.html`.
- [ ] Abrir o repositório no navegador.

## Parte 1: o esquema (2 min)

**Mostrar:** o diagrama do esquema.

**Falar:**

- É um esquema com duas estrelas que compartilham as dimensões de data, curso, disciplina, professor e turma da disciplina.
- `fato_professor_aluno` tem uma linha por matrícula. Ela responde perguntas sobre o aluno, como período, cota, assistência e evasão.
- `fato_professor_disciplina` tem uma linha por oferta e curso, sem aluno individual. Ela responde perguntas sobre a turma e a disciplina, como taxas e distribuição de notas.
- Não existe uma estrela por professor. A turma guarda até três professores, e a view `vw_turma_professor` transforma esses papéis em linhas.

## Parte 2: consultas e gráficos (3 min)

**Mostrar:** a seção 1 do PDF.

**Falar:** as 12 consultas estão em ordem de prioridade. Cada uma explica para que serve, quais dados usa, qual gráfico mostra e por que esse gráfico. As imagens do PDF são exemplos ilustrativos; o painel mostra os valores calculados. Vamos apresentar três exemplos.

| Consulta | Para que serve | Gráfico e motivo |
| --- | --- | --- |
| C1. Em cada semestre, quais são as 10 disciplinas com maior taxa de reprovação, separando nota e falta? | Mostra onde investir em monitoria ou em acompanhamento da frequência | Barras horizontais empilhadas: a ordem destaca as críticas, e a divisão mostra o tipo de ação. |
| C2. Em cada turma de ingresso, qual é a proporção de alunos que concluíram, continuam ativos ou evadiram? | Compara turmas de ingresso para planejar ações de permanência | Barras empilhadas em 100%: a parte de ativos evita ler as turmas novas como piores. |
| C10. Quais turmas tiveram reprovação muito acima ou abaixo do histórico da mesma disciplina no curso? | Aponta turmas atípicas para investigar o contexto | Barras divergentes: o zero é o histórico da própria disciplina. |

**Se perguntarem sobre as outras:** todas estão no PDF e no painel, com a mesma numeração.

## Parte 3: ajustes no esquema (2 min)

**Mostrar:** a tabela da seção 2 do PDF, ou `docs/mudancas_esquemas.md`.

**Falar:** as consultas mostraram o que faltava. Mantivemos os grãos e as chaves, e fizemos seis acréscimos:

| Ajuste | Por que |
| --- | --- |
| `situacao_vinculo` e `id_data_saida` em `dim_aluno` | Sem eles, não dá para saber quem concluiu ou evadiu, nem quando. |
| `semestres_previstos` em `dim_curso` | Sem o prazo, não há com o que comparar o tempo de conclusão. |
| `periodo_aluno` em `fato_professor_aluno` | Mostra em que momento da trajetória a matrícula aconteceu. |
| `qtd_trancamentos` em `fato_professor_disciplina` | As contagens de situação não fechavam com `qtd_matriculados` quando havia trancamento. |
| Tabela `curso_disciplina` | Guarda o período curricular de cada disciplina em cada curso. |
| View `vw_turma_professor` | Evita três joins para analisar por professor. |

## Parte 4: dados sintéticos (2 min)

**Mostrar:** a seção 3 do PDF.

**Falar:**

- O gerador simula cada aluno semestre a semestre, de 2018.1 a 2025.2: são 1.433 alunos e 30.992 matrículas.
- A fato agregada é calculada em SQL a partir da fato por aluno, então as duas estrelas sempre fecham.
- Rodamos 16 testes de consistência, e todos deram zero erros.
- **Os dados são fictícios.** Colocamos alguns padrões de propósito para testar as consultas, e nenhum número descreve a UFPE.

## Parte 5: o painel (3 min)

**Mostrar:** o painel publicado.

**Falar e fazer:**

- São quatro páginas: visão geral (C1, C6, C7), desempenho acadêmico (C4, C5, C9), permanência e equidade (C2, C3, C8, C11) e turmas e docência (C10, C12).
- Os filtros de curso, semestre, turma de ingresso e disciplina recalculam todos os gráficos.
- Na C1, clicar em uma disciplina abre a investigação: evolução histórica, faltas e turmas e docentes.
- Cada cartão tem "Como interpretar", tabela e CSV. O botão de ampliar abre filtros só daquela consulta.
- Um script compara os resultados do painel com as 12 consultas SQL, linha a linha.

**Se o professor pedir uma ferramenta de BI:** mostrar o Looker Studio, ou citar a configuração do Metabase em `dashboards/metabase/`.

**Opção sem internet: resultado pronto.** São as cinco primeiras linhas da C1 em 2025.2 para o curso CC, nos dados fictícios:

| Disciplina | Matrículas | Reprovação por nota (%) | Reprovação por falta (%) |
| --- | ---: | ---: | ---: |
| Cálculo 1 | 36 | 44,4 | 5,6 |
| Matemática Discreta | 21 | 47,6 | 0,0 |
| Álgebra Vetorial | 32 | 37,5 | 9,4 |
| Probabilidade e Estatística | 16 | 43,8 | 0,0 |
| Algoritmos e Estruturas de Dados | 30 | 36,7 | 6,7 |

## Perguntas que podem aparecer

**Por que duas tabelas fato?**
Elas têm grãos diferentes. A fato por aluno permite ver o percurso de cada um, e a agregada responde mais rápido as perguntas sobre turma e disciplina.

**A agregada não é redundante?**
É, de propósito. Ela é uma tabela pré-calculada, derivada da fato por aluno, e os testes conferem se os totais das duas batem.

**Como as consultas seguem as orientações do professor?**
Elas mantêm o semestre, o curso e a turma como filtros ou agrupamentos, separam reprovação por nota e por falta (C1 e C4) e comparam cada turma com o histórico da própria disciplina (C10). O período curricular está na tabela `curso_disciplina`, mas nenhuma das 12 consultas o usa: a C4 mede semestres desde o ingresso.

**Quais são as regras de aprovação?**
Nota a partir de 7 aprova direto. Abaixo de 3 reprova sem final. De 3 a 6,99 faz a final e precisa de média final de pelo menos 5. Mais de 25% da carga horária em faltas reprova por falta. O gerador guarda só a nota final, sem simular a prova em separado.

**Por que a evasão está tão alta nos dados?**
Porque esse é um resultado do gerador, e não uma medição. Esse número não deve ser lido como a evasão real de nenhum curso.

**A assistência estudantil reduz a reprovação?**
Não dá para concluir isso com estes dados. No gerador, o benefício não influencia o resultado, e calouros não o recebem. Com dados reais, a C3 mostraria uma associação, não um efeito.

**A C10 ou a C12 servem para avaliar professores?**
Não sozinhas. A C10 aponta turmas fora do padrão da própria disciplina, e a C12 compara ofertas para conversas pedagógicas. Nos dados sintéticos, o professor não influencia o resultado, então as diferenças são acaso.
