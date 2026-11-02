-- Deriva a segunda estrela da primeira, para as duas fecharem sempre.
USE dw_academico;
DELETE FROM fato_professor_disciplina;

INSERT INTO fato_professor_disciplina
WITH ordenadas AS (
  SELECT id_turma_disciplina, id_curso, nota_final,
         ROW_NUMBER() OVER (PARTITION BY id_turma_disciplina, id_curso ORDER BY nota_final) AS pos,
         COUNT(*) OVER (PARTITION BY id_turma_disciplina, id_curso) AS total
  FROM fato_professor_aluno
  WHERE nota_final IS NOT NULL
),
medianas AS (
  -- MySQL nao tem MEDIAN: media das posicoes centrais
  SELECT id_turma_disciplina, id_curso, ROUND(AVG(nota_final), 2) AS mediana
  FROM ordenadas
  WHERE pos IN (FLOOR((total + 1) / 2), CEIL((total + 1) / 2))
  GROUP BY id_turma_disciplina, id_curso
)
SELECT
  ROW_NUMBER() OVER (ORDER BY f.id_turma_disciplina, f.id_curso),
  MAX(f.id_disciplina), f.id_turma_disciplina, f.id_curso, MAX(f.id_data),
  COUNT(*),
  SUM(f.situacao_final = 'APROVADO_NOTA'),
  SUM(f.situacao_final = 'APROVADO_FINAL'),
  SUM(f.situacao_final = 'REPROVADO_NOTA'),
  SUM(f.situacao_final = 'REPROVADO_FALTAS'),
  SUM(f.situacao_final = 'TRANCADO_DISCIPLINA'),
  MIN(f.nota_final), MAX(f.nota_final), MAX(m.mediana),
  ROUND(AVG(f.nota_final), 2), ROUND(AVG(f.quantidade_faltas), 2),
  COALESCE(SUM(f.nota_final), 0), COUNT(f.nota_final),
  COALESCE(SUM(f.quantidade_faltas), 0), COUNT(f.quantidade_faltas),
  COALESCE(SUM(f.nota_final >= 0 AND f.nota_final < 3), 0),
  COALESCE(SUM(f.nota_final >= 3 AND f.nota_final < 7), 0),
  COALESCE(SUM(f.nota_final >= 7 AND f.nota_final < 8), 0),
  COALESCE(SUM(f.nota_final >= 8 AND f.nota_final < 9), 0),
  COALESCE(SUM(f.nota_final >= 9 AND f.nota_final <= 10), 0),
  SUM(f.bolsista_no_semestre AND f.situacao_final = 'APROVADO_NOTA'),
  SUM(f.bolsista_no_semestre AND f.situacao_final = 'APROVADO_FINAL'),
  SUM(f.bolsista_no_semestre AND f.situacao_final = 'REPROVADO_NOTA'),
  SUM(f.bolsista_no_semestre AND f.situacao_final = 'REPROVADO_FALTAS')
FROM fato_professor_aluno f
LEFT JOIN medianas m
  ON m.id_turma_disciplina = f.id_turma_disciplina AND m.id_curso = f.id_curso
GROUP BY f.id_turma_disciplina, f.id_curso;
