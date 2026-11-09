-- C5. Como a taxa de reprovacao das disciplinas criticas evoluiu por semestre e periodo curricular?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH criticas AS (
  SELECT id_disciplina FROM fato_professor_disciplina GROUP BY id_disciplina
  ORDER BY SUM(qtd_reprovacoes_nota + qtd_reprovacoes_faltas) / SUM(qtd_matriculados - qtd_trancamentos) DESC
  LIMIT 10
)
SELECT c.codigo_curso, m.periodo_curricular, di.nome_disciplina, d.ano_semestre,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_reprovacao
FROM fato_professor_disciplina f
JOIN criticas x ON x.id_disciplina = f.id_disciplina
JOIN curso_disciplina m ON m.id_curso = f.id_curso AND m.id_disciplina = f.id_disciplina
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, m.periodo_curricular, di.nome_disciplina, d.ano_semestre
ORDER BY c.codigo_curso, m.periodo_curricular, di.nome_disciplina, d.ano_semestre;
