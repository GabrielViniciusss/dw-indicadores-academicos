# Tasks — ordem de execução

Tarefas derivadas de [`spec.md`](spec.md), com as decisões de [`plan.md`](plan.md). Cada uma traz os
arquivos que toca e como conferir que ficou pronta.

Convenção: toda tarefa que mexe em esquema ou dados termina com `./scripts/carregar.sh` e
`python3 dashboards/validar.py` passando. Tarefa que não passa não está pronta.

## Fase 0 — Destravar

- [ ] **T0.1 Confirmar o próximo enunciado com a equipe.** Se existir enunciado novo, reescrever a
  seção 4 de `spec.md` antes de qualquer código. Bloqueia tudo.
- [ ] **T0.2 Fechar as quatro decisões em aberto** da seção 6 de `spec.md`: snapshot vs. SCD2,
  renomeações, colunas mortas, e prioridade. Registrar a escolha no fim de `plan.md`.
  Bloqueia T4, T7 e T8.

## Fase 1 — Base conceitual, sem tocar em dados

Nenhuma tarefa desta fase muda um número já apresentado.

- [ ] **T1.1 `indice_semestre` em `dim_data`** (D6)
  - `sql/01_ddl.sql`: coluna nova; `gerador/gerar_dados.py`: preencher sequencial a partir de 20181.
  - `sql/05_consultas.sql`: C11 passa a subtrair índices em vez de `ano * 2 + semestre`.
  - `sql/06_validacao.sql`: o teste de matrícula fora da janela passa a usar o índice.
  - Confere: C11 devolve exatamente os mesmos valores de antes; novo teste garante que o índice é
    contíguo e sem repetição.

- [ ] **T1.2 `dim_situacao_matricula`** (R2, D2)
  - `sql/01_ddl.sql`: tabela com as 5 linhas e as flags; `id_situacao` em `fato_professor_aluno`.
  - `gerador/gerar_dados.py`: gravar `id_situacao` junto de `situacao_final`.
  - `sql/06_validacao.sql`: teste de que toda situação da fato existe na dimensão e que
    `id_situacao` e `situacao_final` concordam.
  - Confere: carga limpa, 17 testes com zero erros.

- [ ] **T1.3 Reescrever C3, C4, C5 e C8 sobre as flags** (R2)
  - `conta_como_resultado` no lugar de `<> 'TRANCADO_DISCIPLINA'`; `eh_reprovacao` no lugar de
    `LIKE 'REPROVADO%'`; `motivo` no lugar da comparação com `'REPROVADO_NOTA'` e
    `'REPROVADO_FALTAS'` em C4.
  - `dashboards/painel.js`: mesma classificação, lendo a dimensão em vez de comparar string.
  - Confere: `grep -E "LIKE '(RE|A)PROVADO|TRANCADO_DISCIPLINA'" sql/05_consultas.sql` não retorna
    nada, e `validar.py` passa com os mesmos resultados.

- [ ] **T1.4 `fato_vinculo_semestre`** (R1, D1)
  - `sql/01_ddl.sql`: tabela nova; `sql/07_snapshot_vinculo.sql`: derivação; `scripts/carregar.sh`:
    executar o novo arquivo na sequência; `scripts/exportar_csv.py`: incluir a tabela.
  - `sql/06_validacao.sql`: as duas regras de aceitação de R1.
  - Confere: no último semestre, 381 ativos, 433 concluídos e 619 evadidos; nenhuma linha antes do
    ingresso.

- [ ] **T1.5 Consulta de retenção sobre o snapshot**
  - Primeira consulta que o snapshot viabiliza: situação da coorte semestre a semestre, em barras
    empilhadas em 100% por período desde o ingresso. É a resposta a "qual era a evasão em 2021.2".
  - Decidir se entra como C14 na numeração da entrega ou como consulta de demonstração fora da lista.
    Ver T0.2.

- [ ] **T1.6 C13, atraso curricular** (R3, D3)
  - `sql/05_consultas.sql`, `dashboards/painel.js`, `dashboards/exploracao.js` se houver investigação,
    `dashboards/validar.py`, e `dashboards/metabase/C13.sql` via `build_demo.py`.
  - Cartão com "Como interpretar" distinguindo `periodo_aluno` de `periodo_curricular` e avisando que
    reprovação acumulada empurra o indicador.
  - Confere: `validar.py` cobre C13; `periodo_curricular` deixa de ter zero leitores.

## Fase 2 — OLAP visível

- [ ] **T2.1 Hierarquia nos dados** (R4, D4)
  - `gerador/gerar_dados.py`: campus e centro distintos para CC, EC e SI; `area` em
    `dim_disciplina`, derivada do prefixo do código.
  - `sql/01_ddl.sql`: coluna `area`.
  - Regenerar na mesma tarefa: dados, CSVs, painel e SQLs do Metabase.
  - Confere: ao menos 2 campi e 2 centros; nenhuma taxa de reprovação, aprovação ou nota muda em
    relação à execução anterior.

- [ ] **T2.2 Consulta de roll-up** (R4)
  - `GROUP BY ... WITH ROLLUP` por campus, centro e curso, com a taxa recalculada em cada nível a
    partir de numerador e denominador.
  - Confere: a linha de total geral coincide com a taxa calculada sobre a base inteira; nenhuma
    média de médias.

- [ ] **T2.3 Drill-down no painel** (R4)
  - Filtros de campus, centro e área, encadeados com os de curso e disciplina.
  - Confere: `validar.py` cobre os filtros novos, inclusive recorte vazio.

