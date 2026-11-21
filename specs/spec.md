# Spec — próximo ciclo do DW de indicadores acadêmicos

Especificação do que construir a seguir e por quê. Disciplina de Data Warehouse, UFPE.
Escrita em 21/11/2026, depois das entregas de 03/11 (esquemas) e 05/11 (visualização).

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

Documentos irmãos: [`plan.md`](plan.md) traz as decisões técnicas, [`tasks.md`](tasks.md) a ordem de execução.

## 1. Para que serve este documento

As duas entregas anteriores foram orientadas por perguntas de gestão: escolhemos 12 consultas úteis
para a coordenação e ajustamos o esquema até elas responderem. Isso deu um projeto coerente, mas
deixou de fora conceitos que a disciplina cobra e que hoje não têm como ser demonstrados com o
repositório na mão.

Esta spec fecha essa distância. Ela parte do que existe, nomeia o que falta com evidência no código,
e define requisitos verificáveis para o próximo ciclo.

## 2. Linha de base: o que existe hoje

| Camada | Estado |
| --- | --- |
| Modelo | Um banco, `dw_academico`, com duas estrelas e cinco dimensões compartilhadas |
| Grão da fato individual | `fato_professor_aluno`: 1 linha por aluno × oferta × curso — 30.992 linhas |
| Grão da fato agregada | `fato_professor_disciplina`: 1 linha por oferta × curso — 2.211 linhas, derivada da primeira em SQL |
| Dimensões | `dim_data` (16 semestres), `dim_curso` (3), `dim_disciplina` (42), `dim_professor` (40), `dim_turma_disciplina` (875), `dim_turma_aluno` (72 coortes), `dim_aluno` (1.433) |
| Ponte | View `vw_turma_professor`, com `peso = 1/n` por oferta |
| Matriz curricular | Tabela `curso_disciplina`, com `periodo_curricular` |
| Carga | `gerador/gerar_dados.py` (semente fixa) → DDL → dados → derivação da agregada → views |
| Qualidade | 16 testes em `sql/06_validacao.sql`, todos com zero erros |
| Consultas | C1 a C12 em `sql/05_consultas.sql`, em ordem de prioridade |
| Visualização | Painel HTML offline (4 páginas), Looker Studio, configuração de Metabase |
| Verificação cruzada | `dashboards/validar.py` compara o JavaScript do painel com as 12 consultas em SQLite |

O que esse conjunto já faz bem, e que o próximo ciclo não deve desmontar: as duas estrelas fecham por
construção, as taxas guardam numerador e denominador em vez de razões prontas, os limites de leitura
de cada indicador estão escritos, e os dados são declaradamente fictícios.

## 3. Lacunas, com evidência

Cada linha foi conferida no repositório em 21/11/2026.

| # | Lacuna | Evidência | Por que importa |
| --- | --- | --- | --- |
| L1 | Nenhuma dimensão é historicizada. `dim_aluno.situacao_vinculo` é um retrato final, sobrescrito | `dashboards/LEIA-ME.md`: "O vínculo é um retrato final da base; não é reconstituído para cada semestre" | Dimensão de mudança lenta é conceito central da disciplina. Sem ela, C2 e C8 aplicam o estado de hoje a coortes antigas, e não há como responder "qual era a evasão em 2021.2?" |
| L2 | `situacao_final` é texto livre, e as consultas classificam por `LIKE 'REPROVADO%'` e `<> 'TRANCADO_DISCIPLINA'` | `sql/05_consultas.sql`, C3, C4, C5, C8 | A regra de negócio "o que conta como resultado" está repetida em quatro consultas, em string. Uma dimensão de situação com flags centraliza isso |
| L3 | `curso_disciplina.periodo_curricular` nunca é lido | `grep periodo_curricular`: zero ocorrências em consultas, validação e painel | O professor pediu para considerar o período curricular. Hoje a tabela existe, é validada e não responde nada |
| L4 | 14 das 28 colunas de `fato_professor_disciplina` não são lidas por consulta alguma | `menor_notas`, `maior_notas`, `mediana_notas`, `media_notas`, `media_faltas`, as 5 faixas `qtd_nota_*` e as 4 `qtd_bolsistas_*` só aparecem em `06_validacao.sql` | Medida que ninguém consome não é agregado, é peso morto. E `mediana_notas` é não aditiva: não se recupera em nenhuma reagregação |
| L5 | A hierarquia de drill-down existe no esquema e é constante nos dados | `dados/csv/dim_curso.csv`: os 3 cursos têm `departamento` e `centro` = "Centro de Informatica" e `campus` = "Recife". `dim_disciplina` não tem área nem departamento | Roll-up e drill-down são a operação básica de OLAP e não há por onde demonstrá-los |
| L6 | O `peso` da ponte é validado e nunca aplicado | `06_validacao.sql` testa que os pesos somam 1 por turma; C12 não usa `tp.peso` | A salvaguarda contra dupla contagem por docente está construída e desligada |
| L7 | C11 mede tempo de conclusão só entre concluintes | `sql/05_consultas.sql`, C11: `WHERE a.situacao_vinculo = 'CONCLUIDO'` | Viés de sobrevivência: coortes recentes parecem mais rápidas porque só os rápidos já concluíram. Sem a taxa de conclusão ao lado, a média engana |
| L8 | `ano_ingresso >= 2018` está escrito em três consultas | C2, C8 e C11 | Regra de observação parcial embutida em SQL, em vez de atributo da dimensão |
| L9 | Nomes das fatos não descrevem o grão | `fato_professor_aluno` não tem `id_professor`; `fato_professor_disciplina` também não. `dim_turma_aluno` é coorte de ingresso, não turma | `docs/apresentacao.md` precisa de uma frase só para desfazer o mal-entendido. O DBML precisa de um `Note` avisando que não é a turma cursada |
| L10 | A carga é recriação total, sem linhagem | `03_carga_fato_agregada.sql` começa com `DELETE FROM`; nenhuma tabela registra quando carregou, com que semente ou quantas linhas | Carga incremental, auditoria e linhagem são assunto de ETL na disciplina |
| L11 | A verificação cruzada roda em SQLite, não em MySQL | `dashboards/validar.py` monta um banco em memória e faz `replace('100 *', '100.0 *')` para compensar a divisão | Prova consistência de cálculo, não equivalência no MySQL 8. A própria substituição mostra que a semântica difere |
| L12 | Dívida de documentação conhecida | `v2_esquema.pdf` não mostra `curso_disciplina`; os diagramas do DrawSQL seguem desatualizados; o importador do Metabase foi testado com 13 consultas, não com as 12 atuais | Três pontos que a banca pode abrir e encontrar divergência entre diagrama e DDL |
| L13 | Atributos de dimensão sem uso analítico | `creditos`, `horario`, `forma_ingresso`, `versao_curriculo` e `qtd_tentativas` não aparecem em nenhuma consulta | Não é erro, mas cada um é uma pergunta que o esquema já pode responder e não responde |

