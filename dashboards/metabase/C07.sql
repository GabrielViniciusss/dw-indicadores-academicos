-- C7. Como as matriculas nas disciplinas criticas se distribuem entre aprovacao por nota, aprovacao na final, reprovacao por nota, reprovacao por falta e trancamento?
-- DADOS SINTÉTICOS; não representam a UFPE.
-- Percentuais sobre todas as matriculas, incluindo trancamentos: as cinco situacoes somam 100%.
WITH criticas AS (
  SELECT id_disciplina FROM fato_professor_disciplina GROUP BY id_disciplina
  ORDER BY SUM(qtd_reprovacoes_nota + qtd_reprovacoes_faltas) / SUM(qtd_matriculados - qtd_trancamentos) DESC
  LIMIT 10
)
SELECT d.ano_semestre, c.codigo_curso, di.nome_disciplina, SUM(f.qtd_matriculados) AS matriculas,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota) / SUM(f.qtd_matriculados), 1) AS aprovado_nota,
       ROUND(100 * SUM(f.qtd_aprovacoes_final) / SUM(f.qtd_matriculados), 1) AS aprovado_final,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota) / SUM(f.qtd_matriculados), 1) AS reprovado_nota,
       ROUND(100 * SUM(f.qtd_reprovacoes_faltas) / SUM(f.qtd_matriculados), 1) AS reprovado_falta,
       ROUND(100 * SUM(f.qtd_trancamentos) / SUM(f.qtd_matriculados), 1) AS trancado
FROM fato_professor_disciplina f
JOIN criticas x ON x.id_disciplina = f.id_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
JOIN dim_curso c ON c.id_curso = f.id_curso
GROUP BY d.ano_semestre, c.codigo_curso, di.nome_disciplina
ORDER BY d.ano_semestre, c.codigo_curso, di.nome_disciplina;
