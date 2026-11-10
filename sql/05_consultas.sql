-- Consultas da entrega. A numeracao segue docs/entrega_05_11.pdf.
-- Taxas sobre matriculas com resultado (sem trancamentos), salvo indicacao.
USE dw_academico;

-- C1. Em cada semestre, quais sao as 10 disciplinas com maior taxa de reprovacao, separando reprovacao por nota e por falta?
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

-- C2. Em cada turma de ingresso, qual e a proporcao de alunos que concluiram, continuam ativos ou evadiram?
SELECT c.codigo_curso, t.ano_semestre_ingresso, COUNT(*) AS ingressantes,
       ROUND(100 * SUM(a.situacao_vinculo = 'CONCLUIDO') / COUNT(*), 1) AS concluiu,
       ROUND(100 * SUM(a.situacao_vinculo = 'ATIVO') / COUNT(*), 1) AS ativo,
       ROUND(100 * SUM(a.situacao_vinculo = 'EVADIDO') / COUNT(*), 1) AS evadiu
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
WHERE t.ano_ingresso >= 2018 -- turmas anteriores so tem os alunos que ainda estavam no curso em 2018
GROUP BY c.codigo_curso, t.ano_semestre_ingresso
ORDER BY c.codigo_curso, t.ano_semestre_ingresso;

