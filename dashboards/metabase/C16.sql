-- C16. Quanto a formula de evasao anual do Instituto Lobo se afasta da evasao medida pela coorte?
-- DADOS SINTÉTICOS; não representam a UFPE.
-- Lobo: EV(n) = 1 - (M(n) - I(n)) / (M(n-1) - C(n-1)), com M = matriculas como no Censo do INEP
-- (cursando ou formado no ano; quem evadiu no ano nao conta), I = ingressantes e C = concluintes.
-- Coorte: veteranos que evadiram no ano / veteranos com vinculo no ano (ingressaram antes de n).
-- A diferenca e exatamente evadidos_calouros / base_veteranos: a formula poe no numerador quem entrou e saiu no mesmo ano.
WITH aluno AS (
  SELECT t.id_curso, t.ano_ingresso, COALESCE(ds.ano, 9999) AS ano_saida, a.situacao_vinculo
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  LEFT JOIN dim_data ds ON ds.id_data = a.id_data_saida
),
ano_curso AS (
  SELECT x.id_curso, y.ano,
         SUM(x.ano_ingresso <= y.ano AND x.ano_saida >= y.ano
             AND NOT (x.ano_saida = y.ano AND x.situacao_vinculo = 'EVADIDO')) AS matriculas,
         SUM(x.ano_ingresso = y.ano) AS ingressantes,
         SUM(x.ano_saida = y.ano AND x.situacao_vinculo = 'CONCLUIDO') AS concluintes,
         SUM(x.ano_ingresso < y.ano AND x.ano_saida >= y.ano) AS base_veteranos,
         SUM(x.ano_ingresso < y.ano AND x.ano_saida = y.ano AND x.situacao_vinculo = 'EVADIDO') AS evadidos_veteranos,
         SUM(x.ano_ingresso = y.ano AND x.ano_saida = y.ano AND x.situacao_vinculo = 'EVADIDO') AS evadidos_calouros
  FROM aluno x
  CROSS JOIN (SELECT DISTINCT ano FROM dim_data) y
  GROUP BY x.id_curso, y.ano
),
lobo AS (
  -- o denominador da formula vem do ano anterior; o primeiro ano da base fica sem ele
  SELECT k.*, LAG(k.matriculas - k.concluintes) OVER (PARTITION BY k.id_curso ORDER BY k.ano) AS base_lobo
  FROM ano_curso k
)
SELECT c.codigo_curso, l.ano, l.base_veteranos, l.evadidos_veteranos, l.evadidos_calouros,
       ROUND(100 * (l.base_lobo - (l.matriculas - l.ingressantes)) / l.base_lobo, 1) AS evasao_lobo,
       ROUND(100 * l.evadidos_veteranos / l.base_veteranos, 1) AS evasao_coorte,
       ROUND(100 * (l.base_lobo - (l.matriculas - l.ingressantes)) / l.base_lobo
             - 100 * l.evadidos_veteranos / l.base_veteranos, 1) AS diferenca_pontos
FROM lobo l
JOIN dim_curso c ON c.id_curso = l.id_curso
WHERE l.base_lobo IS NOT NULL
ORDER BY c.codigo_curso, l.ano;
