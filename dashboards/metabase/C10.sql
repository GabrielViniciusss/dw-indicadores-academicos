-- C10. Em cada turma de ingresso, como reprovacao e evasao variam entre tipos de cota e faixas economicas?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT c.codigo_curso, t.ano_semestre_ingresso, COALESCE(a.tipo_cota, 'Outras formas de ingresso') AS tipo_cota,
       a.faixa_economica, COUNT(DISTINCT a.id_aluno) AS alunos,
       ROUND(100 * SUM(f.situacao_final LIKE 'REPROVADO%')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS taxa_reprovacao,
       ROUND(100 * COUNT(DISTINCT CASE WHEN a.situacao_vinculo = 'EVADIDO' THEN a.id_aluno END)
             / COUNT(DISTINCT a.id_aluno), 1) AS taxa_evasao
FROM fato_professor_aluno f
JOIN dim_aluno a ON a.id_aluno = f.id_aluno
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
WHERE t.ano_ingresso >= 2018
GROUP BY c.codigo_curso, t.ano_semestre_ingresso, tipo_cota, a.faixa_economica
ORDER BY c.codigo_curso, t.ano_semestre_ingresso, tipo_cota, a.faixa_economica;
