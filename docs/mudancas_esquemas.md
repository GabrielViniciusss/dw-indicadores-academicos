# Mudanças em relação aos diagramas do DrawSQL

Comparação entre os diagramas [PDFs](https://drawsql.app/teams/maria-fernanda-fa/diagrams/pdfs) e [PDFs 2](https://drawsql.app/teams/maria-fernanda-fa/diagrams/pdfs-2), lidos em 02/11/2026, e o arquivo `sql/01_ddl.sql`.

Os diagramas ainda não foram alterados. Eles precisam receber os acréscimos abaixo.

## Resumo

| # | Onde | Mudança | Diagrama | Consultas |
| --- | --- | --- | --- | --- |
| 1 | `dim_curso` | Nova coluna `semestres_previstos` | PDFs e PDFs 2 | C5 |
| 2 | `dim_aluno` | Nova coluna `situacao_vinculo` | PDFs | C2, C3, C4, C5, C6 |
| 3 | `dim_aluno` | Nova coluna `id_data_saida`, com relação para `dim_data` | PDFs | C3, C4 |
| 4 | `fato_professor_aluno` | Nova coluna `periodo_aluno` | PDFs | C3, C6 |
| 5 | `fato_professor_disciplina` | Nova coluna `qtd_trancamentos` | PDFs 2 | C1, C7 |
| 6 | Banco | Nova view `vw_turma_professor` | Só no SQL | C7 |

Nenhuma tabela ou coluna foi removida ou renomeada. Os grãos, as chaves primárias, os índices únicos e as relações que já existiam continuam iguais.

## Colunas para adicionar no DrawSQL

| Tabela | Coluna | Tipo | Nulo | Posição | Comentário |
| --- | --- | --- | --- | --- | --- |
| `dim_curso` | `semestres_previstos` | `smallint` | Sim | Depois de `campus` | Prazo previsto do curso, em semestres |
| `dim_aluno` | `situacao_vinculo` | `varchar(20)` | Sim | Depois de `versao_curriculo` | ATIVO, CONCLUIDO ou EVADIDO |
| `dim_aluno` | `id_data_saida` | `bigint` | Sim | Depois de `situacao_vinculo` | Semestre da saída, nulo se ATIVO |
| `fato_professor_aluno` | `periodo_aluno` | `smallint` | Não | Depois de `qtd_tentativas` | Semestres desde o ingresso; o primeiro semestre é 1 |
| `fato_professor_disciplina` | `qtd_trancamentos` | `int` | Não | Depois de `qtd_reprovacoes_faltas` | Fecha a conta de `qtd_matriculados` |

No diagrama PDFs, crie também a relação `dim_aluno.id_data_saida` para `dim_data.id_data` (muitos para um).

`dim_curso` existe nos dois diagramas e é uma dimensão compartilhada. Por isso, a coluna entra nos dois.

## Por que cada mudança foi feita

- **`semestres_previstos`:** cada curso tem um prazo diferente, e sem ele não há como saber quem está atrasado.
- **`situacao_vinculo` e `id_data_saida`:** o esquema registrava as matrículas, mas não dizia quem concluiu ou evadiu, nem quando. A evasão não pode ser deduzida só pela falta de matrícula, porque o aluno pode estar apenas sem cursar nada naquele semestre.
- **`periodo_aluno`:** mostra em que momento do curso a matrícula aconteceu. É calculado na carga a partir da coorte do aluno e do semestre da matrícula, então dispensa uma tabela de matriz curricular por curso.
- **`qtd_trancamentos`:** as quatro contagens de situação não fechavam com `qtd_matriculados` quando havia trancamento. Agora vale: `qtd_matriculados = qtd_aprovacoes_nota + qtd_aprovacoes_final + qtd_reprovacoes_nota + qtd_reprovacoes_faltas + qtd_trancamentos`.
- **`vw_turma_professor`:** a turma guarda até três professores em três colunas. A view transforma esses papéis em linhas, o que evita três joins em cada consulta. A coluna `peso` reparte a turma entre os professores em somas gerais. É uma view, então nenhuma tabela muda.

## SQL equivalente

Estes comandos levam um banco criado a partir dos diagramas originais para a versão atual.

```sql
ALTER TABLE dim_curso
  ADD COLUMN semestres_previstos SMALLINT AFTER campus;

ALTER TABLE dim_aluno
  ADD COLUMN situacao_vinculo VARCHAR(20) AFTER versao_curriculo,
  ADD COLUMN id_data_saida BIGINT AFTER situacao_vinculo,
  ADD FOREIGN KEY (id_data_saida) REFERENCES dim_data (id_data);

ALTER TABLE fato_professor_aluno
  ADD COLUMN periodo_aluno SMALLINT NOT NULL AFTER qtd_tentativas;

ALTER TABLE fato_professor_disciplina
  ADD COLUMN qtd_trancamentos INT NOT NULL AFTER qtd_reprovacoes_faltas;
```

A definição da view está em `sql/04_views.sql`.

## Unificação dos dois diagramas

No DrawSQL, as duas estrelas estão em diagramas separados. No SQL, elas ficam no mesmo banco, `dw_academico`, e compartilham `dim_data`, `dim_curso`, `dim_disciplina`, `dim_professor` e `dim_turma_disciplina`. Isso não muda a modelagem: essas tabelas já tinham a mesma estrutura nos dois diagramas.