-- C3. Entre alunos matriculados em disciplinas, como a taxa de reprovacao de beneficiarios da assistencia estudantil se compara a de nao beneficiarios ao longo dos semestres?
SELECT c.codigo_curso, d.ano_semestre,
       CASE WHEN f.bolsista_no_semestre = 1 THEN 'Beneficiario' ELSE 'Nao beneficiario' END AS grupo,
       SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA') AS matriculas,
       ROUND(100 * SUM(f.situacao_final LIKE 'REPROVADO%')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS taxa_reprovacao
FROM fato_professor_aluno f
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, d.ano_semestre, grupo
ORDER BY c.codigo_curso, d.ano_semestre, grupo;

-- C4. Como varia a taxa de reprovacao por nota e por falta conforme os semestres transcorridos desde o ingresso do aluno?
SELECT c.codigo_curso, d.ano_semestre, t.ano_semestre_ingresso,
       CASE WHEN f.periodo_aluno >= 9 THEN '9+' ELSE CAST(f.periodo_aluno AS CHAR) END AS periodo,
       SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA') AS matriculas,
       ROUND(100 * SUM(f.situacao_final = 'REPROVADO_NOTA')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS reprovacao_nota,
       ROUND(100 * SUM(f.situacao_final = 'REPROVADO_FALTAS')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS reprovacao_falta
FROM fato_professor_aluno f
JOIN dim_aluno a ON a.id_aluno = f.id_aluno
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY c.codigo_curso, d.ano_semestre, t.ano_semestre_ingresso, periodo
ORDER BY c.codigo_curso, d.ano_semestre, t.ano_semestre_ingresso, periodo;

-- C5. Quais disciplinas apresentam maior proporcao de alunos que reprovaram duas ou mais vezes na mesma disciplina?
WITH historico AS (
  -- uma linha por aluno, disciplina e curso, somando as reprovacoes de 2018.1 a 2025.2
  SELECT f.id_curso, f.id_disciplina, f.id_aluno,
         SUM(f.situacao_final LIKE 'REPROVADO%') AS reprovacoes
  FROM fato_professor_aluno f
  WHERE f.situacao_final <> 'TRANCADO_DISCIPLINA'
  GROUP BY f.id_curso, f.id_disciplina, f.id_aluno
)
SELECT c.codigo_curso, di.nome_disciplina, COUNT(*) AS alunos,
       SUM(h.reprovacoes >= 2) AS alunos_afetados,
       ROUND(100 * SUM(h.reprovacoes >= 2) / COUNT(*), 1) AS taxa_recorrente
FROM historico h
JOIN dim_curso c ON c.id_curso = h.id_curso
JOIN dim_disciplina di ON di.id_disciplina = h.id_disciplina
GROUP BY c.codigo_curso, di.nome_disciplina
ORDER BY c.codigo_curso, taxa_recorrente DESC, di.nome_disciplina;

-- C6. Como a taxa de aprovacao das disciplinas criticas evolui de um semestre para outro?
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

-- C7. Como as matriculas nas disciplinas criticas se distribuem entre aprovacao por nota, aprovacao na final, reprovacao por nota, reprovacao por falta e trancamento?
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

-- C8. Em cada turma de ingresso, como reprovacao e evasao variam simultaneamente por tipo de cota e faixa economica?
SELECT c.codigo_curso, t.ano_semestre_ingresso, COALESCE(a.tipo_cota, 'Outras formas de ingresso') AS tipo_cota,
       a.faixa_economica, COUNT(DISTINCT a.id_aluno) AS alunos,
       ROUND(100 * SUM(f.situacao_final LIKE 'REPROVADO%')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS taxa_reprovacao,
       ROUND(100 * COUNT(DISTINCT CASE WHEN a.situacao_vinculo = 'EVADIDO' THEN a.id_aluno END)
             / COUNT(DISTINCT a.id_aluno), 1) AS taxa_evasao
FROM fato_professor_aluno f
JOIN dim_aluno a ON a.id_aluno = f.id_aluno
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
WHERE t.ano_ingresso >= 2018
GROUP BY c.codigo_curso, t.ano_semestre_ingresso, tipo_cota, a.faixa_economica
ORDER BY c.codigo_curso, t.ano_semestre_ingresso, tipo_cota, a.faixa_economica;

-- C9. Nas ofertas de disciplina, como a taxa de reprovacao se relaciona com a media de faltas?
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

-- C10. Quais turmas tiveram taxa de reprovacao muito acima ou abaixo do historico da mesma disciplina no curso?
WITH oferta AS (
  SELECT f.id_turma_disciplina, f.id_curso, f.id_disciplina, f.id_data,
         f.qtd_matriculados - f.qtd_trancamentos AS matriculas,
         f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas AS reprovacoes
  FROM fato_professor_disciplina f
),
comparada AS (
  -- historico: semestres anteriores da mesma disciplina e curso, ponderado pelas matriculas
  SELECT o.*,
         (SELECT 100 * SUM(h.reprovacoes) / NULLIF(SUM(h.matriculas), 0)
          FROM oferta h
          WHERE h.id_curso = o.id_curso AND h.id_disciplina = o.id_disciplina AND h.id_data < o.id_data) AS taxa_historica
  FROM oferta o
  WHERE o.matriculas >= 10 -- turmas menores oscilam demais
)
SELECT d.ano_semestre, c.codigo_curso, di.nome_disciplina, t.codigo_turma, x.matriculas,
       ROUND(100 * x.reprovacoes / x.matriculas, 1) AS taxa_reprovacao,
       ROUND(x.taxa_historica, 1) AS taxa_historica,
       ROUND(100 * x.reprovacoes / x.matriculas - x.taxa_historica, 1) AS diferenca_pontos
FROM comparada x
JOIN dim_turma_disciplina t ON t.id_turma_disciplina = x.id_turma_disciplina
JOIN dim_disciplina di ON di.id_disciplina = x.id_disciplina
JOIN dim_data d ON d.id_data = x.id_data
JOIN dim_curso c ON c.id_curso = x.id_curso
WHERE x.taxa_historica IS NOT NULL
ORDER BY d.ano_semestre, c.codigo_curso, ABS(diferenca_pontos) DESC, di.nome_disciplina, t.codigo_turma;

-- C11. Quanto o tempo de conclusao de cada turma de ingresso se afasta do prazo previsto do curso?
SELECT c.codigo_curso, t.ano_semestre_ingresso, c.semestres_previstos, COUNT(*) AS concluintes,
       ROUND(AVG((ds.ano * 2 + ds.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1), 1) AS media_semestres,
       ROUND(AVG((ds.ano * 2 + ds.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1) - c.semestres_previstos, 1) AS diferenca_semestres
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
JOIN dim_curso c ON c.id_curso = t.id_curso
JOIN dim_data ds ON ds.id_data = a.id_data_saida
WHERE a.situacao_vinculo = 'CONCLUIDO' AND t.ano_ingresso >= 2018
GROUP BY c.codigo_curso, t.ano_semestre_ingresso, c.semestres_previstos
ORDER BY c.codigo_curso, t.ano_semestre_ingresso;

-- C12. Na mesma disciplina e semestre, como variam aprovacao, nota media e tamanho das turmas associadas a diferentes professores?
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
