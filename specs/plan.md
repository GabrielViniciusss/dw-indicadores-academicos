# Plan — decisões técnicas do próximo ciclo

Como atender os requisitos de [`spec.md`](spec.md) sem quebrar as invariantes. Ordem de execução em
[`tasks.md`](tasks.md).

## 1. Princípio que orienta as decisões

O projeto hoje tem uma propriedade que vale mais do que qualquer acréscimo: a fato agregada é
derivada da fato individual em SQL, e 16 testes conferem que as duas fecham. Toda estrutura nova deve
nascer derivada do que já existe, em SQL, verificada por teste. Nada de nova população sorteada pelo
gerador quando o dado já está implícito na base.

Isso tem uma consequência prática: a maioria dos requisitos P0 não toca `gerador/gerar_dados.py`, e
portanto não muda um único número já apresentado. A exceção é R4, que precisa de variedade nos dados
de hierarquia, e R6, que muda um indicador de propósito.

## 2. D1 — Historicização: snapshot periódico, não SCD Tipo 2

**Decisão:** criar `fato_vinculo_semestre` como snapshot periódico. Manter `dim_aluno` como está.

**Alternativas consideradas:**

| Opção | O que exige | O que entrega | Custo |
| --- | --- | --- | --- |
| SCD Tipo 2 em `dim_aluno` | `data_inicio`, `data_fim`, `versao_atual`, chave surrogate separada da matrícula, e reescrita de todas as junções com `dim_aluno` | O conceito pelo nome que a bibliografia usa | Alto: toca as 7 consultas que juntam `dim_aluno`, mais painel e validação |
| Snapshot periódico (escolhida) | Uma tabela nova, derivada em SQL | Vínculo por semestre, curvas de retenção, evasão reconstituível | Baixo: nenhuma consulta existente muda |
| SCD Tipo 3 | Colunas "situação anterior" | Uma transição só | Não resolve |

**Justificativa:** o vínculo muda no máximo uma vez por aluno nesta base — ATIVO vira CONCLUIDO ou
EVADIDO, e `id_data_saida` já registra quando. Um SCD Tipo 2 geraria no máximo duas versões por aluno
para guardar a mesma informação que `situacao_vinculo` + `id_data_saida` já guardam, ao custo de
reescrever todas as junções. O snapshot, em troca, entrega o que o Tipo 2 não entrega sozinho: uma
linha por aluno por semestre, que é o que as curvas de retenção e a evasão por período pedem.

Vale dizer isto na apresentação de forma explícita, porque é um argumento de modelagem, não uma
desculpa: a dimensão não precisa versionar o que a fato de snapshot já historiciza.

**Esboço da derivação**, para `sql/07_snapshot_vinculo.sql`:

```sql
INSERT INTO fato_vinculo_semestre
SELECT ROW_NUMBER() OVER (ORDER BY a.id_aluno, d.id_data),
       a.id_aluno, t.id_curso, a.id_turma_aluno, d.id_data,
       CASE WHEN a.id_data_saida IS NULL OR d.id_data < a.id_data_saida
            THEN 'ATIVO' ELSE a.situacao_vinculo END,
       (d.ano * 2 + d.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_data d
  ON d.id_data >= t.ano_ingresso * 10 + t.semestre_ingresso
 AND (a.id_data_saida IS NULL OR d.id_data <= a.id_data_saida);
```

Volume esperado: por volta de 10 a 12 mil linhas, bem abaixo da fato individual.

**Pendência conhecida:** a aritmética `ano * 2 + semestre` aparece aqui e em C11. Ver D6.

## 3. D2 — Dimensão de situação: chave surrogate na fato, texto mantido na transição

**Decisão:** criar `dim_situacao_matricula` com 5 linhas e acrescentar `id_situacao` a
`fato_professor_aluno`, preenchido na carga. `situacao_final` continua na fato durante a transição,
como atributo degenerado, e sai só depois de R9.

