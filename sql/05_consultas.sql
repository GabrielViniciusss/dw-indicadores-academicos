-- Consultas analiticas. O numero segue o documento da entrega.
-- Taxas sobre matriculas com resultado (sem trancamentos), salvo indicacao.
USE dw_academico;

-- C1. Como a taxa de aprovacao evoluiu a cada semestre, por curso?
SELECT d.ano_semestre, c.codigo_curso,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota + f.qtd_aprovacoes_final)
             / SUM(f.qtd_matriculados - f.qtd_trancamentos), 1) AS taxa_aprovacao
FROM fato_professor_disciplina f
JOIN dim_data d ON d.id_data = f.id_data
JOIN dim_curso c ON c.id_curso = f.id_curso
GROUP BY d.ano_semestre, c.codigo_curso
ORDER BY d.ano_semestre, c.codigo_curso;

-- C2. Quais disciplinas mais reprovam?
SELECT di.nome_disciplina, SUM(f.qtd_matriculados) AS matriculados,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / SUM(f.qtd_matriculados - f.qtd_trancamentos), 1) AS taxa_reprovacao
FROM fato_professor_disciplina f
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
GROUP BY di.nome_disciplina
HAVING SUM(f.qtd_matriculados) >= 100
ORDER BY taxa_reprovacao DESC
LIMIT 10;

-- C3. Nas disciplinas criticas, como o resultado das matriculas se divide?
SELECT di.nome_disciplina,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota) / SUM(f.qtd_matriculados), 1) AS aprovado_nota,
       ROUND(100 * SUM(f.qtd_aprovacoes_final) / SUM(f.qtd_matriculados), 1) AS aprovado_final,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota) / SUM(f.qtd_matriculados), 1) AS reprovado_nota,
       ROUND(100 * SUM(f.qtd_reprovacoes_faltas) / SUM(f.qtd_matriculados), 1) AS reprovado_faltas,
       ROUND(100 * SUM(f.qtd_trancamentos) / SUM(f.qtd_matriculados), 1) AS trancado
FROM fato_professor_disciplina f
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
GROUP BY di.nome_disciplina
HAVING SUM(f.qtd_matriculados) >= 100
ORDER BY (SUM(f.qtd_reprovacoes_nota) + SUM(f.qtd_reprovacoes_faltas)) / SUM(f.qtd_matriculados) DESC
LIMIT 8;

-- C4. Como as notas se distribuem nas faixas, por curso?
SELECT c.codigo_curso,
       SUM(f.qtd_nota_0_2_9) AS nota_0_a_2_9, SUM(f.qtd_nota_3_6_9) AS nota_3_a_6_9,
       SUM(f.qtd_nota_7_7_9) AS nota_7_a_7_9, SUM(f.qtd_nota_8_8_9) AS nota_8_a_8_9,
       SUM(f.qtd_nota_9_10) AS nota_9_a_10
FROM fato_professor_disciplina f
JOIN dim_curso c ON c.id_curso = f.id_curso
GROUP BY c.codigo_curso
ORDER BY c.codigo_curso;

-- C5. Em que semestres cada disciplina critica ficou pior?
WITH criticas AS (
  SELECT id_disciplina
  FROM fato_professor_disciplina
  GROUP BY id_disciplina
  HAVING SUM(qtd_matriculados) >= 100
  ORDER BY SUM(qtd_reprovacoes_nota + qtd_reprovacoes_faltas) / SUM(qtd_matriculados - qtd_trancamentos) DESC
  LIMIT 8
)
SELECT di.nome_disciplina, d.ano_semestre,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_reprovacao
FROM fato_professor_disciplina f
JOIN criticas x ON x.id_disciplina = f.id_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY di.nome_disciplina, d.ano_semestre
ORDER BY di.nome_disciplina, d.ano_semestre;

-- C6. Ofertas com mais faltas reprovam mais?
SELECT t.id_turma_disciplina, di.nome_disciplina, d.ano_semestre,
       ROUND(SUM(f.soma_faltas) / NULLIF(SUM(f.qtd_faltas_validas), 0), 2) AS media_faltas,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_reprovacao,
       SUM(f.qtd_matriculados) AS matriculados
FROM fato_professor_disciplina f
JOIN dim_turma_disciplina t ON t.id_turma_disciplina = f.id_turma_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY t.id_turma_disciplina, di.nome_disciplina, d.ano_semestre
HAVING SUM(f.qtd_matriculados) >= 10;

-- C7. Dentro de uma mesma disciplina, como variam os resultados por professor?
SELECT di.nome_disciplina, p.nome_professor, COUNT(DISTINCT f.id_turma_disciplina) AS turmas,
       SUM(f.qtd_matriculados) AS matriculados,
       ROUND(SUM(f.soma_notas_finais) / NULLIF(SUM(f.qtd_notas_validas), 0), 2) AS media_notas,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0), 1) AS taxa_reprovacao
