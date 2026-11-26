# Planejamento — próximo ciclo do DW de indicadores acadêmicos

Disciplina de Data Warehouse, UFPE. Escrito em 21/11/2026, depois das entregas de 03/11 (esquemas) e
05/11 (visualização), e da curadoria de observatórios de dados e DWs de referência.

**Equipe:** jlsm2, jvcn, gflb, gvab, lmq2, mffa, thrb

Documentos irmãos: [`spec.md`](spec.md) (requisitos e critérios de aceitação), [`plan.md`](plan.md)
(decisões técnicas), [`tasks.md`](tasks.md) (tarefas ordenadas). Este arquivo é a visão de conjunto e
a divisão de trabalho.

---

## 1. Onde estamos

O que está pronto e funcionando: duas estrelas com dimensões compartilhadas, 12 consultas analíticas,
16 testes de consistência com zero erros, painel interativo em quatro páginas, Looker Studio,
configuração de Metabase, e um gerador de dados sintéticos com semente fixa.

O que mudou nesta branch (`calibracao-taxas`):

| Commit | Conteúdo |
| --- | --- |
| `b283c32` | `specs/` — o SDD: 13 lacunas com evidência, 11 requisitos, 9 decisões, 24 tarefas |
| `60d6269` | Correção do gerador (seção 4 deste documento) + `gerador/calibrar.py` + SQL regerado |

**Propagação concluída em 23/11/2026 (F1 feito):** `dados/csv/` e o painel HTML foram regerados a
partir do dado novo e agora batem com `sql/02_dados_sinteticos.sql`. Os SQLs em
`dashboards/metabase/` não continham dado nenhum — são só as consultas, e ficaram idênticos. O que
ainda carrega número velho é o `docs/entrega_05_11.pdf`, que é binário e precisa ser refeito (F5).

---

## 2. O alvo é o roteiro do professor

O relatório pedido tem seis seções. Elas são o critério de pronto deste ciclo:

| Seção do roteiro | Nosso estado hoje | Frente |
| --- | --- | --- |
| **1) Contexto e objetivo, perguntas de negócio** | Pronto. As 12 consultas já estão em ordem de prioridade com "para que serve" | — |
| **2) Fatos: medidas por tipo de aditividade** | **Lacuna.** Nunca classificamos. Classificação inicial na seção 5.3 abaixo | F4 |
| **3) Dimensões: campo a campo, valores especiais e SCD** | **Lacuna maior.** Hoje a resposta é "nenhuma dimensão tem SCD" nas sete | F3, F4 |
| **4) Técnicas de projeto de cada estrela** | Temos várias e nunca nomeamos. Lista na seção 5.4 | F4 |
| **5) Consultas SQL explicadas** | 12 prontas, 5 candidatas novas identificadas | F2, F3 |
| **6) Gráficos a partir das consultas** | Painel pronto para as 12; falta para as novas | F5 |

Observação que orienta tudo: as seções 2, 3 e 4 **não dependem de código novo**. Podem começar hoje.

---

## 3. O que achamos de relevante

### 3.1 Observatórios de dados

| Fonte | O que rendeu |
| --- | --- |
| **UFPB — Metabase "Indicadores Graduação"** (STI / Gerência de Inteligência Institucional) | **O modelo e as definições.** Fato de vínculo discente × `dim_periodo` × `dim_curso` × `dim_discente`, 9 filtros conformados, `codigo_inep` como chave de negócio externa, e 6 indicadores definidos por escrito no próprio painel. **Não rende consultas boas:** os 12 gráficos são a mesma consulta, `COUNT(*) GROUP BY ano, periodo`, sem denominador. E tem armadilha não declarada: "Matriculados" é `COUNT DISTINCT` por período, então somar os períodos de um ano conta o mesmo aluno duas vezes — medida semi-aditiva apresentada como aditiva |
| **UFRPE — Relatório Analítico sobre Controle de Evasão e Retenção** (Observatório de Dados da Graduação / PREG, 2021) | **Três fórmulas com literatura**, mais duas práticas de gráfico: benchmark nacional como elemento visual, e os três fluxos (ingressantes, formados, desvinculados) no mesmo gráfico para auditar o balanço. E um defeito a evitar: curso novo com indicador indefinido impresso como `00,00%` em vez de vazio |
| **INEP / DEED** (metodologia 2017, via paper do COBENGE 2022) | **O melhor achado: TAP, TCA e TDA**, com a identidade `TAP + TCA + TDA = 100%` em todo ano `t` |
| **UFPR — Observatório de Evasão e Baixa Procura** | Precedente de governança: painel público só com agregado, e a calculadora de risco por aluno **restrita**, dentro do SIGA |
| **UFAC — Painéis Estratégicos** | O indicador "ocupação de vagas", que não temos |

