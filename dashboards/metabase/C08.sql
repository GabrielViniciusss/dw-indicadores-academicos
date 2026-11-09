-- C8. Como as reprovacoes por nota e por falta se distribuem conforme o periodo do aluno, em cada semestre?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT d.ano_semestre, f.periodo_aluno,
       SUM(f.situacao_final = 'REPROVADO_NOTA') AS reprovacoes_nota,
       SUM(f.situacao_final = 'REPROVADO_FALTAS') AS reprovacoes_falta,
       COUNT(*) AS matriculas
FROM fato_professor_aluno f
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY d.ano_semestre, f.periodo_aluno
ORDER BY d.ano_semestre, f.periodo_aluno;
