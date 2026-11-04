-- Consultas de apoio a decisao. A descricao completa de cada uma esta em docs/entrega_03_11.pdf.
-- Ultimo semestre dos dados: 2025.2 (id_data = 20252). Numero do semestre: ano * 2 + semestre.
USE dw_academico;

-- C1. Monitoria: em quais disciplinas o reforco atinge mais alunos?
WITH agregada AS (
  SELECT id_disciplina, SUM(qtd_matriculados) AS matriculas,
         SUM(qtd_matriculados - qtd_trancamentos) AS com_resultado,
         SUM(qtd_reprovacoes_nota) AS por_nota, SUM(qtd_reprovacoes_faltas) AS por_falta
  FROM fato_professor_disciplina
  WHERE id_data >= 20231
  GROUP BY id_disciplina
),
repetentes AS (
  SELECT id_disciplina, COUNT(*) AS matriculas_repetentes
  FROM fato_professor_aluno
  WHERE id_data >= 20231 AND qtd_tentativas >= 2
  GROUP BY id_disciplina
)
SELECT d.nome_disciplina, a.matriculas, a.por_nota + a.por_falta AS reprovacoes,
       ROUND(100 * (a.por_nota + a.por_falta) / a.com_resultado, 1) AS taxa_reprovacao,
       ROUND(100 * a.por_falta / NULLIF(a.por_nota + a.por_falta, 0), 1) AS pct_reprovacoes_por_falta,
       ROUND(100 * COALESCE(r.matriculas_repetentes, 0) / a.matriculas, 1) AS pct_matriculas_repetentes
FROM agregada a
JOIN dim_disciplina d ON d.id_disciplina = a.id_disciplina
LEFT JOIN repetentes r ON r.id_disciplina = a.id_disciplina
WHERE a.matriculas >= 100
ORDER BY reprovacoes DESC;

-- C2. Oferta: quantas turmas extras cada disciplina precisa para absorver quem ficou para tras?
WITH historico AS (
  SELECT f.id_aluno, f.id_disciplina, f.id_curso,
         MAX(f.situacao_final LIKE 'APROVADO%') AS ja_aprovado,
         SUM(f.situacao_final LIKE 'REPROVADO%') AS reprovacoes
  FROM fato_professor_aluno f
  JOIN dim_aluno a ON a.id_aluno = f.id_aluno
  WHERE a.situacao_vinculo = 'ATIVO'
  GROUP BY f.id_aluno, f.id_disciplina, f.id_curso
),
pendentes AS (
  SELECT h.id_disciplina,
         COUNT(*) AS alunos_pendentes,
         SUM(h.reprovacoes >= 2) AS pendentes_2_ou_mais_reprovacoes,
         SUM(c.codigo_curso = 'CC') AS pendentes_cc,
         SUM(c.codigo_curso = 'EC') AS pendentes_ec,
         SUM(c.codigo_curso = 'SI') AS pendentes_si
  FROM historico h
  JOIN dim_curso c ON c.id_curso = h.id_curso
  WHERE h.ja_aprovado = 0
  GROUP BY h.id_disciplina
),
oferta AS (
  SELECT id_disciplina, COUNT(DISTINCT id_turma_disciplina) AS turmas,
         SUM(qtd_matriculados) / COUNT(DISTINCT id_turma_disciplina) AS alunos_por_turma
  FROM fato_professor_disciplina
  WHERE id_data IN (20251, 20252)
  GROUP BY id_disciplina
)
SELECT d.nome_disciplina, p.alunos_pendentes, p.pendentes_cc, p.pendentes_ec, p.pendentes_si,
       p.pendentes_2_ou_mais_reprovacoes, ROUND(o.alunos_por_turma, 1) AS alunos_por_turma,
       ROUND(p.alunos_pendentes / o.alunos_por_turma, 1) AS turmas_equivalentes
FROM pendentes p
JOIN dim_disciplina d ON d.id_disciplina = p.id_disciplina
LEFT JOIN oferta o ON o.id_disciplina = p.id_disciplina
ORDER BY p.alunos_pendentes DESC
LIMIT 10;