## 4. Escopo do próximo ciclo

### Dentro

Historicização do vínculo, dimensão de situação, uso do período curricular, hierarquia navegável,
correção do viés de C11, aplicação do peso da ponte, linhagem mínima de carga, verificação em MySQL
e quitação da dívida de documentação.

### Fora

Trocar de SGBD, trocar o painel HTML por ferramenta nativa de BI, incluir sexo ou faixa etária
(excluídos por decisão de privacidade, ver `docs/entrega_05_11.pdf`), e usar dados reais da UFPE.
Tudo continua sintético.

### Invariantes

Nenhum requisito abaixo pode quebrar o que já está entregue:

1. As duas estrelas continuam fechando: matrículas, soma de notas e soma de faltas idênticas.
2. Os 16 testes atuais continuam retornando zero erros, e nenhum é removido.
3. As 12 consultas C1–C12 continuam devolvendo os mesmos resultados, linha a linha, salvo onde um
   requisito mudar o indicador de propósito (apenas R6).
4. `dashboards/validar.py` continua passando.
5. A semente do gerador continua fixa, e a reprodução continua sendo `./scripts/carregar.sh`.
6. Nenhum número passa a descrever a UFPE.

## 5. Requisitos

Prioridade P0 é o que um avaliador de Data Warehouse provavelmente vai cobrar; P1 é qualidade do que
já existe; P2 depende de decisão em aberto.

### R1 — Snapshot periódico do vínculo (P0, resolve L1)

Criar `fato_vinculo_semestre`, uma linha por aluno × semestre desde o ingresso, com a situação
naquele semestre. Derivada em SQL de `dim_aluno` e `dim_turma_aluno`, sem mexer no gerador.

Aceitação:
- Uma consulta devolve, para cada coorte e cada semestre, quantos estavam ATIVO, CONCLUIDO e EVADIDO
  naquele ponto do tempo.
- No último semestre da base, as contagens coincidem com as de `dim_aluno` (381 ativos, 433
  concluídos, 619 evadidos).
- Nenhum aluno aparece antes do semestre de ingresso.
- Um teste novo em `06_validacao.sql` confere as duas regras acima.

### R2 — Dimensão de situação da matrícula (P0, resolve L2)

Criar `dim_situacao_matricula` com uma linha por situação e as flags `eh_aprovacao`, `eh_reprovacao`,
`motivo` e `conta_como_resultado`. As consultas passam a filtrar por flag, não por string.

Aceitação:
- Nenhuma consulta em `sql/05_consultas.sql` contém `LIKE 'REPROVADO%'`, `LIKE 'APROVADO%'` ou
  comparação literal com `'TRANCADO_DISCIPLINA'`.
- C1–C12 devolvem resultados idênticos aos de hoje; `validar.py` passa.
- Um teste confere que toda situação presente na fato existe na dimensão.

### R3 — Fechar o período curricular com a consulta C13 (P0, resolve L3)

Nova consulta: quanto as matrículas estão atrasadas em relação à matriz do curso, cruzando
`fato_professor_aluno.periodo_aluno` com `curso_disciplina.periodo_curricular`.

