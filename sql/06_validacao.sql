-- Cada linha deve retornar erros = 0.
USE dw_academico;

SELECT 'duas estrelas: matriculas' AS teste,
       ABS((SELECT COUNT(*) FROM fato_professor_aluno) - (SELECT SUM(qtd_matriculados) FROM fato_professor_disciplina)) AS erros
UNION ALL SELECT 'duas estrelas: soma das notas',
       ABS((SELECT COALESCE(SUM(nota_final), 0) FROM fato_professor_aluno) - (SELECT SUM(soma_notas_finais) FROM fato_professor_disciplina))
UNION ALL SELECT 'duas estrelas: soma das faltas',
       ABS((SELECT COALESCE(SUM(quantidade_faltas), 0) FROM fato_professor_aluno) - (SELECT SUM(soma_faltas) FROM fato_professor_disciplina))
UNION ALL SELECT 'situacoes fecham qtd_matriculados',
       (SELECT COUNT(*) FROM fato_professor_disciplina
        WHERE qtd_matriculados <> qtd_aprovacoes_nota + qtd_aprovacoes_final + qtd_reprovacoes_nota + qtd_reprovacoes_faltas + qtd_trancamentos)
UNION ALL SELECT 'faixas fecham qtd_notas_validas',
       (SELECT COUNT(*) FROM fato_professor_disciplina
        WHERE qtd_notas_validas <> qtd_nota_0_2_9 + qtd_nota_3_6_9 + qtd_nota_7_7_9 + qtd_nota_8_8_9 + qtd_nota_9_10)
UNION ALL SELECT 'media_notas igual a soma / qtd',
       (SELECT COUNT(*) FROM fato_professor_disciplina
        WHERE qtd_notas_validas > 0 AND ABS(media_notas - soma_notas_finais / qtd_notas_validas) > 0.01)
UNION ALL SELECT 'menor <= mediana <= maior',
       (SELECT COUNT(*) FROM fato_professor_disciplina WHERE mediana_notas < menor_notas OR mediana_notas > maior_notas)
UNION ALL SELECT 'bolsistas nao excedem o total da situacao',
       (SELECT COUNT(*) FROM fato_professor_disciplina
        WHERE qtd_bolsistas_aprovados_nota > qtd_aprovacoes_nota OR qtd_bolsistas_aprovados_final > qtd_aprovacoes_final
           OR qtd_bolsistas_reprovados_nota > qtd_reprovacoes_nota OR qtd_bolsistas_reprovados_faltas > qtd_reprovacoes_faltas)
UNION ALL SELECT 'nota coerente com a situacao',
       (SELECT COUNT(*) FROM fato_professor_aluno
        WHERE (situacao_final = 'APROVADO_NOTA' AND nota_final < 7)
           OR (situacao_final = 'APROVADO_FINAL' AND (nota_final < 5 OR nota_final >= 7))
           OR (situacao_final = 'REPROVADO_NOTA' AND nota_final >= 5)
           OR (situacao_final = 'TRANCADO_DISCIPLINA' AND nota_final IS NOT NULL))
UNION ALL SELECT 'carga horaria so em aprovacao',
       (SELECT COUNT(*) FROM fato_professor_aluno f JOIN dim_disciplina d ON d.id_disciplina = f.id_disciplina
        WHERE (f.situacao_final LIKE 'APROVADO%' AND f.ch_adquirida <> d.carga_horaria)
           OR (f.situacao_final NOT LIKE 'APROVADO%' AND f.ch_adquirida <> 0))
UNION ALL SELECT 'aluno cursa no curso da sua coorte',
       (SELECT COUNT(*) FROM fato_professor_aluno f JOIN dim_aluno a ON a.id_aluno = f.id_aluno
        JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno WHERE t.id_curso <> f.id_curso)
UNION ALL SELECT 'disciplina e semestre iguais aos da turma',
       (SELECT COUNT(*) FROM fato_professor_aluno f JOIN dim_turma_disciplina t ON t.id_turma_disciplina = f.id_turma_disciplina
        WHERE t.id_disciplina <> f.id_disciplina OR t.id_data <> f.id_data)
UNION ALL SELECT 'nenhuma matricula antes do ingresso ou apos a saida',
       (SELECT COUNT(*) FROM fato_professor_aluno f JOIN dim_aluno a ON a.id_aluno = f.id_aluno
        JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
        WHERE f.id_data < t.ano_ingresso * 10 + t.semestre_ingresso OR (a.id_data_saida IS NOT NULL AND f.id_data > a.id_data_saida))
UNION ALL SELECT 'saida preenchida so para quem saiu',
       (SELECT COUNT(*) FROM dim_aluno WHERE (situacao_vinculo = 'ATIVO') <> (id_data_saida IS NULL))
UNION ALL SELECT 'pesos da ponte somam 1 por turma',
       (SELECT COUNT(*) FROM (SELECT id_turma_disciplina FROM vw_turma_professor GROUP BY id_turma_disciplina HAVING ABS(SUM(peso) - 1) > 0.001) x);
