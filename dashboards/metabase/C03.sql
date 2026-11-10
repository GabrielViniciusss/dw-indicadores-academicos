-- C3. Entre alunos matriculados em disciplinas, como a taxa de reprovacao de beneficiarios da assistencia estudantil se compara a de nao beneficiarios ao longo dos semestres?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT c.codigo_curso, d.ano_semestre,
       CASE WHEN f.bolsista_no_semestre = 1 THEN 'Beneficiario' ELSE 'Nao beneficiario' END AS grupo,
       SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA') AS matriculas,
       ROUND(100 * SUM(f.situacao_final LIKE 'REPROVADO%')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS taxa_reprovacao
FROM fato_professor_aluno f
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, d.ano_semestre, grupo
ORDER BY c.codigo_curso, d.ano_semestre, grupo;
