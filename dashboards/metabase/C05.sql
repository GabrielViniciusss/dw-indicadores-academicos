-- C5. Quais disciplinas apresentam maior proporcao de alunos que reprovaram duas ou mais vezes na mesma disciplina?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH historico AS (
  -- uma linha por aluno, disciplina e curso, somando as reprovacoes de 2018.1 a 2025.2
  SELECT f.id_curso, f.id_disciplina, f.id_aluno,
         SUM(f.situacao_final LIKE 'REPROVADO%') AS reprovacoes
  FROM fato_professor_aluno f
  WHERE f.situacao_final <> 'TRANCADO_DISCIPLINA'
  GROUP BY f.id_curso, f.id_disciplina, f.id_aluno
)
SELECT c.codigo_curso, di.nome_disciplina, COUNT(*) AS alunos,
       SUM(h.reprovacoes >= 2) AS alunos_afetados,
       ROUND(100 * SUM(h.reprovacoes >= 2) / COUNT(*), 1) AS taxa_recorrente
FROM historico h
JOIN dim_curso c ON c.id_curso = h.id_curso
JOIN dim_disciplina di ON di.id_disciplina = h.id_disciplina
GROUP BY c.codigo_curso, di.nome_disciplina
ORDER BY c.codigo_curso, taxa_recorrente DESC, di.nome_disciplina;
