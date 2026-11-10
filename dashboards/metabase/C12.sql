-- C12. Na mesma disciplina e semestre, como variam aprovacao, nota media e tamanho das turmas associadas a diferentes professores?
-- DADOS SINTÉTICOS; não representam a UFPE.
SELECT di.nome_disciplina, d.ano_semestre, p.nome_professor, t.codigo_turma,
       SUM(f.qtd_matriculados) AS alunos,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota + f.qtd_aprovacoes_final)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_aprovacao,
       ROUND(SUM(f.soma_notas_finais) / NULLIF(SUM(f.qtd_notas_validas), 0), 2) AS nota_media
FROM fato_professor_disciplina f
JOIN vw_turma_professor tp ON tp.id_turma_disciplina = f.id_turma_disciplina
JOIN dim_professor p ON p.id_professor = tp.id_professor
JOIN dim_turma_disciplina t ON t.id_turma_disciplina = f.id_turma_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY di.nome_disciplina, d.ano_semestre, p.nome_professor, t.codigo_turma
ORDER BY di.nome_disciplina, d.ano_semestre, t.codigo_turma, p.nome_professor;
