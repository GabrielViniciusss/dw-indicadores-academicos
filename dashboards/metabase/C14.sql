-- C14. Qual e a Taxa de Sucesso na Graduacao (TSG) de cada curso por ano?
-- DADOS SINTÉTICOS; não representam a UFPE.
-- TSG(n) = concluintes no ano n / ingressantes das turmas cujo prazo previsto termina no ano n.
-- So entram anos em que essas turmas ingressaram a partir de 2018: as anteriores so tem quem ainda estava no curso em 2018.
WITH previstas AS (
  -- turma de ingresso e o ano em que termina o seu prazo previsto
  SELECT t.id_curso, t.id_turma_aluno, t.ano_ingresso, d.ano
  FROM dim_turma_aluno t
  JOIN dim_curso c ON c.id_curso = t.id_curso
  JOIN dim_data d ON d.ano * 2 + d.semestre = t.ano_ingresso * 2 + t.semestre_ingresso + c.semestres_previstos - 1
),
base AS (
  SELECT p.id_curso, p.ano, COUNT(a.id_aluno) AS ingressantes,
         MIN(p.ano_ingresso) AS primeira_coorte, COUNT(DISTINCT p.id_turma_aluno) AS turmas
  FROM previstas p
  LEFT JOIN dim_aluno a ON a.id_turma_aluno = p.id_turma_aluno
  GROUP BY p.id_curso, p.ano
),
concluintes AS (
  SELECT t.id_curso, d.ano, COUNT(*) AS concluintes
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  JOIN dim_data d ON d.id_data = a.id_data_saida
  WHERE a.situacao_vinculo = 'CONCLUIDO'
  GROUP BY t.id_curso, d.ano
)
SELECT c.codigo_curso, b.ano, c.semestres_previstos, COALESCE(k.concluintes, 0) AS concluintes,
       b.ingressantes AS ingressantes_previstos,
       ROUND(100 * COALESCE(k.concluintes, 0) / NULLIF(b.ingressantes, 0), 1) AS tsg
FROM base b
JOIN dim_curso c ON c.id_curso = b.id_curso
LEFT JOIN concluintes k ON k.id_curso = b.id_curso AND k.ano = b.ano
WHERE b.primeira_coorte >= 2018 AND b.turmas = 2 -- os dois semestres do ano tem turma prevista
ORDER BY c.codigo_curso, b.ano;
