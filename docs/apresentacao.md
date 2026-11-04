# Guia da apresentação

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

**Falar:** depois do retorno do professor, trocamos 13 consultas por 7, cada uma ligada a uma decisão de gestão. Cada descrição diz a população, o período, as medidas e os agrupamentos, e nenhuma se responde com sim ou não. Vamos apresentar três exemplos.

| Consulta | Decisão | Gráfico e motivo |
| --- | --- | --- |
| C1. Volume e taxa de reprovação por disciplina, de 2023.1 a 2025.2 | Onde colocar as vagas de monitoria | Dispersão: um ranking só pela taxa destacaria disciplinas pequenas. O quadrante de muitas matrículas e taxa alta é a prioridade. |
| C3. Evasão posterior, conforme as reprovações no 1º ano | A partir de quantas reprovações chamar o aluno para a tutoria | Colunas por curso: as categorias são ordenadas, e o que importa é onde a evasão salta. |
| C4. Evasão acumulada até cada semestre do curso | Em que momento concentrar as ações de permanência | Linhas: a inclinação mostra quando a evasão acontece. |

**Se perguntarem sobre as outras:** todas estão no PDF, com a decisão e o motivo do gráfico.

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
- **Os dados são fictícios.** Colocamos alguns padrões de propósito para testar as consultas, e nenhum número descreve a UFPE.

**Opção A: rodar no banco.** Precisa do MySQL com os dados carregados, como explica o `README.md`:

```bash
sudo service mysql start
sudo mysql --table < sql/05_consultas.sql | less
```

**Opção B: mostrar o resultado pronto.** São as cinco primeiras linhas da consulta C1:

| Disciplina | Matrículas | Reprovações | Taxa de reprovação (%) |
| --- | ---: | ---: | ---: |
| Introdução à Programação | 637 | 268 | 43,7 |
| Algoritmos e Estruturas de Dados | 562 | 228 | 42,4 |
| Cálculo 1 | 456 | 209 | 47,4 |
| Álgebra Vetorial | 566 | 201 | 36,9 |
| Matemática Discreta | 521 | 183 | 36,5 |

Também dá para abrir `dados/csv/fato_professor_aluno.csv` no GitHub para mostrar os dados linha a linha.

## Parte 5: pendência e próximo passo (1 min)

**Falar:**

- Ainda falta confirmar se a situação de vínculo e o semestre de saída estão nos PDFs de origem. Cinco das sete consultas dependem desses campos: C2, C3, C4, C5 e C6.
- O próximo passo é transformar essas consultas em painéis, usando os mesmos dados.

## Perguntas que podem aparecer

**Por que duas tabelas fato?**
Elas têm grãos diferentes. A fato por aluno permite ver o percurso de cada um, e a agregada responde mais rápido as perguntas sobre turma e disciplina.

**A agregada não é redundante?**
É, de propósito. Ela é uma tabela pré-calculada, derivada da fato por aluno, e os testes conferem se os totais das duas batem.

**O que mudou nas consultas depois do retorno do professor?**
Saíram as consultas básicas e as que se respondiam com sim ou não. Cada uma das sete agora diz qual decisão apoia e descreve população, período, medidas e agrupamentos.

**Por que a C3 só conta quem chegou ao fim do 2º semestre?**
Porque a decisão da tutoria seria tomada nesse momento. Quem já tinha evadido não poderia mais ser chamado, e a evasão dele distorceria o critério.

**Por que a C4 usa só as turmas de 2018.1 a 2020.1?**
Porque só elas têm 12 semestres de histórico. Com as mesmas turmas em todos os pontos, a curva não muda apenas porque os alunos observados mudaram.

**Quais são as regras de aprovação?**
Nota a partir de 7 aprova direto. Abaixo de 3 reprova sem final. De 3 a 6,99 faz a final e precisa de média final de pelo menos 5. Mais de 25% da carga horária em faltas reprova por falta. O gerador guarda só a nota final, sem simular a prova em separado.

**Por que a evasão está tão alta nos dados?**
Porque esse é um resultado do gerador, e não uma medição. Esse número não deve ser lido como a evasão real de nenhum curso.

**A assistência estudantil aumenta a aprovação?**
Não dá para concluir isso com estes dados. No gerador, o benefício não influencia o resultado, e as diferenças da C6 são acaso. Com dados reais, a consulta mostraria uma associação, não um efeito.

**A C7 serve para avaliar professores?**
Não. Ela aponta disciplinas em que vale alinhar critérios. Nos dados sintéticos, o professor não influencia o resultado, então as diferenças são acaso.

**O que acontece se os campos novos não existirem na fonte real?**
Só C1 e C7 continuam funcionando como estão. As outras cinco precisariam de outra fonte para a situação do aluno.
