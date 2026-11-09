-- C6. Em cada oferta de disciplina, como a taxa de reprovacao se relaciona com a media de faltas?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT d.ano_semestre, c.codigo_curso, di.nome_disciplina, t.codigo_turma,
       ROUND(f.soma_faltas / NULLIF(f.qtd_faltas_validas, 0), 2) AS media_faltas,
       ROUND(100 * (f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(f.qtd_matriculados - f.qtd_trancamentos, 0), 1) AS taxa_reprovacao,
       f.qtd_matriculados AS alunos
FROM fato_professor_disciplina f
JOIN dim_turma_disciplina t ON t.id_turma_disciplina = f.id_turma_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
JOIN dim_curso c ON c.id_curso = f.id_curso
ORDER BY d.ano_semestre, c.codigo_curso, di.nome_disciplina, t.codigo_turma;
