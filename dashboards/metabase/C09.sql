-- C9. Em cada turma de ingresso, qual e a proporcao de alunos que concluiram, que seguem ativos e que evadiram?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT c.codigo_curso, t.ano_semestre_ingresso, COUNT(*) AS ingressantes,
       ROUND(100 * SUM(a.situacao_vinculo = 'CONCLUIDO') / COUNT(*), 1) AS concluiu,
       ROUND(100 * SUM(a.situacao_vinculo = 'ATIVO') / COUNT(*), 1) AS ativo,
       ROUND(100 * SUM(a.situacao_vinculo = 'EVADIDO') / COUNT(*), 1) AS evadiu
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
WHERE t.ano_ingresso >= 2018 -- turmas anteriores so tem os alunos que ainda estavam no curso em 2018
GROUP BY c.codigo_curso, t.ano_semestre_ingresso
ORDER BY c.codigo_curso, t.ano_semestre_ingresso;