```sql
CREATE TABLE dim_situacao_matricula (
  id_situacao TINYINT PRIMARY KEY,
  situacao_final VARCHAR(35) NOT NULL UNIQUE,
  descricao VARCHAR(80),
  eh_aprovacao BOOLEAN NOT NULL,
  eh_reprovacao BOOLEAN NOT NULL,
  motivo VARCHAR(10),                    -- NOTA, FALTA ou NULL
  conta_como_resultado BOOLEAN NOT NULL  -- falso apenas no trancamento
);
```

| id | situacao_final | eh_aprovacao | eh_reprovacao | motivo | conta_como_resultado |
| --- | --- | --- | --- | --- | --- |
| 1 | APROVADO_NOTA | sim | não | NOTA | sim |
| 2 | APROVADO_FINAL | sim | não | NOTA | sim |
| 3 | REPROVADO_NOTA | não | sim | NOTA | sim |
| 4 | REPROVADO_FALTAS | não | sim | FALTA | sim |
| 5 | TRANCADO_DISCIPLINA | não | não | — | não |

**Por que surrogate e não junção por string:** junção por string funcionaria e seria mais barata, mas
perderia exatamente a demonstração que interessa — chave surrogate ligando fato e dimensão. Como a
dimensão tem 5 linhas, o custo é nulo.

**Por que manter `situacao_final` na transição:** os CSVs em `dados/csv/`, o painel e os SQLs do
Metabase leem essa coluna. Removê-la no mesmo passo em que se cria a dimensão transforma um
requisito verificável em uma refatoração ampla. Primeiro a dimensão passa a existir e as consultas
passam a usá-la; depois a coluna sai.

**Ganho concreto:** `conta_como_resultado` substitui `situacao_final <> 'TRANCADO_DISCIPLINA'` em C3,
C4, C5 e C8, e `eh_reprovacao` substitui `LIKE 'REPROVADO%'`. A regra passa a existir em um lugar só.

## 4. D3 — C13: usar o que já está no banco

`curso_disciplina.periodo_curricular` está preenchido pelo gerador com a mesma matriz que define as
disciplinas de cada aluno, e validado por teste. Não falta dado; falta consulta.

```sql
-- C13. Quanto as matriculas estao atrasadas em relacao a matriz curricular do curso?
SELECT c.codigo_curso, d.ano_semestre, m.periodo_curricular,
       COUNT(*) AS matriculas,
       ROUND(AVG(f.periodo_aluno - m.periodo_curricular), 1) AS atraso_medio,
       ROUND(100 * SUM(f.periodo_aluno > m.periodo_curricular) / COUNT(*), 1) AS pct_atrasadas
FROM fato_professor_aluno f
JOIN curso_disciplina m ON m.id_curso = f.id_curso AND m.id_disciplina = f.id_disciplina
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, d.ano_semestre, m.periodo_curricular;
```

**Gráfico sugerido:** mapa de calor de período curricular por semestre, com a cor no atraso médio.
Mantém o padrão das outras: a escolha do gráfico é justificada pela natureza ordinal dos dois eixos.

**Cuidado de leitura que precisa estar no cartão:** atraso aqui é diferença entre o período do aluno e
o período previsto da disciplina. Um aluno adiantado produz valor negativo, e reprovação acumulada
empurra o indicador para cima sem que a disciplina seja a causa.

## 5. D4 — Hierarquia: mexer no gerador é inevitável

É o único requisito P0/P1 que muda dados já apresentados. Duas opções:

| Opção | Efeito |
| --- | --- |
| Dar campus e centro variados aos 3 cursos atuais | Hierarquia navegável com 3 folhas; nenhum número de desempenho muda, porque curso e disciplina continuam iguais |
| Acrescentar cursos de outros centros | Hierarquia mais realista, mas muda toda a volumetria e invalida os números do PDF entregue |