Aceitação:
- C13 em `sql/05_consultas.sql`, com o mesmo padrão de comentário das outras.
- C13 no painel, com cartão, "Como interpretar", tabela e CSV.
- C13 coberta por `validar.py` e exportada para `dashboards/metabase/C13.sql`.
- O texto distingue explicitamente `periodo_aluno` (semestres desde o ingresso) de
  `periodo_curricular` (posição na matriz).

### R4 — Hierarquia navegável e uma operação de roll-up (P1, resolve L5)

Dar variedade real a `campus`, `centro` e `departamento` no gerador, acrescentar área a
`dim_disciplina`, e escrever uma consulta que demonstre roll-up explícito com `GROUP BY ... WITH ROLLUP`.

Aceitação:
- Pelo menos dois campi e dois centros nos dados.
- Uma consulta devolve, na mesma saída, os totais por curso, por centro, por campus e o total geral.
- Os filtros do painel permitem descer de campus a curso.

### R5 — Aplicar o peso da ponte (P1, resolve L6)

C12 passa a usar `vw_turma_professor.peso` em qualquer medida somável por docente, mantendo as taxas
por oferta como estão.

Aceitação:
- Somar a medida ponderada sobre todos os docentes de um semestre dá exatamente
  `SUM(qtd_matriculados)` da fato agregada naquele semestre.
- Um teste novo confere essa igualdade.
- O cartão de C12 explica a diferença entre a contagem exibida por docente e o total do semestre.

### R6 — Corrigir a leitura de C11 (P1, resolve L7 e L8)

C11 passa a reportar, ao lado da duração média, a taxa de conclusão da coorte, e a marcar as coortes
cuja trajetória ainda não terminou. O corte `ano_ingresso >= 2018` sai do SQL e vira atributo de
`dim_turma_aluno`.

Aceitação:
- C11 mostra concluintes sobre ingressantes por coorte.
- Coortes com observação incompleta aparecem marcadas, no SQL e no painel.
- Nenhuma das três consultas tem `2018` escrito no corpo.
- Este é o único requisito autorizado a mudar números já apresentados; a mudança fica registrada em
  `docs/mudancas_esquemas.md`.

### R7 — Linhagem mínima de carga (P1, resolve L10)

Uma tabela de log de carga com data, semente do gerador e contagem por tabela, preenchida por
`carregar.sh`.

Aceitação:
- Depois de uma carga, a tabela traz uma linha por execução, com semente e contagens.
- As contagens conferem com `COUNT(*)` das tabelas.

### R8 — Verificação em MySQL 8 (P1, resolve L11)

Um modo de execução que roda as 12 consultas no MySQL e compara com a linha de base do SQLite.

Aceitação:
- Um comando documentado no README executa C1–C13 no MySQL 8 e reporta divergências.
- Qualquer divergência de semântica encontrada fica registrada em `plan.md`.

### R9 — Quitar a dívida de documentação (P1, resolve L12)

Aceitação:
- `v2_esquema.pdf` regenerado, já com `curso_disciplina` e com o que R1 e R2 acrescentarem.
- `docs/mudancas_esquemas.md` atualizado, mantendo o formato de tabela atual.
- Importador do Metabase reexecutado com as 13 consultas finais, com a versão testada registrada.
- `docs/apresentacao.md` e `dashboards/LEIA-ME.md` alinhados ao esquema novo.

### R10 — Decidir sobre as colunas mortas (P2, resolve L4)

Para cada uma das 14 colunas sem leitor: criar consulta que a use, ou remover, ou documentar como
reservada. A recomendação está em `plan.md`.

Aceitação:
- Toda coluna de `fato_professor_disciplina` é lida por ao menos uma consulta, ou aparece numa lista
  de colunas reservadas com justificativa.

### R11 — Decidir sobre os nomes enganosos (P2, resolve L9)

Renomear as duas fatos e `dim_turma_aluno`, ou manter e documentar. Depende de decisão da equipe:
renomear toca DDL, gerador, 13 consultas, validação, painel, CSVs, Metabase, DBML, dois PDFs e o
roteiro de apresentação.

## 6. Decisões em aberto

Estas quatro precisam da equipe antes das tarefas correspondentes:

1. **Qual é a próxima entrega, e quando?** Esta spec assume que o ciclo atual é de consolidação
   conceitual e fechamento, sem enunciado novo em mãos. Se houver enunciado, ele reordena as
   prioridades e esta seção deve ser reescrita primeiro.
2. **R1: snapshot ou SCD Tipo 2?** O snapshot periódico é mais barato e responde às perguntas atuais;
   o SCD Tipo 2 em `dim_aluno` é o que a bibliografia cobra pelo nome. Comparação em `plan.md`.
3. **R11: renomear agora ou depois da apresentação?** O custo é alto e o ganho é de clareza.
4. **R10: criar consultas para as colunas mortas ou enxugar a fato agregada?** As faixas `qtd_nota_*`
   dão um histograma de notas quase de graça; as 4 colunas de bolsistas agregados e `mediana_notas`
   são mais difíceis de justificar.
