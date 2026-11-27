-- Deriva o snapshot periodico do vinculo de dim_aluno e dim_turma_aluno, sem sortear nada novo.
-- Roda depois de 01 a 04 e antes de 06_validacao.sql (ver scripts/carregar.sh).
USE dw_academico;
DELETE FROM fato_vinculo_semestre;

INSERT INTO fato_vinculo_semestre
SELECT ROW_NUMBER() OVER (ORDER BY a.id_aluno, d.id_data),
       a.id_aluno, a.id_turma_aluno, t.id_curso, d.id_data,
       CASE WHEN a.id_data_saida IS NULL OR d.id_data < a.id_data_saida THEN 'ATIVO' ELSE a.situacao_vinculo END,
       (d.ano * 2 + d.semestre) - (t.ano_ingresso * 2 + t.semestre_ingresso) + 1,
       a.id_data_saida IS NULL OR d.id_data < a.id_data_saida,
       d.id_data = a.id_data_saida AND a.situacao_vinculo = 'CONCLUIDO',
       d.id_data = a.id_data_saida AND a.situacao_vinculo = 'EVADIDO'
FROM dim_aluno a
JOIN dim_turma_aluno t ON t.id_turma_aluno = a.id_turma_aluno
-- dim_data comeca em 2018.1: coortes anteriores entram a partir dali
JOIN dim_data d
  ON d.id_data >= t.ano_ingresso * 10 + t.semestre_ingresso
 AND (a.id_data_saida IS NULL OR d.id_data <= a.id_data_saida);
