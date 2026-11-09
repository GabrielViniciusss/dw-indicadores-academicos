-- C2. Em cada semestre, quais sao as 10 disciplinas com maior taxa de reprovacao, e quanto vem de nota e de falta?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH por_semestre AS (
  SELECT f.id_data, f.id_disciplina,
         100 * SUM(f.qtd_reprovacoes_nota) / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0) AS por_nota,
         100 * SUM(f.qtd_reprovacoes_faltas) / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0) AS por_falta
  FROM fato_professor_disciplina f
  GROUP BY f.id_data, f.id_disciplina
),
ranking AS (
  SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.id_data ORDER BY p.por_nota + p.por_falta DESC) AS posicao
  FROM por_semestre p
)
SELECT d.ano_semestre, r.posicao, di.nome_disciplina, ROUND(r.por_nota, 1) AS reprovacao_nota,
       ROUND(r.por_falta, 1) AS reprovacao_falta, ROUND(r.por_nota + r.por_falta, 1) AS taxa_reprovacao
FROM ranking r
JOIN dim_data d ON d.id_data = r.id_data
JOIN dim_disciplina di ON di.id_disciplina = r.id_disciplina
WHERE r.posicao <= 10
ORDER BY d.ano_semestre, r.posicao;
