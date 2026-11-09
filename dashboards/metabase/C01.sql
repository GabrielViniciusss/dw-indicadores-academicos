-- C1. Como a taxa de aprovacao de cada disciplina critica mudou de um semestre para outro?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH criticas AS (
  SELECT id_disciplina FROM fato_professor_disciplina GROUP BY id_disciplina
  ORDER BY SUM(qtd_reprovacoes_nota + qtd_reprovacoes_faltas) / SUM(qtd_matriculados - qtd_trancamentos) DESC
  LIMIT 10
)
SELECT di.nome_disciplina, d.ano_semestre, c.codigo_curso, t.codigo_turma,
       SUM(f.qtd_aprovacoes_nota + f.qtd_aprovacoes_final) AS aprovados,
       SUM(f.qtd_reprovacoes_nota) AS reprovados_nota, SUM(f.qtd_reprovacoes_faltas) AS reprovados_falta,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota + f.qtd_aprovacoes_final)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_aprovacao
FROM fato_professor_disciplina f
JOIN criticas x ON x.id_disciplina = f.id_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_turma_disciplina t ON t.id_turma_disciplina = f.id_turma_disciplina
GROUP BY di.nome_disciplina, d.ano_semestre, c.codigo_curso, t.codigo_turma
ORDER BY di.nome_disciplina, d.ano_semestre, c.codigo_curso, t.codigo_turma;