**As fórmulas, para não perdermos:**

```
INEP/DEED, para a coorte que ingressou em T, a cada ano t:
  TAP(T,t) = (Cursando + Matrícula trancada)        / (Ingressantes − Falecidos) × 100
  TCA(T,t) = Σ Formados                             / (Ingressantes − Falecidos) × 100
  TDA(T,t) = (Σ Desvinculados + Σ Transferidos)     / (Ingressantes − Falecidos) × 100
  e TAP + TCA + TDA = 100% sempre.

Instituto Lobo (Silva Filho & Lobo, 2011), evasão anual:
  EV(n) = 1 − (M(n) − I(n)) / (M(n−1) − C(n−1))
  M = matrículas, I = ingressantes, C = concluintes.

Taxa de Sucesso na Graduação (TSG), usada na matriz orçamentária e no TCU:
  TSG(n) = C(n) / I(n − dp)        dp = duração padrão do curso
```

A frase do relatório da UFRPE que explica por que o método do Lobo existe: *"a análise de corte,
acompanhando a trajetória acadêmica de cada estudante é a forma mais precisa de aferir este fenômeno.
Apesar disso, este tipo de análise requer a identificação de cada estudante, o que nem sempre é
possível."* **Nós temos o dado de coorte.** Isso abre uma consulta que nenhuma das fontes pode fazer:
comparar a fórmula agregada com a análise de coorte e medir o quanto ela erra.

### 3.2 DWs de referência

O que se aproveita deles é método, não consulta:

- **TPC-DS**, 99 consultas: cada uma vem documentada com a pergunta de negócio que responde. É o
  padrão que nosso PDF de entrega já segue. E o modelo de vendas **mais devoluções** são dois fatos
  que precisam reconciliar — estruturalmente o que nossas duas estrelas fazem.
