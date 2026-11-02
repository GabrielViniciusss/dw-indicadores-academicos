# Guia da apresentação de 03/11

Roteiro para quem vai apresentar a construção dos esquemas. O enunciado não define tempo nem formato, então a divisão abaixo é uma sugestão para cerca de 10 minutos. Se o tempo for menor, mantenha as partes 1, 2 e 3.

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

**Repositório:** https://github.com/GabrielViniciusss/dw-indicadores-academicos

## Antes da aula

- [ ] Abrir o PDF `docs/entrega_03_11.pdf`.
- [ ] Abrir os diagramas do DrawSQL e confirmar se já têm os ajustes. Se não tiverem, abrir também `docs/mudancas_esquemas.md`.
- [ ] Abrir o repositório no navegador.
- [ ] Decidir como mostrar os dados, seguindo a parte 4. Se for usar o banco, testar a consulta antes da aula.

## Parte 1: os esquemas (2 min)

**Mostrar:** os diagramas PDFs e PDFs 2.

**Falar:**

- Temos duas estrelas que compartilham as dimensões de data, curso, disciplina, professor e turma da disciplina.
- `fato_professor_aluno` tem uma linha por matrícula. Ela responde perguntas sobre o aluno, como período, tentativa, cota e evasão.
- `fato_professor_disciplina` tem uma linha por oferta e curso, sem aluno individual. Ela responde perguntas sobre a turma e a disciplina, como taxas e distribuição de notas.
- Não existe uma estrela por professor. A turma guarda até três professores, e a view `vw_turma_professor` transforma esses papéis em linhas.

## Parte 2: consultas e gráficos (3 min)

**Mostrar:** a seção 1 do PDF.

**Falar:** levantamos 13 consultas e vamos apresentar três exemplos. Os gráficos prontos ficam para a entrega de 05/11; hoje mostramos a escolha e o motivo.

| Consulta | Gráfico | Argumento |
| --- | --- | --- |
| C1. Como a taxa de aprovação evoluiu a cada semestre, por curso? | Linhas, uma por curso | O tempo é contínuo e ordenado, e a linha mostra a tendência. Em colunas, seriam 48 barras difíceis de seguir. |
| C5. Em que semestres cada disciplina crítica ficou pior? | Mapa de calor | São duas dimensões e 128 valores. A cor destaca os pontos fora do padrão, e 8 linhas sobrepostas ficariam ilegíveis. |
| C9. O que aconteceu com cada coorte de ingresso? | Barras empilhadas em 100% | Cada coorte soma 100%. A parte de ativos evita concluir que as coortes recentes vão mal, quando elas apenas ainda estão no curso. |

**Se perguntarem sobre as outras:** todas estão no PDF, cada uma com o motivo do gráfico.

## Parte 3: ajustes nos esquemas (2 min)

**Mostrar:** a tabela da seção 2 do PDF, ou `docs/mudancas_esquemas.md`.

**Falar:** as consultas mostraram o que faltava. Mantivemos os grãos e as chaves, e fizemos cinco acréscimos:

| Ajuste | Por que |
| --- | --- |
| `situacao_vinculo` e `id_data_saida` em `dim_aluno` | Sem eles, não dá para saber quem concluiu ou evadiu, nem quando. |
| `semestres_previstos` em `dim_curso` | Sem o prazo, não há com o que comparar o tempo de conclusão. |
| `periodo_aluno` em `fato_professor_aluno` | Mostra em que momento do curso a matrícula aconteceu. |
| `qtd_trancamentos` em `fato_professor_disciplina` | As contagens de situação não fechavam com `qtd_matriculados` quando havia trancamento. |
| View `vw_turma_professor` | Evita três joins para analisar por professor. |

## Parte 4: dados sintéticos (2 min)

**Mostrar:** a seção 3 do PDF e o resultado de uma consulta.

**Falar:**

