-- C4. Como varia a taxa de reprovacao por nota e por falta conforme os semestres transcorridos desde o ingresso do aluno?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT c.codigo_curso, d.ano_semestre, t.ano_semestre_ingresso,
       CASE WHEN f.periodo_aluno >= 9 THEN '9+' ELSE CAST(f.periodo_aluno AS CHAR) END AS periodo,
       SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA') AS matriculas,
       ROUND(100 * SUM(f.situacao_final = 'REPROVADO_NOTA')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS reprovacao_nota,
       ROUND(100 * SUM(f.situacao_final = 'REPROVADO_FALTAS')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS reprovacao_falta
FROM fato_professor_aluno f
JOIN dim_aluno a ON a.id_aluno = f.id_aluno
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, d.ano_semestre, t.ano_semestre_ingresso, periodo
ORDER BY c.codigo_curso, d.ano_semestre, t.ano_semestre_ingresso, periodo;