- **Star Schema Benchmark** (O'Neil et al., UMass Boston): reescreveu o TPC-H como estrela pura
  citando Kimball. 13 consultas em *flights*: a mesma pergunta com seletividade progressiva.
- **TPC-H**, 22 consultas: contraexemplo útil, criticado justamente por não seguir Kimball.
- **CEDS Data Warehouse** (Common Education Data Standards): modelo educacional padronizado e
  **longitudinal por construção** — a referência mais próxima do nosso domínio, e exatamente o que
  nos falta.
- **badri-2005/Student-Educational-Warehouse**: DW acadêmico em MySQL 8, fatos em grão
  aluno-disciplina e aluno-semestre, com **SCD Tipo 2 em `dim_student`**. Precedente direto: projeto
  comparável que historiza, e nós não.

### 3.3 O critério de "consulta boa"

Comparando as duas classes de fonte, sai o critério que o professor pediu sem nomear. Uma consulta é
boa quando:

1. Tem **denominador** — é taxa ou comparação, não contagem bruta.
2. O denominador é a **população certa** (a defasagem `dp` da TSG; "quem estava em risco" na evasão).
3. **Exige estrutura**: o modelo precisa ter algo específico para ela existir.
4. Tem **referência** contra a qual comparar (prazo, histórico, benchmark, outro grupo).
5. A **aditividade está declarada**.
6. O **gráfico decorre da forma do dado**, não do hábito.

O critério 3 é o que amarra com o roteiro: consulta boa é a que obriga o modelo a ter uma medida de
aditividade específica, uma dimensão historizada, ou um atributo como `dp`. É por isso que, nas
palavras do professor, não basta ter consultas — precisam ser boas.

---

## 4. O que corrigimos

**O defeito.** O gerador usava uma única `CARGA_SEMESTRAL = (3, 4, 4, 5, 5)` para três cursos com
matrizes e prazos diferentes, e nunca conferia isso contra `semestres_previstos`:

| Curso | Matriz | Prazo previsto | Exigido por semestre | Carga antiga |
| --- | ---: | ---: | ---: | ---: |
| CC | 34 | 9 | 3,8 | 4,2 |
| EC | 41 | 10 | 4,1 | 4,2 |
| SI | 29 | 8 | 3,6 | 4,2 |

Consequências medidas:

1. O "% de concluintes no prazo" espalhava **41,1 pontos** entre cursos — SI 49,9%, EC 8,8%. Não vinha
   da dificuldade simulada, vinha de matriz ÷ carga.
2. Nenhum aluno de EC podia se formar adiantado: o tempo mínimo era 10, igual ao próprio prazo.
3. **A C11 é a consulta que compara tempo de conclusão com o prazo previsto** — aquela para a qual
   criamos `semestres_previstos`. Ela estava reportando essa aritmética.
4. Não havia prazo máximo: quem acumulava reprovação ficava `ATIVO` para sempre, 41 alunos estavam
   além do prazo previsto sem saída, e nenhuma coorte antiga fechava.

**A correção**, só no gerador, sem alterar o esquema: carga derivada por curso de
`matriz / prazo_previsto`, e prazo máximo de integralização em 1,5× o prazo — que é o motivo
"ultrapassou prazo máximo" das normas de permanência e está na lista de desvinculação do INEP.

**Resultado**, medido com 8 sementes pela mesma métrica nos dois lados:

| | Antes | Depois |
| --- | ---: | ---: |
| Espalhamento "no prazo" entre cursos | 41,1 pontos | **4,0 pontos** |
| Espalhamento mediana/prazo entre cursos | 0,12 | **0,03** |
| Mediana ÷ prazo, por curso | 1,10 / 1,20 / 1,08 | **1,19 / 1,21 / 1,18** |
| TAP em coorte fechada | 2,5% | **0,0%** |
| `TAP + TCA + TDA = 100%` por coorte | não fechava | **fecha** |

**O ganho que importa:** a identidade do INEP passar a valer não é detalhe. Ela é a pré-condição para
TAP/TCA/TDA serem calculáveis, e vira o 17º teste de validação. O conserto no gerador é a base do
melhor indicador que a curadoria achou.

**Efeito colateral deliberado:** desistência acumulada subiu de ~53% para 64%, conclusão caiu de ~44%
para 36% — ambas dentro da faixa publicada para cursos de computação em federais, mas mudaram.
Volumetria: 1.433 → 1.444 alunos, 875 → 848 turmas, 30.992 → **29.474** matrículas. **Todo número do
`docs/entrega_05_11.pdf` e do roteiro de apresentação fica desatualizado nesta branch.**

**Pendência que não maquiamos:** o "% no prazo" ficou em 4–8% nos três cursos, porque com carga igual a
matriz/prazo formar-se no prazo exige quase nenhuma reprovação e o gerador não modela **sobrecarga de
recuperação** — alunos reais pegam disciplinas extras para recuperar atraso. Subir a carga esconderia
isso com outra constante inventada. Ver frente F6.

### 4.1 O que mudou e o que não quebrou, medido

Medido em 23/11/2026 carregando as duas populações em paralelo no mesmo MySQL 8 (`dw_antigo`, a de
05/11, e `dw_academico`, a corrigida) e rodando as mesmas 12 consultas nas duas.

**O que não mudou: a estrutura inteira.** `git diff 60d6269^ HEAD` é vazio em `sql/01_ddl.sql`,
`sql/03_carga_fato_agregada.sql`, `sql/04_views.sql`, `sql/05_consultas.sql`, `sql/06_validacao.sql`
e `dashboards/painel.js`. O commit tocou só o gerador, o `calibrar.py` e o SQL de dados. Esquema,
consultas, testes e cálculos do painel são os mesmos da entrega, e continuam passando: 16 testes com
zero erros e `validar.py` conferindo C1–C12.

**O que mudou nos agregados** — pouco, o discurso da entrega sobrevive:

| Indicador, sobre toda a base | Antes | Depois | Δ |
| --- | ---: | ---: | ---: |
| Taxa de aprovação | 76,16% | 77,40% | +1,2 |
| Taxa de reprovação | 23,84% | 22,60% | −1,2 |
| Taxa de trancamento | 4,04% | 3,99% | −0,1 |
| Nota média | 6,29 | 6,36 | +0,07 |
| Evasão, vínculo final | 43,20% | 45,71% | +2,5 |
| Conclusão | 30,22% | 25,76% | −4,5 |
| Ativos | 26,59% | 28,53% | +1,9 |
| **TAP em coortes de 2018 ou antes** | **1,01%** | **0,00%** | **−1,0** |

A última linha é a correção, não um efeito colateral: coorte fechada com aluno ativo é o que impedia
`TAP + TCA + TDA = 100%`. Atenção à base: estes números são sobre a base inteira, incluindo coortes
recentes ainda em curso. Os ~53% → 64% de desistência citados acima são a métrica do `calibrar.py`,
com censura de coorte — bases diferentes, não números conflitantes.

**O que mudou linha a linha** — muito, e é aqui que o PDF fica inservível:

| Consulta | Linhas antes | Depois | Chaves só antes | Só depois | Maior variação numa célula |
| --- | ---: | ---: | ---: | ---: | --- |
| C1 | 480 | 480 | 6 | 15 | reprovação por nota, 38,6 pontos |
| C2 | 48 | 48 | 0 | 0 | evadidos, 20 alunos |
| C3 | 96 | 96 | 0 | 0 | matrículas, 45 |
| C4 | 630 | 607 | 0 | 0 | reprovação por nota, 22 pontos |
| C5 | 104 | 104 | 0 | 0 | alunos, 56 |
| C6 | 655 | 616 | 4 | 1 | taxa de aprovação, 100 pontos |
| C7 | 368 | 352 | 2 | 1 | aprovado final, 30 pontos |
| C8 | 581 | 581 | 0 | 0 | taxa de evasão, 100 pontos |
| C9 | 2.211 | 2.140 | 9 | 0 | taxa de reprovação, 100 pontos |
| C10 | 1.566 | 1.516 | 0 | 2 | diferença em pontos, 41,2 |
| C11 | 24 | 23 | 0 | 0 | média de semestres, 2,0 |
| C12 | 1.126 | 1.051 | 7 | 0 | taxa de aprovação, 100 pontos |

Como ler: as variações de 100 pontos são células de denominador minúsculo — oferta com um punhado de
matrículas, onde um aluno vira a taxa inteira. As colunas "chaves só antes/só depois" são ofertas,
turmas ou pares que deixaram de existir ou passaram a existir, porque as turmas caíram de 875 para
848. **Consequência prática:** nenhuma frase do PDF ou do roteiro que cite um número específico de
uma disciplina, turma ou semestre continua válida; as afirmações sobre o nível geral continuam.

**Isso contradiz o invariante 3 da `spec.md`**, que exigia C1–C12 idênticas linha a linha. O
invariante foi reescrito para dizer a verdade: ele vale para a mesma população, e a correção do
gerador é a exceção já consumada, de dado e não de consulta.

---

## 5. As consultas: o que temos e o que falta

### 5.1 As 12 atuais

Passam no critério 1: são todas taxas, com numerador e denominador guardados separados, o que é
genuinamente melhor que o painel da UFPB. Mas **nenhuma é um indicador institucional reconhecido** —
nenhuma tem nome, fórmula e fonte na literatura.

### 5.2 As 5 candidatas

| Consulta | Por que interessa ao negócio | Gráfico e por quê | Exige | Dá hoje? |
| --- | --- | --- | --- | --- |
| **TAP/TCA/TDA** por coorte × ano | É o indicador oficial do INEP pelo qual a instituição é medida | Área empilhada em 100% ao longo de `t`: as três séries são exclusivas e somam 100%, então é a única forma que mostra composição e evolução sem sugerir que o total mudou | Snapshot de vínculo (R1) | Não |
| **TSG** por curso × ano | Alimenta a matriz orçamentária e o relatório do TCU. É dinheiro, não só indicador acadêmico | Linha por ano com faixa de referência: o valor não significa nada sozinho | `semestres_previstos` (temos) | **Sim** |
| **Evasão Lobo × análise de coorte** | A fórmula agregada é a que vai para fora; saber o quanto ela erra é informação que nenhuma das fontes tem | Duas linhas no mesmo eixo com a diferença sombreada — a diferença *é* o achado | Snapshot (R1) | Não |
| **Atraso curricular (C13)** | O professor pediu para considerar o período curricular | Mapa de calor período curricular × semestre, cor no atraso médio: dois eixos ordinais | `periodo_curricular` (temos, sem leitor) | **Sim** |
| **Ocupação de vagas** | Fecha o conjunto dos observatórios (UFAC) | Barra contra capacidade | Coluna `vagas` em `dim_curso` | Quase |

**Atenção na TSG:** é razão **não aditiva entre cursos**, porque cada curso tem `dp` diferente e
portanto um ano-denominador diferente. Média de TSG entre cursos é erro. Tem que somar `C(n)` e somar
`I(n − dp)` separadamente — que é justamente a prática que nosso projeto já segue.

### 5.3 Classificação de aditividade (insumo da seção 2 do roteiro)

Classificação inicial, a revisar na frente F4:

| Medida | Tipo | Observação |
| --- | --- | --- |
| `quantidade_faltas`, `ch_adquirida` | Aditiva | |
| `qtd_matriculados`, `qtd_aprovacoes_*`, `qtd_reprovacoes_*`, `qtd_trancamentos` | Aditivas | Fecham: matriculados = soma das cinco situações |
| `qtd_nota_0_2_9` … `qtd_nota_9_10` | Aditivas | Fecham com `qtd_notas_validas` |
| `qtd_bolsistas_*` | Aditivas | |
| `soma_notas_finais`, `soma_faltas`, `qtd_notas_validas`, `qtd_faltas_validas` | Aditivas | São o numerador e o denominador que tornam as médias reagregáveis |
| `nota_final` | Não aditiva | Valor por matrícula; somar notas não significa nada |
| `media_notas`, `media_faltas` | **Não aditivas** | Razões prontas. Redundantes com as somas acima, e é delas que C9 e C12 já calculam |
| `mediana_notas` | **Não aditiva e não recuperável** | A mediana geral não vem da mediana das medianas, em nenhuma reagregação |
| `menor_notas`, `maior_notas` | Não aditivas, mas reagregáveis | Reagregam com MIN e MAX, nunca com SUM |
| `qtd_tentativas`, `periodo_aluno` | Não aditivas | São atributos no fato (dimensão degenerada), não medidas |
| `bolsista_no_semestre` | Não aditiva | Sinalizador |

Daí sai um achado para o relatório: **14 das 28 colunas da fato agregada não são lidas por consulta
alguma** — as 5 faixas de nota, as 4 de bolsistas, mínimo, máximo, mediana e as duas médias. As faixas
dão um histograma de distribuição de notas quase de graça; as médias devem sair.

### 5.4 Técnicas de projeto (insumo da seção 4 do roteiro)

Usamos e nunca nomeamos:

| Técnica | Onde |
| --- | --- |
| Dimensões conformes | `dim_data`, `dim_curso`, `dim_disciplina`, `dim_professor`, `dim_turma_disciplina`, compartilhadas pelas duas estrelas |
| Dimensão com papéis (*role-playing*) | `dim_professor` nos três papéis de `dim_turma_disciplina` |
| Tabela de ponte com fator de alocação | View `vw_turma_professor`, com `peso = 1/n` |
| Fato agregada derivada | `fato_professor_disciplina`, obtida da fato individual em SQL, com testes de reconciliação |
| Dimensão degenerada | `periodo_aluno` e `qtd_tentativas` dentro do fato |
| Chave inteligente (escolha consciente) | `id_data = ano × 10 + semestre`. A bibliografia desaconselha; mantivemos e declaramos |
| Tabela de cobertura | `curso_disciplina`, a matriz curricular |
| **Ausente: nenhum SCD** | As sete dimensões são Tipo 1. A resposta planejada é o snapshot periódico (R1), não o Tipo 2 — justificativa em `plan.md`, decisão D1 |

---

## 6. O plano, em frentes

Seis frentes. Cada uma tem um dono a definir, o que a bloqueia, e como se sabe que acabou.

### F1 — Propagar a correção no banco · FEITO em 23/11/2026 · não bloqueia mais nada

O gargalo era a senha do MySQL da máquina, que usa `auth_socket` e exige `sudo`. Resolvido sem ela,
com um MySQL 8 em contêiner isolado — o mesmo recurso que `dashboards/metabase/compose.yaml` já usa:

```bash
docker run -d --name dw-f1-mysql -e MYSQL_ROOT_PASSWORD=<senha> \
  -p 127.0.0.1:3310:3306 mysql:8.0
export MYSQL_PWD=<senha>                                   # evita a senha no comando
./scripts/carregar.sh      -h127.0.0.1 -P3310 --protocol=TCP -uroot
python3 scripts/exportar_csv.py -h127.0.0.1 -P3310 --protocol=TCP -uroot
python3 dashboards/build_demo.py
python3 dashboards/validar.py
docker rm -f dw-f1-mysql                                   # o contêiner é descartável
```

Como os scripts repassam os argumentos direto ao cliente `mysql`, apontar para outra porta não exigiu
mudar uma linha de código. Resultado:

| Verificação | Resultado |
| --- | --- |
| `gerador/gerar_dados.py` reexecutado | Reproduz o SQL commitado byte a byte (semente fixa confirmada) |
| 16 testes de `06_validacao.sql` | Zero erros, todos |
| `dashboards/validar.py` | Passa; C1–C12 conferem, de 23 a 2.140 linhas por consulta |
| `sql/05_consultas.sql` no MySQL 8 | As 12 executam sem erro no dado novo |
| `TAP + TCA + TDA = 100%` por coorte fechada | Confere em todas, com `TAP = 0,0%` — agora medido no banco, não só em memória |
| Volumetria propagada | 1.444 alunos, 848 turmas, 29.474 matrículas, 2.140 ofertas, 1.051 linhas de ponte |

Arquivos que mudaram: os cinco CSVs com dado (`dim_aluno`, `dim_turma_disciplina`,
`fato_professor_aluno`, `fato_professor_disciplina`, `vw_turma_professor`) e
`dashboards/painel_academico_interativo.html`.

Dívida de número que isso expôs e já foi quitada no mesmo passo: a volumetria da linha de base em
`spec.md`, os critérios de aceitação de R1 e T1.4 (eram 381/433/619, hoje **412 ativos, 372
concluídos, 660 evadidos**), `dashboards/dados_sinteticos/README.md` e `docs/apresentacao.md`.

### F2 — Duas consultas novas, sem tocar no esquema · depende de F1

TSG e C13 (atraso curricular). Para cada uma: SQL em `sql/05_consultas.sql` no padrão de comentário
das outras, cartão no painel com "Como interpretar", cobertura em `dashboards/validar.py`, e
exportação para `dashboards/metabase/`.

Pronto quando: `validar.py` cobre as duas e `periodo_curricular` deixa de ter zero leitores.

### F3 — Snapshot de vínculo e os indicadores do INEP · depende de F1 · maior ganho

A tabela `fato_vinculo_semestre` (uma linha por aluno × semestre), derivada em SQL de `dim_aluno` e
`dim_turma_aluno` — esboço em `plan.md`, decisão D1. Em cima dela, TAP/TCA/TDA e a comparação
Lobo × coorte.

Pronto quando: o 17º teste confere `TAP + TCA + TDA = 100%` por coorte e ano, e as contagens do último
semestre coincidem com `dim_aluno`.

### F4 — Seções 2, 3 e 4 do relatório · SEM DEPENDÊNCIA, começa já

A classificação de aditividade (5.3) e a lista de técnicas (5.4) acima são o rascunho. Falta:
revisá-las, descrever campo a campo as sete dimensões com valores especiais, e escrever a
justificativa de por que não há SCD e por que o snapshot é a resposta.

Pronto quando: as três seções estão escritas e toda coluna do `01_ddl.sql` aparece em alguma delas.

### F5 — Gráficos das consultas novas · depende de F2 e F3

Quatro cartões novos no painel, cada um com justificativa de escolha de gráfico no padrão do PDF.
Atenção ao denominador zero: continua aparecendo como ausência de valor, nunca como zero — é o defeito
que encontramos no relatório da UFRPE.

### F6 — Pendências de dados · opcional, depois da apresentação

Sobrecarga de recuperação no gerador (a pendência da seção 4), coluna `vagas` para ocupação de vagas,
e variedade real em `campus`/`centro` para permitir *drill-down* — hoje os três cursos têm o mesmo
centro e o mesmo campus, então roll-up e drill-down não são demonstráveis.

---

## 7. Ordem e paralelismo

```
agora          F4 (seções 2,3,4 do relatório)  ─────────────────────────┐
                                                                        │
F1 (banco) ──┬── F2 (TSG, C13) ──┐                                      │
             │                   ├── F5 (gráficos) ── revisão final ────┴── entrega
             └── F3 (snapshot) ──┘
                                     F6 (opcional, depois)
```

**F1 está feito**, então o gargalo acabou: F2, F3 e F4 podem correr em paralelo desde já, cada uma com
um dono diferente, e só F5 espera (F2 e F3). Quem pegar F2 ou F3 precisa de um MySQL 8 — o contêiner
descartável da seção F1 resolve, não é preciso ter senha de banco na máquina.

---

## 8. Decisões que a equipe precisa tomar

1. **Qual é a próxima entrega, e quando?** Este planejamento supõe ciclo de consolidação e
   fechamento. Se houver enunciado novo, ele reordena as frentes e esta seção vira a primeira tarefa.
2. **A ressalva sobre os dados muda.** Hoje o README, o PDF e o roteiro dizem que nenhum número
   descreve a UFPE. Se calibrarmos contra taxas reais publicadas, isso deixa de ser verdade: passa a
   ser "calibrado para reproduzir taxas agregadas publicadas, sem nenhum dado individual real". É uma
   afirmação mais forte e honesta, mas é outra, e os três documentos precisam ser atualizados juntos.
3. **Os números da entrega de 05/11 mudaram.** Decidir se a apresentação usa os dados novos (e o PDF é
   refeito) ou se a branch só é integrada depois de apresentar.
4. **As 14 colunas mortas:** criar o histograma de notas que usa as faixas, ou enxugar a fato agregada?
5. **Renomear o que engana** (`fato_professor_aluno` não tem professor; `dim_turma_aluno` é coorte)?
   Recomendação: depois da apresentação — toca DDL, gerador, consultas, painel, CSVs, Metabase, DBML e
   dois PDFs.
6. **Modelos preditivos:** se formos nessa direção, o precedente da UFPR é o a seguir — agregado
   público, risco por aluno restrito. Nada de risco individual em painel público.

---

## 9. Fontes

- INEP/DEED, *Metodologia de cálculo dos indicadores de trajetória* (2017) — fórmulas de TAP, TCA e TDA
- Bogni et al., *Algoritmos para os indicadores de fluxo de alunos para avaliar a evasão dos cursos*,
  COBENGE 2022, DOI 10.37702/2175-957X.COBENGE.2022.3955 — reproduz as fórmulas do INEP
- UFRPE/PREG, *Relatório Analítico sobre Controle de Evasão e de Retenção na UFRPE* (2021) —
  Observatório de Dados da Graduação; fórmulas do Instituto Lobo, TSG e FORPLAD
- Silva Filho & Lobo (2011), esclarecimentos metodológicos para o cálculo da evasão — Instituto Lobo
- UFPB/STI, painel público *Indicadores Graduação*, Metabase
- UFPR, *Observatório de Dados de Evasão e Baixa Procura*; UFAC, *Painéis Estratégicos*;
  UFSM e UFSB/UnB DataLab, observatórios de evasão
- O'Neil, O'Neil & Chen, *Star Schema Benchmark*, UMass Boston
- TPC-DS e TPC-H, Transaction Processing Performance Council
- CEDS Data Warehouse, Common Education Data Standards
