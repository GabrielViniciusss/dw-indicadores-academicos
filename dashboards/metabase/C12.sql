-- C12. Em cada disciplina, como a taxa de aprovacao muda da 1a para a 2a tentativa, e para a 3a ou mais?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT di.nome_disciplina, c.codigo_curso, d.ano_semestre,
       CASE WHEN f.qtd_tentativas >= 3 THEN '3 ou mais' ELSE CAST(f.qtd_tentativas AS CHAR) END AS tentativa,
       COUNT(*) AS matriculas,
       ROUND(100 * SUM(f.situacao_final LIKE 'APROVADO%')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS taxa_aprovacao
FROM fato_professor_aluno f
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY di.nome_disciplina, c.codigo_curso, d.ano_semestre, tentativa
ORDER BY di.nome_disciplina, c.codigo_curso, d.ano_semestre, tentativa;