## Fase 3 — Corrigir o que engana

- [ ] **T3.1 `coorte_observacao_completa` em `dim_turma_aluno`** (R6)
  - Atributo novo, preenchido na carga. Tira o `2018` de C2, C8 e C11.
  - Confere: `grep -n 2018 sql/05_consultas.sql` não retorna filtro de coorte.

- [ ] **T3.2 Taxa de conclusão em C11** (R6, L7)
  - C11 passa a trazer concluintes sobre ingressantes ao lado da duração média, e a marcar coorte
    incompleta. Cartão do painel explica o viés de sobrevivência.
  - Registrar a mudança de número em `docs/mudancas_esquemas.md`.
  - Confere: a duração média antiga continua na saída; a taxa nova aparece; `validar.py` passa.

- [ ] **T3.3 Medida ponderada em C12** (R5, D5)
  - Coluna `matriculas_atribuidas` usando `tp.peso`; teste novo de que a soma por docente num
    semestre iguala `SUM(qtd_matriculados)` da fato agregada.
  - Cartão explica as duas colunas.
  - Confere: o teste novo dá zero erros.

## Fase 4 — Processo e verificação

- [ ] **T4.1 `log_carga`** (R7, D8)
  - Tabela e preenchimento ao fim de `scripts/carregar.sh`, com data, semente e contagem por tabela.
  - Confere: uma linha por execução; contagens iguais a `COUNT(*)`.

- [ ] **T4.2 Verificação em MySQL 8** (R8, D9)
  - Script novo que roda C1–C13 no MySQL, grava o resultado e compara com a base SQLite de
    `validar.py`, reportando divergência por consulta e coluna.
  - Documentar o comando no README, junto dos outros.
  - Confere: execução registrada, com as divergências encontradas anotadas em `plan.md` seção 10 —
    inclusive "nenhuma", se for o caso.

- [ ] **T4.3 Decidir e executar sobre as colunas mortas** (R10, D7)
  - Depende de T0.2. Se a opção for usar: cartão de distribuição de notas com as 5 faixas, mais
    amplitude com `menor_notas` e `maior_notas`. Se for enxugar: remover de
    `03_carga_fato_agregada.sql`, do DDL, do DBML e dos testes que as citam.
  - Confere: nenhuma coluna de `fato_professor_disciplina` sem leitor ou sem justificativa escrita.

## Fase 5 — Fechar a documentação

Só começa quando as fases 1 a 4 estiverem fechadas, para não documentar duas vezes.

- [ ] **T5.1 DBML e diagrama** (R9)
  - `docs/dbml/v2_esquema.dbml` com `curso_disciplina`, `dim_situacao_matricula`,
    `fato_vinculo_semestre`, `indice_semestre` e `area`. Regenerar `v2_esquema.pdf`.
  - Confere: toda tabela e coluna do `01_ddl.sql` aparece no DBML.

- [ ] **T5.2 `docs/mudancas_esquemas.md`** (R9)
  - Nova seção para este ciclo, no mesmo formato de tabela, com a mudança de número de C11
    explicitada e o SQL equivalente de migração.

- [ ] **T5.3 DrawSQL** (R9)
  - Aplicar nos dois diagramas as colunas já listadas no `mudancas_esquemas.md` mais as deste ciclo.

- [ ] **T5.4 Metabase** (R9)
  - Reexecutar `criar_paineis.py` com as 13 consultas, registrar a versão testada e substituir a
    ressalva atual de "testado com 13 consultas da versão anterior".

- [ ] **T5.5 README, LEIA-ME e roteiro** (R9)
  - Acrescentar `specs/` à tabela de estrutura do README, atualizar a contagem de consultas e de
    testes, e revisar `docs/apresentacao.md` com os argumentos novos: por que snapshot e não SCD2,
    o roll-up, o período curricular agora em uso, e o viés corrigido em C11.

## Fase 6 — Opcional, depois da apresentação

- [ ] **T6.1 Renomear o que engana** (R11, L9)
  - `fato_professor_aluno` → `fato_matricula`, `fato_professor_disciplina` → `fato_rendimento_oferta`,
    `dim_turma_aluno` → `dim_coorte`.
  - Commit único, tocando DDL, gerador, consultas, validação, painel, CSVs, Metabase, DBML e docs.
  - Confere: `validar.py` passa sem alteração de resultado; nenhuma ocorrência do nome antigo.

- [ ] **T6.2 Remover `situacao_final` da fato** (D2)
  - Só depois de T1.3 e T6.1. A classificação passa a vir exclusivamente da dimensão.

- [ ] **T6.3 Medição de plano de execução**
  - Se a disciplina cobrar desempenho: `EXPLAIN ANALYZE` nas consultas mais pesadas, com e sem
    índice composto, e registro do resultado. Sem medição, não criar índice.

## Rastreabilidade

| Requisito | Tarefas |
| --- | --- |
| R1 snapshot de vínculo | T1.4, T1.5 |
| R2 dimensão de situação | T1.2, T1.3, T6.2 |
| R3 período curricular / C13 | T1.6 |
| R4 hierarquia e roll-up | T2.1, T2.2, T2.3 |
| R5 peso da ponte | T3.3 |
| R6 viés de C11 | T3.1, T3.2 |
| R7 linhagem | T4.1 |
| R8 verificação em MySQL | T4.2 |
| R9 documentação | T5.1 a T5.5 |
| R10 colunas mortas | T4.3 |
| R11 renomeações | T6.1 |
| D6 índice de semestre | T1.1 |
