-- Esquemas PDFs e PDFs 2 unificados, com dimensoes conformadas.
-- [AJUSTE] marca o que foi acrescentado em relacao aos diagramas do DrawSQL.
DROP DATABASE IF EXISTS dw_academico;
CREATE DATABASE dw_academico CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE dw_academico;

CREATE TABLE dim_data (
  id_data BIGINT PRIMARY KEY,
  ano SMALLINT,
  semestre SMALLINT,
  ano_semestre VARCHAR(6) UNIQUE
);

CREATE TABLE dim_curso (
  id_curso BIGINT PRIMARY KEY,
  codigo_curso VARCHAR(30),
  nome_curso VARCHAR(160),
  departamento VARCHAR(120),
  centro VARCHAR(120),
  campus VARCHAR(120),
  semestres_previstos SMALLINT -- [AJUSTE] prazo do curso, base da consulta C11
);

CREATE TABLE dim_disciplina (
  id_disciplina BIGINT PRIMARY KEY,
  codigo_disciplina VARCHAR(30),
  nome_disciplina VARCHAR(160),
  carga_horaria INT,
  creditos INT
);

-- [AJUSTE] periodo curricular da disciplina em cada curso, base da consulta C5
CREATE TABLE curso_disciplina (
  id_curso BIGINT NOT NULL,
  id_disciplina BIGINT NOT NULL,
  periodo_curricular SMALLINT NOT NULL,
  PRIMARY KEY (id_curso, id_disciplina),
  FOREIGN KEY (id_curso) REFERENCES dim_curso (id_curso),
  FOREIGN KEY (id_disciplina) REFERENCES dim_disciplina (id_disciplina)
);

CREATE TABLE dim_professor (
  id_professor BIGINT PRIMARY KEY,
  matricula_professor VARCHAR(30),
  nome_professor VARCHAR(160)
);

CREATE TABLE dim_turma_aluno (
  id_turma_aluno BIGINT PRIMARY KEY,
  id_curso BIGINT NOT NULL,
  ano_ingresso SMALLINT,
  semestre_ingresso SMALLINT,
  ano_semestre_ingresso VARCHAR(6),
  FOREIGN KEY (id_curso) REFERENCES dim_curso (id_curso)
);

CREATE TABLE dim_aluno (
  id_aluno BIGINT PRIMARY KEY,
  id_turma_aluno BIGINT NOT NULL,
  numero_matricula VARCHAR(30) NOT NULL UNIQUE,
  nome VARCHAR(160),
  forma_ingresso VARCHAR(50),
  tipo_cota VARCHAR(120),
  faixa_economica VARCHAR(60),
  versao_curriculo VARCHAR(60),
  situacao_vinculo VARCHAR(20), -- [AJUSTE] ATIVO, CONCLUIDO ou EVADIDO
  id_data_saida BIGINT,         -- [AJUSTE] semestre da saida, nulo se ATIVO
  FOREIGN KEY (id_turma_aluno) REFERENCES dim_turma_aluno (id_turma_aluno),
  FOREIGN KEY (id_data_saida) REFERENCES dim_data (id_data)
);

CREATE TABLE dim_turma_disciplina (
  id_turma_disciplina BIGINT PRIMARY KEY,
  id_disciplina BIGINT NOT NULL,
  id_data BIGINT NOT NULL,
  codigo_turma VARCHAR(40),
  horario VARCHAR(200),
  id_professor_1 BIGINT,
  id_professor_2 BIGINT,
  id_professor_3 BIGINT,
  UNIQUE KEY uq_oferta (id_disciplina, id_data, codigo_turma),
  FOREIGN KEY (id_disciplina) REFERENCES dim_disciplina (id_disciplina),
  FOREIGN KEY (id_data) REFERENCES dim_data (id_data),
  FOREIGN KEY (id_professor_1) REFERENCES dim_professor (id_professor),
  FOREIGN KEY (id_professor_2) REFERENCES dim_professor (id_professor),
  FOREIGN KEY (id_professor_3) REFERENCES dim_professor (id_professor)
);

CREATE TABLE fato_professor_aluno (
  id_professor_aluno BIGINT PRIMARY KEY,
  id_aluno BIGINT NOT NULL,
  id_turma_disciplina BIGINT NOT NULL,
  id_disciplina BIGINT NOT NULL,
  id_curso BIGINT NOT NULL,
  id_data BIGINT NOT NULL,
  situacao_final VARCHAR(35),
  nota_final DECIMAL(5,2),
  quantidade_faltas INT,
  ch_adquirida INT NOT NULL,
  bolsista_no_semestre BOOLEAN,
  qtd_tentativas INT NOT NULL,
  periodo_aluno SMALLINT NOT NULL, -- [AJUSTE] semestres desde o ingresso, base da consulta C8
  UNIQUE KEY uq_matricula (id_aluno, id_turma_disciplina, id_curso),
  FOREIGN KEY (id_aluno) REFERENCES dim_aluno (id_aluno),
  FOREIGN KEY (id_turma_disciplina) REFERENCES dim_turma_disciplina (id_turma_disciplina),
  FOREIGN KEY (id_disciplina) REFERENCES dim_disciplina (id_disciplina),
  FOREIGN KEY (id_curso) REFERENCES dim_curso (id_curso),
  FOREIGN KEY (id_data) REFERENCES dim_data (id_data)
);

CREATE TABLE fato_professor_disciplina (
  id_professor_disciplina BIGINT PRIMARY KEY,
  id_disciplina BIGINT NOT NULL,
  id_turma_disciplina BIGINT NOT NULL,
  id_curso BIGINT NOT NULL,
  id_data BIGINT NOT NULL,
  qtd_matriculados INT NOT NULL,
  qtd_aprovacoes_nota INT NOT NULL,
  qtd_aprovacoes_final INT NOT NULL,
  qtd_reprovacoes_nota INT NOT NULL,
  qtd_reprovacoes_faltas INT NOT NULL,
  qtd_trancamentos INT NOT NULL, -- [AJUSTE] fecha a conta de qtd_matriculados
  menor_notas DECIMAL(5,2),
  maior_notas DECIMAL(5,2),
  mediana_notas DECIMAL(5,2),
  media_notas DECIMAL(5,2),
  media_faltas DECIMAL(8,2),
  soma_notas_finais DECIMAL(14,2) NOT NULL,
  qtd_notas_validas INT NOT NULL,
  soma_faltas INT NOT NULL,
  qtd_faltas_validas INT NOT NULL,
  qtd_nota_0_2_9 INT NOT NULL,
  qtd_nota_3_6_9 INT NOT NULL,
  qtd_nota_7_7_9 INT NOT NULL,
  qtd_nota_8_8_9 INT NOT NULL,
  qtd_nota_9_10 INT NOT NULL,
  qtd_bolsistas_aprovados_nota INT NOT NULL,
  qtd_bolsistas_aprovados_final INT NOT NULL,
  qtd_bolsistas_reprovados_nota INT NOT NULL,
  qtd_bolsistas_reprovados_faltas INT NOT NULL,
  UNIQUE KEY uq_oferta_curso (id_turma_disciplina, id_curso, id_data),
  FOREIGN KEY (id_disciplina) REFERENCES dim_disciplina (id_disciplina),
  FOREIGN KEY (id_turma_disciplina) REFERENCES dim_turma_disciplina (id_turma_disciplina),
  FOREIGN KEY (id_curso) REFERENCES dim_curso (id_curso),
  FOREIGN KEY (id_data) REFERENCES dim_data (id_data)
);
