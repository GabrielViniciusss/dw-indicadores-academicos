-- C4. Em um curso, quais professores tem taxa de reprovacao mais distante da media das disciplinas que ministram?
-- DADOS SINTÉTICOS; não representam a UFPE.
WITH media_disciplina AS (
  SELECT id_curso, id_disciplina,
         SUM(qtd_reprovacoes_nota + qtd_reprovacoes_faltas) / NULLIF(SUM(qtd_matriculados - qtd_trancamentos), 0) AS taxa
  FROM fato_professor_disciplina
  GROUP BY id_curso, id_disciplina
)
SELECT c.codigo_curso, p.nome_professor, COUNT(DISTINCT f.id_disciplina) AS disciplinas,
       SUM(f.qtd_matriculados) AS alunos,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / SUM(f.qtd_matriculados - f.qtd_trancamentos), 1) AS taxa_reprovacao,
       ROUND(100 * SUM((f.qtd_matriculados - f.qtd_trancamentos) * m.taxa)
             / SUM(f.qtd_matriculados - f.qtd_trancamentos), 1) AS taxa_esperada,
       ROUND(100 * (SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
                    - SUM((f.qtd_matriculados - f.qtd_trancamentos) * m.taxa))
             / SUM(f.qtd_matriculados - f.qtd_trancamentos), 1) AS diferenca_pontos
FROM fato_professor_disciplina f
JOIN vw_turma_professor tp ON tp.id_turma_disciplina = f.id_turma_disciplina
JOIN dim_professor p ON p.id_professor = tp.id_professor
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN media_disciplina m ON m.id_curso = f.id_curso AND m.id_disciplina = f.id_disciplina
GROUP BY c.codigo_curso, p.nome_professor
ORDER BY c.codigo_curso, ABS(diferenca_pontos) DESC;
