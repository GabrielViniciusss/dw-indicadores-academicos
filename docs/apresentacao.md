# Guia da apresentação

Roteiro para quem vai apresentar a construção dos esquemas. O enunciado não define tempo nem formato, então a divisão abaixo é uma sugestão para cerca de 10 minutos. Se o tempo for menor, mantenha as partes 1, 2 e 3.

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

**Repositório:** https://github.com/GabrielViniciusss/dw-indicadores-academicos

## Antes da aula

- [ ] Abrir o PDF `docs/entrega_03_11.pdf`.
- [ ] Abrir o diagrama do DrawSQL e confirmar se já tem os ajustes. Se não tiverem, abrir também `docs/mudancas_esquemas.md`.
- [ ] Abrir o repositório no navegador.
- [ ] Decidir como mostrar os dados, seguindo a parte 4. Se for usar o banco, testar a consulta antes da aula.

## Parte 1: o esquema (2 min)

**Mostrar:** o diagrama do esquema.

**Falar:**

- O esquema tem duas estrelas que compartilham as dimensões de data, curso, disciplina, professor e turma da disciplina.
- `fato_professor_aluno` tem uma linha por matrícula. Ela responde perguntas sobre o aluno, como período, tentativa, cota e evasão.
- `fato_professor_disciplina` tem uma linha por oferta e curso, sem aluno individual. Ela responde perguntas sobre a turma e a disciplina, como taxas e distribuição de notas.
- Não existe uma estrela por professor. A turma guarda até três professores, e a view `vw_turma_professor` transforma esses papéis em linhas.

## Parte 2: consultas e gráficos (3 min)

**Mostrar:** a seção 1 do PDF.

**Falar:** cada uma das 13 consultas explica para que serve, quais dados usa, qual gráfico mostra e por que esse gráfico. Os gráficos do PDF são exemplos ilustrativos, com valores fictícios. Vamos apresentar três exemplos.

| Consulta | Para que serve | Gráfico e motivo |
| --- | --- | --- |
| C1. Como a taxa de aprovação de cada disciplina crítica mudou de um semestre para outro? | Mostra se uma disciplina está melhorando ou piorando, para a coordenação investigar | Linhas: os semestres seguem uma ordem, e a linha mostra a tendência. |
| C4. Em um curso, quais professores têm taxa de reprovação mais distante da média das disciplinas que ministram? | Mostra onde vale investigar e alinhar critérios de avaliação | Barras divergentes: o zero é a média das disciplinas. |
| C9. Em cada turma de ingresso, qual é a proporção de alunos que concluíram, que seguem ativos e que evadiram? | Compara turmas de ingresso para planejar ações de permanência | Barras empilhadas: a parte de ativos evita ler as turmas novas como piores. |

**Se perguntarem sobre as outras:** todas estão no PDF, no mesmo formato.

## Parte 3: ajustes no esquema (2 min)

**Mostrar:** a tabela da seção 2 do PDF, ou `docs/mudancas_esquemas.md`.

**Falar:** as consultas mostraram o que faltava. Mantivemos os grãos e as chaves, e fizemos seis acréscimos:

| Ajuste | Por que |
| --- | --- |
| `situacao_vinculo` e `id_data_saida` em `dim_aluno` | Sem eles, não dá para saber quem concluiu ou evadiu, nem quando. |
| `semestres_previstos` em `dim_curso` | Sem o prazo, não há com o que comparar o tempo de conclusão. |
| `periodo_aluno` em `fato_professor_aluno` | Mostra em que momento do curso a matrícula aconteceu. |
| `qtd_trancamentos` em `fato_professor_disciplina` | As contagens de situação não fechavam com `qtd_matriculados` quando havia trancamento. |
| Tabela `curso_disciplina` | Guarda o período curricular de cada disciplina em cada curso. |
| View `vw_turma_professor` | Evita três joins para analisar por professor. |

## Parte 4: dados sintéticos (2 min)

**Mostrar:** a seção 3 do PDF e o resultado de uma consulta.

**Falar:**

- O gerador simula cada aluno semestre a semestre, de 2018.1 a 2025.2: são 1.433 alunos e 30.992 matrículas.
- A fato agregada é calculada em SQL a partir da fato por aluno, então as duas estrelas sempre fecham.
- Rodamos 16 testes de consistência, e todos deram zero erros.
- **Os dados são fictícios.** Colocamos alguns padrões de propósito para testar as consultas, e nenhum número descreve a UFPE.

**Opção A: rodar no banco.** Precisa do MySQL com os dados carregados, como explica o `README.md`:

```bash
sudo service mysql start
sudo mysql --table < sql/05_consultas.sql | less
```

**Opção B: mostrar o resultado pronto.** São as cinco primeiras linhas da consulta C2 em 2025.2, nos dados fictícios:

| Disciplina | Reprovação por nota (%) | Reprovação por falta (%) |
| --- | ---: | ---: |
| Física Geral 1 | 57,1 | 9,5 |
| Cálculo 1 | 46,9 | 6,3 |
| Algoritmos e Estruturas de Dados | 39,1 | 13,0 |
| Álgebra Vetorial | 36,1 | 10,8 |
| Introdução à Programação | 40,2 | 6,5 |

Também dá para abrir `dados/csv/fato_professor_aluno.csv` no GitHub para mostrar os dados linha a linha.

## Parte 5: pendência e próximo passo (1 min)

**Falar:**

- Ainda falta confirmar se a situação de vínculo e o semestre de saída estão nos PDFs de origem. C9, C10, C11 e C13 dependem desses campos.
- O próximo passo é transformar essas consultas em painéis, usando os mesmos dados.

## Perguntas que podem aparecer

**Por que duas tabelas fato?**
Elas têm grãos diferentes. A fato por aluno permite ver o percurso de cada um, e a agregada responde mais rápido as perguntas sobre turma e disciplina.

**A agregada não é redundante?**
É, de propósito. Ela é uma tabela pré-calculada, derivada da fato por aluno, e os testes conferem se os totais das duas batem.

**Como as consultas seguem as orientações do professor?**
Elas mantêm o semestre e a turma como filtros ou agrupamentos, separam reprovação por nota e por falta, e a C5 considera o período curricular.

**Quais são as regras de aprovação?**
Nota a partir de 7 aprova direto. Abaixo de 3 reprova sem final. De 3 a 6,99 faz a final e precisa de média final de pelo menos 5. Mais de 25% da carga horária em faltas reprova por falta. O gerador guarda só a nota final, sem simular a prova em separado.

**Por que a evasão está tão alta nos dados?**
Porque esse é um resultado do gerador, e não uma medição. Esse número não deve ser lido como a evasão real de nenhum curso.

**A assistência estudantil reduz a reprovação e a evasão?**
Não dá para concluir isso com estes dados. No gerador, o benefício não influencia o resultado, e calouros não o recebem. Com dados reais, a C13 mostraria uma associação, não um efeito.

**A C4 serve para avaliar professores?**
Não sozinha. Ela aponta onde investigar a causa e alinhar critérios. Nos dados sintéticos, o professor não influencia o resultado, então as diferenças são acaso.

**O que acontece se os campos novos não existirem na fonte real?**
C9, C10, C11 e C13 não poderiam ser feitas com os dados reais. As outras nove continuam valendo.
