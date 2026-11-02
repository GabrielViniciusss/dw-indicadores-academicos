-- [AJUSTE] Ponte professor x turma: transforma os 3 papeis em linhas.
-- peso divide a turma entre os professores, para somas nao contarem duas vezes.
USE dw_academico;
CREATE OR REPLACE VIEW vw_turma_professor AS
WITH papeis AS (
  SELECT id_turma_disciplina, id_professor_1 AS id_professor, 1 AS papel FROM dim_turma_disciplina WHERE id_professor_1 IS NOT NULL
  UNION ALL
  SELECT id_turma_disciplina, id_professor_2, 2 FROM dim_turma_disciplina WHERE id_professor_2 IS NOT NULL
  UNION ALL
  SELECT id_turma_disciplina, id_professor_3, 3 FROM dim_turma_disciplina WHERE id_professor_3 IS NOT NULL
)
SELECT id_turma_disciplina, id_professor, papel,
       1.0 / COUNT(*) OVER (PARTITION BY id_turma_disciplina) AS peso
FROM papeis;