FROM fato_professor_disciplina f
JOIN vw_turma_professor tp ON tp.id_turma_disciplina = f.id_turma_disciplina
JOIN dim_professor p ON p.id_professor = tp.id_professor
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
GROUP BY di.nome_disciplina, p.nome_professor
ORDER BY di.nome_disciplina, taxa_reprovacao DESC;

-- C8. Em qual periodo do aluno as reprovacoes se concentram?
SELECT f.periodo_aluno, COUNT(*) AS matriculas,
       ROUND(100 * SUM(f.situacao_final LIKE 'REPROVADO%')
             / SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 1) AS taxa_reprovacao
FROM fato_professor_aluno f
WHERE f.periodo_aluno <= 12
GROUP BY f.periodo_aluno
ORDER BY f.periodo_aluno;

-- C9. O que aconteceu com cada coorte de ingresso?
SELECT t.ano_semestre_ingresso, COUNT(*) AS ingressantes,
       ROUND(100 * SUM(a.situacao_vinculo = 'CONCLUIDO') / COUNT(*), 1) AS concluiu,
       ROUND(100 * SUM(a.situacao_vinculo = 'ATIVO') / COUNT(*), 1) AS ativo,
       ROUND(100 * SUM(a.situacao_vinculo = 'EVADIDO') / COUNT(*), 1) AS evadiu
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
WHERE t.ano_ingresso >= 2018 -- coortes anteriores so tem os sobreviventes de 2018
GROUP BY t.ano_semestre_ingresso
ORDER BY t.ano_semestre_ingresso;

-- C10. Desempenho e evasao mudam com o tipo de cota e a faixa economica?
SELECT COALESCE(a.tipo_cota, 'Sem cota (outras formas)') AS tipo_cota, a.faixa_economica,
       COUNT(DISTINCT a.id_aluno) AS alunos,
       ROUND(100 * SUM(f.situacao_final LIKE 'REPROVADO%')
             / SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 1) AS taxa_reprovacao,
       ROUND(100 * COUNT(DISTINCT CASE WHEN a.situacao_vinculo = 'EVADIDO' THEN a.id_aluno END)
             / COUNT(DISTINCT a.id_aluno), 1) AS taxa_evasao
FROM fato_professor_aluno f
JOIN dim_aluno a ON a.id_aluno = f.id_aluno
GROUP BY tipo_cota, a.faixa_economica
ORDER BY tipo_cota, a.faixa_economica;

-- C11. O tempo de conclusao supera o previsto em cada curso?
SELECT c.codigo_curso, c.semestres_previstos, COUNT(*) AS concluintes,
       ROUND(AVG((ds.ano * 2 + ds.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1), 1) AS media_semestres
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
JOIN dim_data ds ON ds.id_data = a.id_data_saida
WHERE a.situacao_vinculo = 'CONCLUIDO'
GROUP BY c.codigo_curso, c.semestres_previstos
ORDER BY c.codigo_curso;

-- C12. A chance de aprovacao muda a cada nova tentativa?
SELECT CASE WHEN f.qtd_tentativas >= 3 THEN '3 ou mais' ELSE CAST(f.qtd_tentativas AS CHAR) END AS tentativa,
       COUNT(*) AS matriculas,
       ROUND(100 * SUM(f.situacao_final LIKE 'APROVADO%')
             / SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 1) AS taxa_aprovacao
FROM fato_professor_aluno f
GROUP BY tentativa
ORDER BY tentativa;

-- C13. Bolsistas aprovam mais do que nao bolsistas ao longo do tempo?
SELECT d.ano_semestre,
       ROUND(100 * SUM(f.qtd_bolsistas_aprovados_nota + f.qtd_bolsistas_aprovados_final)
             / NULLIF(SUM(f.qtd_bolsistas_aprovados_nota + f.qtd_bolsistas_aprovados_final
                          + f.qtd_bolsistas_reprovados_nota + f.qtd_bolsistas_reprovados_faltas), 0), 1) AS bolsistas,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota + f.qtd_aprovacoes_final
                       - f.qtd_bolsistas_aprovados_nota - f.qtd_bolsistas_aprovados_final)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos
                          - f.qtd_bolsistas_aprovados_nota - f.qtd_bolsistas_aprovados_final
                          - f.qtd_bolsistas_reprovados_nota - f.qtd_bolsistas_reprovados_faltas), 0), 1) AS nao_bolsistas
FROM fato_professor_disciplina f
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY d.ano_semestre
ORDER BY d.ano_semestre;
