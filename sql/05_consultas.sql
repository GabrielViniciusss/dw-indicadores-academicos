-- Consultas da entrega. O numero segue docs/entrega_03_11.pdf.
-- Taxas sobre matriculas com resultado (sem trancamentos), salvo indicacao.
USE dw_academico;

-- C1. Como a taxa de aprovacao de cada disciplina critica mudou de um semestre para outro?
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

-- C2. Em cada semestre, quais sao as 10 disciplinas com maior taxa de reprovacao, e quanto vem de nota e de falta?
WITH por_semestre AS (
  SELECT f.id_data, f.id_disciplina,
         100 * SUM(f.qtd_reprovacoes_nota) / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0) AS por_nota,
         100 * SUM(f.qtd_reprovacoes_faltas) / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0) AS por_falta
  FROM fato_professor_disciplina f
  GROUP BY f.id_data, f.id_disciplina
),
ranking AS (
  SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p.id_data ORDER BY p.por_nota + p.por_falta DESC) AS posicao
  FROM por_semestre p
)
SELECT d.ano_semestre, r.posicao, di.nome_disciplina, ROUND(r.por_nota, 1) AS reprovacao_nota,
       ROUND(r.por_falta, 1) AS reprovacao_falta, ROUND(r.por_nota + r.por_falta, 1) AS taxa_reprovacao
FROM ranking r
JOIN dim_data d ON d.id_data = r.id_data
JOIN dim_disciplina di ON di.id_disciplina = r.id_disciplina
WHERE r.posicao <= 10
ORDER BY d.ano_semestre, r.posicao;

-- C3. Em cada semestre, como as matriculas das disciplinas criticas se dividem entre as situacoes?
WITH criticas AS (
  SELECT id_disciplina FROM fato_professor_disciplina GROUP BY id_disciplina
  ORDER BY SUM(qtd_reprovacoes_nota + qtd_reprovacoes_faltas) / SUM(qtd_matriculados - qtd_trancamentos) DESC
  LIMIT 10
)
SELECT d.ano_semestre, di.nome_disciplina,
       ROUND(100 * SUM(f.qtd_aprovacoes_nota) / SUM(f.qtd_matriculados), 1) AS aprovado_nota,
       ROUND(100 * SUM(f.qtd_aprovacoes_final) / SUM(f.qtd_matriculados), 1) AS aprovado_final,
       ROUND(100 * SUM(f.qtd_reprovacoes_nota) / SUM(f.qtd_matriculados), 1) AS reprovado_nota,
       ROUND(100 * SUM(f.qtd_reprovacoes_faltas) / SUM(f.qtd_matriculados), 1) AS reprovado_falta,
       ROUND(100 * SUM(f.qtd_trancamentos) / SUM(f.qtd_matriculados), 1) AS trancado
FROM fato_professor_disciplina f
JOIN criticas x ON x.id_disciplina = f.id_disciplina
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY d.ano_semestre, di.nome_disciplina
ORDER BY d.ano_semestre, di.nome_disciplina;

-- C4. Em um curso, quais professores tem taxa de reprovacao mais distante da media das disciplinas que ministram?
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

-- C5. Como a taxa de reprovacao das disciplinas criticas evoluiu por semestre e periodo curricular?
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

-- C6. Em cada oferta de disciplina, como a taxa de reprovacao se relaciona com a media de faltas?
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

-- C7. Em uma mesma disciplina, qual e a relacao da aprovacao, da nota media e do numero de alunos com professores e turmas?
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

-- C8. Como as reprovacoes por nota e por falta se distribuem conforme o periodo do aluno, em cada semestre?
SELECT d.ano_semestre, f.periodo_aluno,
       SUM(f.situacao_final = 'REPROVADO_NOTA') AS reprovacoes_nota,
       SUM(f.situacao_final = 'REPROVADO_FALTAS') AS reprovacoes_falta,
       COUNT(*) AS matriculas
FROM fato_professor_aluno f
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY d.ano_semestre, f.periodo_aluno
ORDER BY d.ano_semestre, f.periodo_aluno;

-- C9. Em cada turma de ingresso, qual e a proporcao de alunos que concluiram, que seguem ativos e que evadiram?
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

-- C10. Em cada turma de ingresso, como reprovacao e evasao variam entre tipos de cota e faixas economicas?
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

-- C11. Em cada turma de ingresso, quanto o tempo de conclusao se afasta do prazo previsto do curso?
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

-- C12. Em cada disciplina, como a taxa de aprovacao muda da 1a para a 2a tentativa, e para a 3a ou mais?
SELECT di.nome_disciplina, c.codigo_curso, d.ano_semestre,
       CASE WHEN f.qtd_tentativas >= 3 THEN '3 ou mais' ELSE CAST(f.qtd_tentativas AS CHAR) END AS tentativa,
       COUNT(*) AS matriculas,
       ROUND(100 * SUM(f.situacao_final LIKE 'APROVADO%')
             / NULLIF(SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS taxa_aprovacao
FROM fato_professor_aluno f
JOIN dim_disciplina di ON di.id_disciplina = f.id_disciplina
JOIN dim_curso c ON c.id_curso = f.id_curso
JOIN dim_data d ON d.id_data = f.id_data
GROUP BY di.nome_disciplina, c.codigo_curso, d.ano_semestre, tentativa
ORDER BY di.nome_disciplina, c.codigo_curso, d.ano_semestre, tentativa;

-- C13. Como reprovacao e evasao de beneficiarios se comparam com as de nao beneficiarios, em cada curso e semestre?
WITH alunos_semestre AS (
  -- evasao medida por semestre: quem evadiu ao final do semestre em que estava matriculado
  SELECT f.id_curso, f.id_data, f.id_aluno, MAX(f.bolsista_no_semestre) AS beneficiario,
         SUM(f.situacao_final LIKE 'REPROVADO%') AS reprovacoes,
         SUM(f.situacao_final <> 'TRANCADO_DISCIPLINA') AS com_resultado,
         MAX(a.situacao_vinculo = 'EVADIDO' AND a.id_data_saida = f.id_data) AS evadiu
  FROM fato_professor_aluno f
  JOIN dim_aluno a ON a.id_aluno = f.id_aluno
  GROUP BY f.id_curso, f.id_data, f.id_aluno
)
SELECT c.codigo_curso, d.ano_semestre,
       CASE WHEN x.beneficiario = 1 THEN 'Beneficiario' ELSE 'Nao beneficiario' END AS grupo,
       COUNT(*) AS alunos,
       ROUND(100 * SUM(x.reprovacoes) / NULLIF(SUM(x.com_resultado), 0), 1) AS taxa_reprovacao,
       ROUND(100 * SUM(x.evadiu) / COUNT(*), 1) AS taxa_evasao
FROM alunos_semestre x
JOIN dim_curso c ON c.id_curso = x.id_curso
JOIN dim_data d ON d.id_data = x.id_data
GROUP BY c.codigo_curso, d.ano_semestre, grupo
ORDER BY c.codigo_curso, d.ano_semestre, grupo;