-- C3. Acompanhamento: a partir de quantas reprovacoes no primeiro ano vale acionar a tutoria?
WITH primeiro_ano AS (
  SELECT id_aluno, SUM(situacao_final LIKE 'REPROVADO%') AS reprovacoes
  FROM fato_professor_aluno
  WHERE periodo_aluno <= 2
  GROUP BY id_aluno
),
base AS (
  -- so entra quem chegou ao fim do 2o semestre sem evadir: e quando a decisao seria tomada
  SELECT a.id_aluno, a.situacao_vinculo, t.id_curso
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  LEFT JOIN dim_data ds ON ds.id_data = a.id_data_saida
  WHERE t.ano_ingresso * 2 + t.semestre_ingresso BETWEEN 2018 * 2 + 1 AND 2023 * 2 + 2
    AND NOT (a.situacao_vinculo = 'EVADIDO'
             AND ds.ano * 2 + ds.semestre - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1 <= 2)
)
SELECT c.codigo_curso,
       CASE WHEN p.reprovacoes >= 4 THEN '4 ou mais' ELSE CAST(p.reprovacoes AS CHAR) END AS reprovacoes_primeiro_ano,
       COUNT(*) AS alunos,
       SUM(b.situacao_vinculo = 'EVADIDO') AS evadiram_depois,
       ROUND(100 * SUM(b.situacao_vinculo = 'EVADIDO') / COUNT(*), 1) AS taxa_evasao_posterior
FROM base b
JOIN primeiro_ano p ON p.id_aluno = b.id_aluno
JOIN dim_curso c ON c.id_curso = b.id_curso
GROUP BY c.codigo_curso, reprovacoes_primeiro_ano
ORDER BY c.codigo_curso, reprovacoes_primeiro_ano;

-- C4. Prevencao: ate que semestre do curso a evasao se acumula, e quando ela perde forca?
WITH RECURSIVE semestres (n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM semestres WHERE n < 12
),
base AS (
  -- so turmas com 12 semestres de historico, para todos os pontos terem os mesmos alunos
  SELECT c.codigo_curso,
         CASE WHEN a.situacao_vinculo = 'EVADIDO'
              THEN ds.ano * 2 + ds.semestre - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1 END AS semestre_evasao
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  JOIN dim_curso c ON c.id_curso = t.id_curso
  LEFT JOIN dim_data ds ON ds.id_data = a.id_data_saida
  WHERE t.ano_ingresso * 2 + t.semestre_ingresso BETWEEN 2018 * 2 + 1 AND 2020 * 2 + 1
)
SELECT b.codigo_curso, s.n AS semestre_do_curso, COUNT(*) AS ingressantes,
       SUM(COALESCE(b.semestre_evasao <= s.n, 0)) AS evadidos_acumulados,
       ROUND(100 * SUM(COALESCE(b.semestre_evasao <= s.n, 0)) / COUNT(*), 1) AS evasao_acumulada
FROM base b
CROSS JOIN semestres s
GROUP BY b.codigo_curso, s.n
ORDER BY b.codigo_curso, s.n;

-- C5. Integralizacao: quantos alunos ativos ja passaram do prazo em cada curso, e por quanto?
WITH ativos AS (
  SELECT a.id_aluno, c.codigo_curso,
         (2025 * 2 + 2) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1 - c.semestres_previstos AS atraso
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  JOIN dim_curso c ON c.id_curso = t.id_curso
  WHERE a.situacao_vinculo = 'ATIVO'
),
carga AS (
  SELECT id_aluno, SUM(ch_adquirida) AS ch
  FROM fato_professor_aluno
  GROUP BY id_aluno
)
SELECT x.codigo_curso,
       CASE WHEN x.atraso <= 0 THEN '0. No prazo'
            WHEN x.atraso <= 2 THEN '1. Ate 2 semestres de atraso'
            WHEN x.atraso <= 4 THEN '2. De 3 a 4 semestres de atraso'
            ELSE '3. 5 semestres de atraso ou mais' END AS situacao_prazo,
       COUNT(*) AS alunos_ativos,
       ROUND(AVG(k.ch)) AS carga_horaria_media_cursada
FROM ativos x
JOIN carga k ON k.id_aluno = x.id_aluno
GROUP BY x.codigo_curso, situacao_prazo
ORDER BY x.codigo_curso, situacao_prazo;

