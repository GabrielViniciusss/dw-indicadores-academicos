-- C13. Como reprovacao e evasao de beneficiarios se comparam com as de nao beneficiarios, em cada curso e semestre?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH alunos_semestre AS (
  -- evasao medida por semestre: quem evadiu ao final do semestre em que estava matriculado
  SELECT f.id_curso, f.id_data, f.id_aluno, MAX(f.bolsista_no_semestre) AS beneficiario,
         SUM(f.situacao_final LIKE 'REPROVADO%') AS reprovacoes,
         SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA') AS com_resultado,
         MAX(a.situacao_vinculo = 'EVADIDO' AND a.id_data_saida = f.id_data) AS evadiu
  FROM fato_professor_aluno f
  JOIN dim_aluno a ON a.id_aluno = f.id_aluno
  GROUP BY f.id_curso, f.id_data, f.id_aluno
)
SELECT c.codigo_curso, d.ano_semestre,
       CASE WHEN x.beneficiario = 1 THEN 'Beneficiario' ELSE 'Nao beneficiario' END AS grupo,
       COUNT(*) AS alunos,
       ROUND(100 * SUM(x.reprovacoes) / NULLIF(SUM(x.com_resultado), 0), 1) AS taxa_reprovacao,
       ROUND(100 * SUM(x.evadiu) / COUNT(*), 1) AS taxa_evasao
FROM alunos_semestre x
JOIN dim_curso c ON c.id_curso = x.id_curso
JOIN dim_data d ON d.id_data = x.id_data
GROUP BY c.codigo_curso, d.ano_semestre, grupo
ORDER BY c.codigo_curso, d.ano_semestre, grupo;
