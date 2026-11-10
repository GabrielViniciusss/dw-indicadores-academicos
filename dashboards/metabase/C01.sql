-- C1. Em cada semestre, quais sao as 10 disciplinas com maior taxa de reprovacao, separando reprovacao por nota e por falta?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH por_semestre AS (
  SELECT f.id_data, f.id_curso, f.id_disciplina,
         SUM(f.qtd_matriculados - f.qtd_trancamentos) AS matriculas,
         SUM(f.qtd_reprovacoes_nota) AS rep_nota,
         SUM(f.qtd_reprovacoes_faltas) AS rep_falta
  FROM fato_professor_disciplina f
  GROUP BY f.id_data, f.id_curso, f.id_disciplina
  HAVING SUM(f.qtd_matriculados - f.qtd_trancamentos) > 0
),
ranking AS (
  -- ranking separado por semestre e curso; empate resolvido pelo id da disciplina
  SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.id_data, p.id_curso
                                 ORDER BY 100 * (p.rep_nota + p.rep_falta) / p.matriculas DESC, p.id_disciplina) AS posicao
  FROM por_semestre p
)
SELECT d.ano_semestre, c.codigo_curso, r.posicao, di.nome_disciplina, r.matriculas,
       ROUND(100 * r.rep_nota / r.matriculas, 1) AS reprovacao_nota,
       ROUND(100 * r.rep_falta / r.matriculas, 1) AS reprovacao_falta,
       ROUND(100 * (r.rep_nota + r.rep_falta) / r.matriculas, 1) AS taxa_reprovacao
FROM ranking r
JOIN dim_data d ON d.id_data = r.id_data
JOIN dim_curso c ON c.id_curso = r.id_curso
JOIN dim_disciplina di ON di.id_disciplina = r.id_disciplina
WHERE r.posicao <= 10
ORDER BY d.ano_semestre, c.codigo_curso, r.posicao;
