# Mudanças em relação aos diagramas do DrawSQL

Comparação entre os diagramas [PDFs](https://drawsql.app/teams/maria-fernanda-fa/diagrams/pdfs) e [PDFs 2](https://drawsql.app/teams/maria-fernanda-fa/diagrams/pdfs-2), lidos em 02/11/2026, e o arquivo `sql/01_ddl.sql`.

O projeto agora tem um único esquema, em `docs/dbml/dw_academico.dbml`, com as duas estrelas juntas. Para atualizar o DrawSQL, use esse arquivo em um único diagrama, em vez de manter PDFs e PDFs 2 separados.

## Resumo

| # | Onde | Mudança | Diagrama | Consultas |
| --- | --- | --- | --- | --- |
| 1 | `dim_curso` | Nova coluna `semestres_previstos` | PDFs e PDFs 2 | C11 |
| 2 | `dim_aluno` | Nova coluna `situacao_vinculo` | PDFs | C9, C10, C11, C13 |
| 3 | `dim_aluno` | Nova coluna `id_data_saida`, com relação para `dim_data` | PDFs | C11, C13 |
| 4 | `fato_professor_aluno` | Nova coluna `periodo_aluno` | PDFs | C8 |
| 5 | `fato_professor_disciplina` | Nova coluna `qtd_trancamentos` | PDFs 2 | C1, C2, C3, C4, C5, C6, C7 |
| 6 | Banco | Nova tabela `curso_disciplina` | PDFs 2 | C5 |
| 7 | Banco | Nova view `vw_turma_professor` | Só no SQL | C4, C7 |

Nenhuma tabela ou coluna foi removida ou renomeada. Os grãos, as chaves primárias, os índices únicos e as relações que já existiam continuam iguais.

## Colunas para adicionar no DrawSQL

| Tabela | Coluna | Tipo | Nulo | Posição | Comentário |
| --- | --- | --- | --- | --- | --- |
| `dim_curso` | `semestres_previstos` | `smallint` | Sim | Depois de `campus` | Prazo previsto do curso, em semestres |
| `dim_aluno` | `situacao_vinculo` | `varchar(20)` | Sim | Depois de `versao_curriculo` | ATIVO, CONCLUIDO ou EVADIDO |
| `dim_aluno` | `id_data_saida` | `bigint` | Sim | Depois de `situacao_vinculo` | Semestre da saída, nulo se ATIVO |
| `fato_professor_aluno` | `periodo_aluno` | `smallint` | Não | Depois de `qtd_tentativas` | Semestres desde o ingresso; o primeiro semestre é 1 |
| `fato_professor_disciplina` | `qtd_trancamentos` | `int` | Não | Depois de `qtd_reprovacoes_faltas` | Fecha a conta de `qtd_matriculados` |

No diagrama PDFs 2, crie também a tabela `curso_disciplina`:

| Coluna | Tipo | Nulo | Observação |
| --- | --- | --- | --- |
| `id_curso` | `bigint` | Não | Chave primária, com relação para `dim_curso.id_curso` |
| `id_disciplina` | `bigint` | Não | Chave primária, com relação para `dim_disciplina.id_disciplina` |
| `periodo_curricular` | `smallint` | Não | Período da disciplina na matriz daquele curso |

No diagrama PDFs, crie também a relação `dim_aluno.id_data_saida` para `dim_data.id_data` (muitos para um).

`dim_curso` existe nos dois diagramas e é uma dimensão compartilhada. Por isso, a coluna entra nos dois.

## Por que cada mudança foi feita

- **`semestres_previstos`:** cada curso tem um prazo diferente, e sem ele não há como saber quem está atrasado.
- **`situacao_vinculo` e `id_data_saida`:** o esquema registrava as matrículas, mas não dizia quem concluiu ou evadiu, nem quando. A evasão não pode ser deduzida só pela falta de matrícula, porque o aluno pode estar apenas sem cursar nada naquele semestre.
- **`periodo_aluno`:** mostra em que momento do curso a matrícula aconteceu. É calculado na carga a partir da coorte do aluno e do semestre da matrícula, então dispensa uma tabela de matriz curricular por curso.
- **`qtd_trancamentos`:** as quatro contagens de situação não fechavam com `qtd_matriculados` quando havia trancamento. Agora vale: `qtd_matriculados = qtd_aprovacoes_nota + qtd_aprovacoes_final + qtd_reprovacoes_nota + qtd_reprovacoes_faltas + qtd_trancamentos`.
- **`curso_disciplina`:** o professor pediu para considerar o período curricular. Ele fica em uma tabela própria porque a mesma disciplina pode estar em períodos diferentes em cada curso.
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

CREATE TABLE curso_disciplina (
  id_curso BIGINT NOT NULL,
  id_disciplina BIGINT NOT NULL,
  periodo_curricular SMALLINT NOT NULL,
  PRIMARY KEY (id_curso, id_disciplina),
  FOREIGN KEY (id_curso) REFERENCES dim_curso (id_curso),
  FOREIGN KEY (id_disciplina) REFERENCES dim_disciplina (id_disciplina)
);
```

A definição da view está em `sql/04_views.sql`.

## Unificação dos dois diagramas

No DrawSQL, as duas estrelas estão em diagramas separados. No SQL, elas ficam no mesmo banco, `dw_academico`, e compartilham `dim_data`, `dim_curso`, `dim_disciplina`, `dim_professor` e `dim_turma_disciplina`. Isso não muda a modelagem: essas tabelas já tinham a mesma estrutura nos dois diagramas.
