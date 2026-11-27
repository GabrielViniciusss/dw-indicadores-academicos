-- C13. Em cada semestre, quanto as matriculas estao atrasadas em relacao ao periodo previsto da disciplina na matriz do curso?
-- DADOS SINTÉTICOS; não representam a UFPE.
-- Atraso = periodo do aluno (semestres desde o ingresso) - periodo curricular da disciplina. Negativo = adiantado.
SELECT c.codigo_curso, d.ano_semestre, m.periodo_curricular, COUNT(*) AS matriculas,
       ROUND(AVG(f.periodo_aluno - m.periodo_curricular), 2) AS atraso_medio,
       ROUND(100 * SUM(f.periodo_aluno > m.periodo_curricular) / COUNT(*), 1) AS pct_atrasadas
FROM fato_professor_aluno f
JOIN curso_disciplina m ON m.id_curso = f.id_curso AND m.id_disciplina = f.id_disciplina
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, d.ano_semestre, m.periodo_curricular
ORDER BY c.codigo_curso, d.ano_semestre, m.periodo_curricular;
