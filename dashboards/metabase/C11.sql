-- C11. Em cada turma de ingresso, quanto o tempo de conclusao se afasta do prazo previsto do curso?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT c.codigo_curso, t.ano_semestre_ingresso, c.semestres_previstos, COUNT(*) AS concluintes,
       ROUND(AVG((ds.ano * 2 + ds.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1), 1) AS media_semestres,
       ROUND(AVG((ds.ano * 2 + ds.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1) - c.semestres_previstos, 1) AS diferenca_semestres
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
JOIN dim_data ds ON ds.id_data = a.id_data_saida
WHERE a.situacao_vinculo = 'CONCLUIDO' AND t.ano_ingresso >= 2018
GROUP BY c.codigo_curso, t.ano_semestre_ingresso, c.semestres_previstos
ORDER BY c.codigo_curso, t.ano_semestre_ingresso;