- O gerador simula cada aluno semestre a semestre, de 2018.1 a 2025.2: são 1.433 alunos e 30.992 matrículas.
- A fato agregada é calculada em SQL a partir da fato por aluno, então as duas estrelas sempre fecham.
- Rodamos 15 testes de consistência, e todos deram zero erros.
- **Os dados são fictícios.** Colocamos alguns padrões de propósito para o painel ter o que mostrar, e nenhum número descreve a UFPE.

**Opção A: rodar no banco.** Precisa do MySQL com os dados carregados, como explica o `README.md`:

```bash
sudo service mysql start
sudo mysql dw_academico --table -e "SELECT di.nome_disciplina, SUM(f.qtd_matriculados) AS matriculados, ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas) / SUM(f.qtd_matriculados - f.qtd_trancamentos), 1) AS taxa_reprovacao FROM fato_professor_disciplina f JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina GROUP BY di.nome_disciplina HAVING SUM(f.qtd_matriculados) >= 100 ORDER BY taxa_reprovacao DESC LIMIT 10;"
```

**Opção B: mostrar o resultado pronto.** É a saída da consulta C2:

| Disciplina | Matriculados | Taxa de reprovação (%) |
| --- | ---: | ---: |
| Cálculo 1 | 1.229 | 47,3 |
| Introdução à Programação | 1.637 | 41,3 |
| Física Geral 1 | 447 | 38,8 |
| Algoritmos e Estruturas de Dados | 1.436 | 38,5 |
| Álgebra Vetorial | 1.521 | 37,5 |

Também dá para abrir `dados/csv/fato_professor_aluno.csv` no GitHub para mostrar os dados linha a linha.

## Parte 5: pendência e próximo passo (1 min)

**Falar:**

- Ainda falta confirmar se a situação de vínculo e o semestre de saída estão nos PDFs de origem. Se não estiverem, as consultas C9, C10 e C11 ficam sem base nos dados reais.
- Na entrega de 05/11, vamos transformar essas consultas em painéis, usando os mesmos dados.

## Perguntas que podem aparecer

**Por que duas tabelas fato?**
Elas têm grãos diferentes. A fato por aluno permite ver o percurso de cada um, e a agregada responde mais rápido as perguntas sobre turma e disciplina.

**A agregada não é redundante?**
É, de propósito. Ela é uma tabela pré-calculada, derivada da fato por aluno, e os testes conferem se os totais das duas batem.

**Por que não dá para tirar a média das médias?**
Porque turmas pequenas pesariam igual às grandes. Por isso a média geral é `soma_notas_finais / qtd_notas_validas`. A mediana não se agrega, e precisa ser calculada sobre as notas individuais.

**Por que as faixas de nota têm larguras diferentes?**
Elas seguem a regra da disciplina: abaixo de 3 o aluno não vai para a final, e de 3 a 6,99 ele faz a final. Por isso o gráfico da C4 é de colunas por faixa, e não um histograma de verdade.

**Por que `periodo_aluno`, e não o período ideal da disciplina?**
Ele é calculado a partir da coorte e do semestre da matrícula, então dispensa uma tabela de matriz curricular por curso. Ele mede quando o aluno cursou, não quando deveria ter cursado.

**Quais são as regras de aprovação?**
Nota a partir de 7 aprova direto. Abaixo de 3 reprova sem final. De 3 a 6,99 faz a final e precisa de média final de pelo menos 5. Mais de 25% da carga horária em faltas reprova por falta. O gerador guarda só a nota final, sem simular a prova em separado.

**Por que a evasão está tão alta nos dados?**
Porque esse é um resultado do gerador, e não uma medição. Algumas coortes passam de 50%, e esse número não deve ser lido como a evasão real de nenhum curso.

**Os bolsistas aprovam mais?**
Não dá para concluir isso com estes dados. No gerador só há bolsa a partir do 2º período, então o grupo sem bolsa inclui os calouros, que reprovam mais.

**Por que comparar professores só dentro da mesma disciplina?**
Porque um ranking geral puniria quem ensina as disciplinas mais difíceis.

**O que acontece se os campos novos não existirem na fonte real?**
As consultas de coorte e tempo de conclusão não poderiam ser feitas com os dados reais. As outras dez continuam valendo.
