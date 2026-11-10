-- C10. Quais turmas tiveram taxa de reprovacao muito acima ou abaixo do historico da mesma disciplina no curso?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH oferta AS (
  SELECT f.id_turma_disciplina, f.id_curso, f.id_disciplina, f.id_data,
         f.qtd_matriculados - f.qtd_trancamentos AS matriculas,
         f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas AS reprovacoes
  FROM fato_professor_disciplina f
),
comparada AS (
  -- historico: semestres anteriores da mesma disciplina e curso, ponderado pelas matriculas
  SELECT o.*,
         (SELECT 100 * SUM(h.reprovacoes) / NULLIF(SUM(h.matriculas), 0)
          FROM oferta h
          WHERE h.id_curso = o.id_curso AND h.id_disciplina = o.id_disciplina AND h.id_data < o.id_data) AS taxa_historica
  FROM oferta o
  WHERE o.matriculas >= 10 -- turmas menores oscilam demais
)
SELECT d.ano_semestre, c.codigo_curso, di.nome_disciplina, t.codigo_turma, x.matriculas,
       ROUND(100 * x.reprovacoes / x.matriculas, 1) AS taxa_reprovacao,
       ROUND(x.taxa_historica, 1) AS taxa_historica,
       ROUND(100 * x.reprovacoes / x.matriculas - x.taxa_historica, 1) AS diferenca_pontos
FROM comparada x
JOIN dim_turma_disciplina t ON t.id_turma_disciplina = x.id_turma_disciplina
JOIN dim_disciplina di ON di.id_disciplina = x.id_disciplina
JOIN dim_data d ON d.id_data = x.id_data
JOIN dim_curso c ON c.id_curso = x.id_curso
WHERE x.taxa_historica IS NOT NULL
ORDER BY d.ano_semestre, c.codigo_curso, ABS(diferenca_pontos) DESC, di.nome_disciplina, t.codigo_turma;