-- C6. Assistencia estudantil: em quais faixas economicas o beneficio deve ser priorizado?
WITH evasao AS (
  SELECT a.faixa_economica, COUNT(*) AS alunos,
         ROUND(100 * SUM(a.situacao_vinculo = 'EVADIDO') / COUNT(*), 1) AS taxa_evasao
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  WHERE t.ano_ingresso * 2 + t.semestre_ingresso BETWEEN 2018 * 2 + 1 AND 2023 * 2 + 2
  GROUP BY a.faixa_economica
),
desempenho AS (
  SELECT a.faixa_economica,
         ROUND(100 * AVG(f.bolsista_no_semestre), 1) AS cobertura_beneficio,
         ROUND(100 * SUM(f.bolsista_no_semestre AND f.situacao_final LIKE 'APROVADO%')
               / NULLIF(SUM(f.bolsista_no_semestre AND f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS aprovacao_com_beneficio,
         ROUND(100 * SUM(NOT f.bolsista_no_semestre AND f.situacao_final LIKE 'APROVADO%')
               / NULLIF(SUM(NOT f.bolsista_no_semestre AND f.situacao_final <> 'TRANCADO_DISCIPLINA'), 0), 1) AS aprovacao_sem_beneficio
  FROM fato_professor_aluno f
  JOIN dim_aluno a ON a.id_aluno = f.id_aluno
  WHERE f.periodo_aluno >= 2
  GROUP BY a.faixa_economica
)
SELECT e.faixa_economica, e.alunos, e.taxa_evasao, d.cobertura_beneficio,
       d.aprovacao_com_beneficio, d.aprovacao_sem_beneficio
FROM evasao e
JOIN desempenho d ON d.faixa_economica = e.faixa_economica
ORDER BY FIELD(e.faixa_economica, 'Ate 1,5 SM', '1,5 a 3 SM', '3 a 5 SM', 'Acima de 5 SM');

-- C7. Coordenacao pedagogica: em quais disciplinas vale alinhar criterios entre professores?
WITH por_professor AS (
  SELECT f.id_disciplina, tp.id_professor, SUM(f.qtd_matriculados) AS matriculas,
         SUM(f.qtd_matriculados - f.qtd_trancamentos) AS com_resultado,
         SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas) AS reprovacoes,
         100 * SUM(f.qtd_reprovacoes_nota + f.qtd_reprovacoes_faltas)
             / NULLIF(SUM(f.qtd_matriculados - f.qtd_trancamentos), 0) AS taxa
  FROM fato_professor_disciplina f
  JOIN vw_turma_professor tp ON tp.id_turma_disciplina = f.id_turma_disciplina
  WHERE f.id_data >= 20231
  GROUP BY f.id_disciplina, tp.id_professor
  HAVING SUM(f.qtd_matriculados) >= 30
)
SELECT d.nome_disciplina, COUNT(*) AS professores,
       ROUND(MIN(p.taxa), 1) AS menor_taxa_reprovacao,
       ROUND(MAX(p.taxa), 1) AS maior_taxa_reprovacao,
       ROUND(MAX(p.taxa) - MIN(p.taxa), 1) AS diferenca_pontos
FROM por_professor p
JOIN dim_disciplina d ON d.id_disciplina = p.id_disciplina
GROUP BY d.nome_disciplina
HAVING COUNT(*) >= 2
ORDER BY diferenca_pontos DESC
LIMIT 10;

-- C8. Grade de horarios: quais horarios concentram mais faltas e reprovacao por falta do que o esperado?
WITH base AS (
  SELECT f.id_disciplina, t.horario, f.id_turma_disciplina, f.qtd_matriculados, f.qtd_trancamentos,
         f.qtd_reprovacoes_faltas, f.soma_faltas, f.qtd_faltas_validas,
         f.qtd_matriculados - f.qtd_trancamentos AS com_resultado
  FROM fato_professor_disciplina f
  JOIN dim_turma_disciplina t ON t.id_turma_disciplina = f.id_turma_disciplina
  WHERE f.id_data >= 20231
),
por_disciplina AS (
  SELECT id_disciplina, SUM(qtd_reprovacoes_faltas) / NULLIF(SUM(com_resultado), 0) AS taxa_disciplina
  FROM base
  GROUP BY id_disciplina
)
SELECT b.horario, COUNT(DISTINCT b.id_turma_disciplina) AS turmas, SUM(b.qtd_matriculados) AS matriculas,
       ROUND(SUM(b.soma_faltas) / NULLIF(SUM(b.qtd_faltas_validas), 0), 2) AS media_faltas,
       ROUND(100 * SUM(b.qtd_trancamentos) / SUM(b.qtd_matriculados), 1) AS pct_trancamento,
       ROUND(100 * SUM(b.qtd_reprovacoes_faltas) / SUM(b.com_resultado), 1) AS reprovacao_falta,
       ROUND(100 * SUM(b.com_resultado * d.taxa_disciplina) / SUM(b.com_resultado), 1) AS reprovacao_falta_esperada,
       ROUND(100 * (SUM(b.qtd_reprovacoes_faltas) - SUM(b.com_resultado * d.taxa_disciplina)) / SUM(b.com_resultado), 1) AS diferenca_pontos
FROM base b
JOIN por_disciplina d ON d.id_disciplina = b.id_disciplina
GROUP BY b.horario
ORDER BY diferenca_pontos DESC;

-- C9. Nivelamento: quais grupos de ingresso chegam ao 2o ano com mais dificuldade?
WITH alunos AS (
  SELECT a.id_aluno, COALESCE(a.tipo_cota, 'Outras formas de ingresso') AS grupo_ingresso,
         a.situacao_vinculo = 'EVADIDO'
         AND ds.ano * 2 + ds.semestre - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1 <= 4 AS evadiu_ate_4
  FROM dim_aluno a
  JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
  LEFT JOIN dim_data ds ON ds.id_data = a.id_data_saida
  WHERE t.ano_ingresso * 2 + t.semestre_ingresso BETWEEN 2018 * 2 + 1 AND 2023 * 2 + 2
),
primeiro_ano AS (
  SELECT id_aluno, SUM(situacao_final LIKE 'REPROVADO%') AS reprovacoes,
         SUM(situacao_final <> 'TRANCADO_DISCIPLINA') AS com_resultado, SUM(ch_adquirida) AS ch
  FROM fato_professor_aluno
  WHERE periodo_aluno <= 2
  GROUP BY id_aluno
)
SELECT x.grupo_ingresso, COUNT(*) AS alunos,
       ROUND(100 * SUM(p.reprovacoes) / SUM(p.com_resultado), 1) AS reprovacao_primeiro_ano,
       ROUND(AVG(p.ch)) AS carga_horaria_media_primeiro_ano,
       ROUND(100 * SUM(COALESCE(x.evadiu_ate_4, 0)) / COUNT(*), 1) AS evasao_ate_4o_semestre
FROM alunos x
JOIN primeiro_ano p ON p.id_aluno = x.id_aluno
GROUP BY x.grupo_ingresso
ORDER BY alunos DESC;

-- C10. Tipo de reforco: em quais disciplinas as notas ficam mais abaixo de 7, e em que faixa?
SELECT d.nome_disciplina, SUM(f.qtd_matriculados) AS matriculas,
       ROUND(SUM(f.soma_notas_finais) / SUM(f.qtd_notas_validas), 2) AS media_notas,
       ROUND(100 * SUM(f.qtd_nota_0_2_9) / SUM(f.qtd_notas_validas), 1) AS pct_abaixo_de_3,
       ROUND(100 * SUM(f.qtd_nota_3_6_9) / SUM(f.qtd_notas_validas), 1) AS pct_3_a_6_99,
       ROUND(100 * SUM(f.qtd_nota_7_7_9 + f.qtd_nota_8_8_9 + f.qtd_nota_9_10) / SUM(f.qtd_notas_validas), 1) AS pct_7_ou_mais,
       ROUND(100 * SUM(f.qtd_aprovacoes_final) / NULLIF(SUM(f.qtd_aprovacoes_nota + f.qtd_aprovacoes_final), 0), 1) AS pct_aprovados_na_final
FROM fato_professor_disciplina f
JOIN dim_disciplina d ON d.id_disciplina = f.id_disciplina
WHERE f.id_data >= 20231
GROUP BY d.nome_disciplina
HAVING SUM(f.qtd_matriculados) >= 100
ORDER BY pct_7_ou_mais ASC
LIMIT 10;