**Decisão:** a primeira. Atribuir `campus` e `centro` distintos aos cursos existentes e acrescentar
`area` a `dim_disciplina` derivada do prefixo do código (`MAT`, `CMP`, `FIS`, `ELE`, `EST`, `ADM`,
`HUM`, `TCC`). O prefixo já existe no currículo do gerador, então a área sai de graça e dá uma
segunda hierarquia para drill-down, independente do curso.

Nenhuma taxa muda, porque nada disso entra no cálculo de nota, falta ou situação. O que muda é a
rotulagem de 3 linhas de `dim_curso` e uma coluna nova em `dim_disciplina`.

**Roll-up explícito** fica numa consulta própria, para a operação OLAP ficar visível:

```sql
SELECT COALESCE(c.campus, 'TODOS') AS campus,
       COALESCE(c.centro, 'TODOS') AS centro,
       COALESCE(c.codigo_curso, 'TODOS') AS curso,
       SUM(f.qtd_matriculados - f.qtd_trancamentos) AS matriculas,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_reprovacao
FROM fato_professor_disciplina f
JOIN dim_curso c ON c.id_curso = f.id_curso
GROUP BY c.campus, c.centro, c.codigo_curso WITH ROLLUP;
```

Note que a taxa é recalculada em cada nível a partir de numerador e denominador, e não é média de
médias. Esse é o ponto a destacar na apresentação.

## 6. D5 — Peso da ponte em C12

C12 hoje devolve uma linha por oferta × docente, com `SUM(qtd_matriculados)` integral em cada linha.
Isso está certo para ler a oferta e errado para somar docentes, e o `LEIA-ME.md` já avisa.

**Decisão:** manter as medidas por oferta como estão e acrescentar uma coluna ponderada,
`matriculas_atribuidas = SUM(qtd_matriculados * tp.peso)`, explicitamente rotulada como a medida
somável. Duas colunas, dois usos, nenhuma ambiguidade.

**Alternativa rejeitada:** substituir a contagem integral pela ponderada. Tornaria a leitura por
oferta estranha — uma turma de 40 alunos com dois docentes apareceria com 20 para cada, o que não
descreve a turma que cada um deu.

## 7. D6 — `dim_data` precisa de um índice sequencial de semestre

Problema transversal, descoberto ao escrever D1: a aritmética `ano * 2 + semestre` aparece em C11,
reaparece no snapshot de D1, e `ano * 10 + semestre` aparece em `06_validacao.sql`. São três lugares
reconstruindo, na consulta, uma informação que pertence à dimensão.

**Decisão:** acrescentar `indice_semestre` a `dim_data`, sequencial a partir do primeiro semestre da
base, preenchido pelo gerador. C11, o snapshot e a validação passam a subtrair índices.

**Ganho além da limpeza:** `ano * 2 + semestre` presume exatamente dois semestres por ano. Um semestre
de verão quebraria a conta em silêncio; o índice sequencial não quebra.

`id_data = ano * 10 + semestre` continua como está. É uma chave inteligente, o que a bibliografia
desaconselha, mas trocá-la por surrogate pura tocaria todas as tabelas e CSVs para ganhar pouco nesta
escala. Fica registrado como escolha consciente, não como descuido — e é um bom item para responder
se a banca perguntar.

## 8. D7 — Colunas mortas: usar as baratas, remover as caras

Recomendação para R10, para a equipe decidir:

| Colunas | Recomendação | Motivo |
| --- | --- | --- |
| `qtd_nota_0_2_9` a `qtd_nota_9_10` (5) | Usar: histograma de distribuição de notas por disciplina | Já estão calculadas e validadas; um gráfico de barras empilhadas resolve, e distribuição de notas é pergunta legítima de coordenação |
| `menor_notas`, `maior_notas` | Usar no mesmo cartão, como amplitude | Custo zero |
| `media_notas`, `media_faltas` | Remover | São razões prontas, redundantes com `soma_notas_finais / qtd_notas_validas` e `soma_faltas / qtd_faltas_validas`, que é o que C9 e C12 já usam. Guardar razão em fato agregada é justamente o que a boa prática evita |
| `mediana_notas` | Remover, ou manter documentada como não reagregável | É irrecuperável em qualquer roll-up, e o próprio DBML já anota isso. Se ficar, precisa de uma consulta que a use no grão exato da oferta |
| `qtd_bolsistas_*` (4) | Decidir | Permitiriam uma versão agregada de C3, mais rápida. Mas no gerador o benefício não influencia o resultado, então a consulta não mostraria nada novo |

Remover coluna de fato agregada é seguro aqui: ela é recriada por inteiro a cada carga.

## 9. D8 — Linhagem: tabela de log, não coluna em cada fato

**Decisão:** uma tabela `log_carga` com uma linha por execução — data e hora, semente, nome da tabela
e contagem. Preenchida ao fim de `carregar.sh`.

**Alternativa rejeitada:** coluna `carregado_em` em cada fato. Numa carga de recriação total, o valor
seria idêntico em todas as 31 mil linhas. A tabela de log diz a mesma coisa sem o desperdício, e
guarda a semente, que é o que de fato identifica a versão dos dados neste projeto.

## 10. D9 — Verificação em MySQL

`validar.py` compara o painel com as consultas em SQLite. É uma prova de consistência de cálculo, não
de equivalência no MySQL 8. A substituição `replace('100 *', '100.0 *')` é a evidência: o SQLite faria
divisão inteira onde o MySQL não faz.

**Decisão:** não substituir o SQLite. Acrescentar um script separado que roda C1–C13 no MySQL, grava
os resultados e compara com a execução em SQLite, reportando divergência por consulta e coluna. Os
dois níveis passam a conviver: SQLite verifica o painel sem precisar de banco, MySQL verifica o SQL
que será apresentado.

**Divergências esperadas e que devem ser conferidas, não presumidas:** divisão inteira, `SUM` sobre
expressão booleana, ordenação de `NULL`, e arredondamento de `ROUND` em valor com meio exato.

## 11. Riscos

| Risco | Mitigação |
| --- | --- |
| R6 muda números já apresentados em C11 | Registrar em `docs/mudancas_esquemas.md` e dizer na apresentação que a correção é deliberada e por quê. A média antiga continua na saída, ao lado da taxa de conclusão |
| D4 muda `dim_curso` e `dim_disciplina`, e o painel embute os CSVs | A sequência de `tasks.md` reconstrói painel, CSVs e Metabase na mesma tarefa, nunca em tarefas separadas |
| R11, se aprovado, toca tudo de uma vez | Fazer por último, depois da apresentação, em commit único e com `validar.py` como rede |
| A spec supõe o próximo enunciado | Confirmar com a equipe antes de T1. Se houver enunciado, reescrever a seção 4 de `spec.md` primeiro |
| Crescimento de escopo | As 13 consultas são o teto. Nenhum requisito aqui autoriza uma 14ª além de C13 e das duas consultas de demonstração OLAP |

## 12. O que deliberadamente não entra

- Trocar o SGBD, ou usar recurso que o MySQL 8 não tenha.
- Substituir o painel HTML por ferramenta nativa. O HTML é o protótipo verificado; o Metabase é a
  demonstração de ferramenta de BI e continua nesse papel.
- Índices secundários além dos que o MySQL cria para chave estrangeira. Com 31 mil linhas na maior
  fato, não há ganho mensurável, e inventar índice sem medição é pior do que não ter. Se a disciplina
  cobrar o assunto, a resposta honesta é uma medição de plano de execução, e isso é tarefa própria.
- Carga incremental. A recriação total roda em segundos nesta escala. O que falta é linhagem (D8),
  não incrementalidade.
- Sexo e faixa etária, mantendo a decisão de privacidade das entregas anteriores.
