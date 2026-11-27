-- C15. Ano a ano, que parte de cada turma de ingresso permanece, concluiu ou desistiu (TAP, TCA e TDA do INEP)?
-- DADOS SINTÉTICOS; não representam a UFPE.
-- Sobre o snapshot fato_vinculo_semestre. TAP = ativos no fim do ano; TCA e TDA acumulam concluintes e evadidos.
-- Denominador: ingressantes da turma (nao ha falecidos na base). TAP + TCA + TDA = 100% em todo ano.
WITH turma AS (
  SELECT t.id_turma_aluno, t.id_curso, t.ano_ingresso, t.ano_semestre_ingresso, COUNT(*) AS ingressantes
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  WHERE t.ano_ingresso >= 2018
  GROUP BY t.id_turma_aluno, t.id_curso, t.ano_ingresso, t.ano_semestre_ingresso
),
anos AS (SELECT DISTINCT ano FROM dim_data),
fluxo AS (
  -- ativos so no ultimo semestre do ano: estoque nao se soma entre semestres
  SELECT v.id_turma_aluno, d.ano,
         SUM(CASE WHEN d.semestre = (SELECT MAX(x.semestre) FROM dim_data x WHERE x.ano = d.ano) THEN v.qtd_ativo ELSE 0 END) AS ativos,
         SUM(v.qtd_concluiu) AS concluintes, SUM(v.qtd_evadiu) AS evadidos
  FROM fato_vinculo_semestre v
  JOIN dim_data d ON d.id_data = v.id_data
  GROUP BY v.id_turma_aluno, d.ano
),
serie AS (
  SELECT k.id_curso, k.ano_semestre_ingresso, y.ano, k.ingressantes, COALESCE(f.ativos, 0) AS ativos,
         SUM(COALESCE(f.concluintes, 0)) OVER (PARTITION BY k.id_turma_aluno ORDER BY y.ano) AS concluintes_acum,
         SUM(COALESCE(f.evadidos, 0)) OVER (PARTITION BY k.id_turma_aluno ORDER BY y.ano) AS evadidos_acum
  FROM turma k
  JOIN anos y ON y.ano >= k.ano_ingresso
  LEFT JOIN fluxo f ON f.id_turma_aluno = k.id_turma_aluno AND f.ano = y.ano
)
SELECT c.codigo_curso, s.ano_semestre_ingresso, s.ano, s.ingressantes,
       ROUND(100 * s.ativos / s.ingressantes, 1) AS tap,
       ROUND(100 * s.concluintes_acum / s.ingressantes, 1) AS tca,
       ROUND(100 * s.evadidos_acum / s.ingressantes, 1) AS tda
FROM serie s
JOIN dim_curso c ON c.id_curso = s.id_curso
ORDER BY c.codigo_curso, s.ano_semestre_ingresso, s.ano;
