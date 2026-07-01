-- =====================================================================
-- TRABALHO PRÁTICO DE BANCO DE DADOS I
-- Bacharelado em Engenharia de Computação - IFRJ Campus Niterói
-- Aplicação: Sistema de Controle de Atividades Acadêmicas
-- SGBD: MySQL 8.0+  (engine InnoDB / charset utf8mb4)
-- ---------------------------------------------------------------------
-- Modelo lógico (6 tabelas relacionadas):
--   curso(1) ----< aluno(N)
--   curso(1) ----< disciplina(N)
--   disciplina(1) ----< turma(N) >---- (1)professor
--   aluno(1) ----< matricula(N) >---- (1)turma
--
-- As 4 regras de integridade referencial exigidas são demonstradas:
--   RESTRICT   -> aluno.fk_curso        (não exclui curso com alunos)
--   CASCADE    -> disciplina.fk_curso   (exclui curso => exclui disciplinas)
--   CASCADE    -> turma.fk_disciplina e matricula.fk_aluno
--   SET NULL   -> turma.fk_professor    (professor sai => turma sem prof.)
--   NO ACTION  -> matricula.fk_turma    (impede excluir turma com matrículas)
-- =====================================================================

-- Recria o schema do zero (script idempotente / pronto para reexecutar)
DROP DATABASE IF EXISTS controle_academico;
CREATE DATABASE controle_academico
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
USE controle_academico;


-- =====================================================================
-- 1. CREATE TABLE
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tabela CURSO (entidade base, sem chave estrangeira)
-- Tipos: numérico (id, carga_horaria), textual (codigo, nome, modalidade),
--        data (data_criacao)
-- ---------------------------------------------------------------------
CREATE TABLE curso (
    id_curso       INT AUTO_INCREMENT,                          -- numérico (PK)
    codigo         CHAR(6)            NOT NULL,                 -- textual, identificador único
    nome           VARCHAR(100)       NOT NULL,                 -- textual
    modalidade     ENUM('Presencial','EAD','Hibrido')
                                      NOT NULL DEFAULT 'Presencial',
    carga_horaria  SMALLINT UNSIGNED  NOT NULL,                 -- numérico (horas)
    data_criacao   DATE               NOT NULL,                 -- data

    CONSTRAINT pk_curso       PRIMARY KEY (id_curso),
    CONSTRAINT uq_curso_codigo UNIQUE (codigo),                 -- UNIQUE
    CONSTRAINT chk_curso_ch   CHECK (carga_horaria > 0)         -- regra de domínio
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- Tabela PROFESSOR (entidade base, sem chave estrangeira)
-- Tipos: numérico (id, salario), textual (siape, nome, email, titulacao),
--        data (data_admissao)
-- ---------------------------------------------------------------------
CREATE TABLE professor (
    id_professor   INT AUTO_INCREMENT,                          -- numérico (PK)
    siape          CHAR(7)            NOT NULL,                 -- textual, matrícula funcional única
    nome           VARCHAR(100)       NOT NULL,                 -- textual
    email          VARCHAR(120)       NOT NULL,                 -- textual
    titulacao      ENUM('Graduado','Especialista','Mestre','Doutor')
                                      NOT NULL DEFAULT 'Mestre',
    salario        DECIMAL(10,2)      NOT NULL,                 -- numérico (valor monetário)
    data_admissao  DATE               NOT NULL,                 -- data

    CONSTRAINT pk_professor       PRIMARY KEY (id_professor),
    CONSTRAINT uq_professor_siape UNIQUE (siape),               -- UNIQUE
    CONSTRAINT uq_professor_email UNIQUE (email),               -- UNIQUE
    CONSTRAINT chk_professor_sal  CHECK (salario >= 0)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- Tabela ALUNO (FK -> curso, regra RESTRICT)
-- RESTRICT: bloqueia a exclusão de um curso enquanto houver alunos nele.
-- Tipos: numérico (id), textual (matricula, nome, email),
--        data (data_nascimento, data_ingresso)
-- ---------------------------------------------------------------------
CREATE TABLE aluno (
    id_aluno        INT AUTO_INCREMENT,                         -- numérico (PK)
    matricula       CHAR(12)          NOT NULL,                 -- textual, única
    nome            VARCHAR(100)      NOT NULL,                 -- textual
    email           VARCHAR(120)      NOT NULL,                 -- textual
    data_nascimento DATE              NOT NULL,                 -- data
    data_ingresso   DATE              NOT NULL,                 -- data
    id_curso        INT               NOT NULL,                 -- FK (obrigatória)

    CONSTRAINT pk_aluno           PRIMARY KEY (id_aluno),
    CONSTRAINT uq_aluno_matricula UNIQUE (matricula),           -- UNIQUE
    CONSTRAINT uq_aluno_email     UNIQUE (email),               -- UNIQUE
    CONSTRAINT fk_aluno_curso     FOREIGN KEY (id_curso)
        REFERENCES curso (id_curso)
        ON DELETE RESTRICT                                      -- integridade referencial
        ON UPDATE CASCADE
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- Tabela DISCIPLINA (FK -> curso, regra CASCADE)
-- CASCADE: ao excluir um curso, suas disciplinas são removidas junto.
-- Tipos: numérico (id, carga_horaria, periodo), textual (codigo, nome, ementa),
-- ---------------------------------------------------------------------
CREATE TABLE disciplina (
    id_disciplina  INT AUTO_INCREMENT,                          -- numérico (PK)
    codigo         CHAR(8)            NOT NULL,                 -- textual, único
    nome           VARCHAR(100)       NOT NULL,                 -- textual
    carga_horaria  SMALLINT UNSIGNED  NOT NULL,                 -- numérico
    periodo        TINYINT UNSIGNED   NOT NULL,                 -- numérico (período do curso)
    ementa         TEXT               NULL,                     -- textual longo (opcional)
    id_curso       INT                NOT NULL,                 -- FK (obrigatória)

    CONSTRAINT pk_disciplina        PRIMARY KEY (id_disciplina),
    CONSTRAINT uq_disciplina_codigo UNIQUE (codigo),            -- UNIQUE
    CONSTRAINT fk_disciplina_curso  FOREIGN KEY (id_curso)
        REFERENCES curso (id_curso)
        ON DELETE CASCADE                                       -- integridade referencial
        ON UPDATE CASCADE,
    CONSTRAINT chk_disciplina_per   CHECK (periodo BETWEEN 1 AND 12)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- Tabela TURMA (FK -> disciplina [CASCADE] e FK -> professor [SET NULL])
-- CASCADE : excluir a disciplina remove as turmas dela.
-- SET NULL: ao excluir o professor, a turma fica sem professor (id_professor = NULL),
--           por isso a coluna id_professor ACEITA NULL.
-- Tipos: numérico (id, ano, semestre, vagas), textual (sala), data (data_inicio)
-- ---------------------------------------------------------------------
CREATE TABLE turma (
    id_turma       INT AUTO_INCREMENT,                          -- numérico (PK)
    id_disciplina  INT                NOT NULL,                 -- FK obrigatória
    id_professor   INT                NULL,                     -- FK opcional (permite SET NULL)
    ano            SMALLINT UNSIGNED  NOT NULL,                 -- numérico
    semestre       TINYINT  UNSIGNED  NOT NULL,                 -- numérico (1 ou 2)
    sala           VARCHAR(20)        NOT NULL,                 -- textual
    vagas          SMALLINT UNSIGNED  NOT NULL DEFAULT 40,      -- numérico
    data_inicio    DATE               NOT NULL,                 -- data

    CONSTRAINT pk_turma          PRIMARY KEY (id_turma),
    -- evita cadastrar a mesma turma (disciplina/ano/semestre/sala) duas vezes
    CONSTRAINT uq_turma          UNIQUE (id_disciplina, ano, semestre, sala),
    CONSTRAINT fk_turma_disc     FOREIGN KEY (id_disciplina)
        REFERENCES disciplina (id_disciplina)
        ON DELETE CASCADE                                       -- integridade referencial
        ON UPDATE CASCADE,
    CONSTRAINT fk_turma_prof     FOREIGN KEY (id_professor)
        REFERENCES professor (id_professor)
        ON DELETE SET NULL                                      -- integridade referencial
        ON UPDATE CASCADE,
    CONSTRAINT chk_turma_sem     CHECK (semestre IN (1,2)),
    CONSTRAINT chk_turma_vagas   CHECK (vagas > 0)
) ENGINE=InnoDB;


-- ---------------------------------------------------------------------
-- Tabela MATRICULA (associativa: FK -> aluno [CASCADE] e FK -> turma [NO ACTION])
-- CASCADE  : ao excluir um aluno, suas matrículas são removidas.
-- NO ACTION: impede excluir uma turma que ainda possua matrículas
--            (no InnoDB, NO ACTION é verificado e se comporta como RESTRICT).
-- Tipos: numérico (id, nota_final, frequencia), textual (status), data (data_matricula)
-- ---------------------------------------------------------------------
CREATE TABLE matricula (
    id_matricula   INT AUTO_INCREMENT,                          -- numérico (PK)
    id_aluno       INT                NOT NULL,                 -- FK obrigatória
    id_turma       INT                NOT NULL,                 -- FK obrigatória
    data_matricula DATE               NOT NULL,                 -- data
    status         ENUM('Cursando','Aprovado','Reprovado','Trancado')
                                      NOT NULL DEFAULT 'Cursando',
    nota_final     DECIMAL(4,2)       NULL,                     -- numérico (0.00 a 10.00)
    frequencia     TINYINT UNSIGNED   NULL,                     -- numérico (0 a 100 %)

    CONSTRAINT pk_matricula      PRIMARY KEY (id_matricula),
    -- impede o mesmo aluno se matricular duas vezes na mesma turma
    CONSTRAINT uq_matricula      UNIQUE (id_aluno, id_turma),
    CONSTRAINT fk_matricula_aluno FOREIGN KEY (id_aluno)
        REFERENCES aluno (id_aluno)
        ON DELETE CASCADE                                       -- integridade referencial
        ON UPDATE CASCADE,
    CONSTRAINT fk_matricula_turma FOREIGN KEY (id_turma)
        REFERENCES turma (id_turma)
        ON DELETE NO ACTION                                     -- integridade referencial
        ON UPDATE NO ACTION,
    CONSTRAINT chk_mat_nota      CHECK (nota_final  BETWEEN 0 AND 10),
    CONSTRAINT chk_mat_freq      CHECK (frequencia  BETWEEN 0 AND 100)
) ENGINE=InnoDB;


-- =====================================================================
-- 2. ALTER TABLE
-- ---------------------------------------------------------------------
-- As constraints já foram declaradas inline nos CREATE TABLE acima.
-- Abaixo, exemplos de como as mesmas restrições seriam adicionadas via
-- ALTER TABLE (mantidos comentados para não duplicar as constraints):
--
-- ALTER TABLE aluno
--     ADD CONSTRAINT fk_aluno_curso FOREIGN KEY (id_curso)
--     REFERENCES curso (id_curso) ON DELETE RESTRICT ON UPDATE CASCADE;
--
-- ALTER TABLE matricula
--     ADD CONSTRAINT uq_matricula UNIQUE (id_aluno, id_turma);
-- =====================================================================

-- Exemplo real de ALTER TABLE: coluna de auditoria adicionada após a criação
ALTER TABLE matricula
    ADD COLUMN atualizado_em DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP;                            -- data/hora (auditoria)


-- =====================================================================
-- 3. INSERT INTO  (dados de teste)
-- =====================================================================

-- ---------- CURSO (10 registros) ----------
INSERT INTO curso (codigo, nome, modalidade, carga_horaria, data_criacao) VALUES
('ENGCMP', 'Engenharia de Computacao',          'Presencial', 4000, '2018-02-01'),
('SISINF', 'Sistemas de Informacao',            'Presencial', 3200, '2015-03-10'),
('REDCMP', 'Redes de Computadores',             'Hibrido',    2400, '2017-08-15'),
('ADSTEC', 'Analise e Desenvolvimento de Sist.','EAD',        2000, '2019-01-20'),
('ENGELE', 'Engenharia Eletrica',               'Presencial', 4000, '2014-02-05'),
('MATIND', 'Manutencao Industrial',             'Presencial', 2200, '2016-07-01'),
('AUTIND', 'Automacao Industrial',              'Hibrido',    2600, '2020-02-10'),
('SEGTRB', 'Seguranca do Trabalho',             'EAD',        1800, '2021-03-01'),
('TELCOM', 'Telecomunicacoes',                  'Presencial', 2800, '2013-08-20'),
('CIEDAD', 'Ciencia de Dados',                  'Hibrido',    2400, '2022-02-15');

-- ---------- PROFESSOR (12 registros) ----------
INSERT INTO professor (siape, nome, email, titulacao, salario, data_admissao) VALUES
('1000001', 'Luiz Felipe Silva Oliveira', 'luiz.oliveira@ifrj.edu.br',   'Doutor',       12500.00, '2012-03-01'),
('1000002', 'Mariana Costa Andrade',      'mariana.andrade@ifrj.edu.br', 'Doutor',       12500.00, '2014-08-12'),
('1000003', 'Rafael Souza Lima',          'rafael.lima@ifrj.edu.br',     'Mestre',        9800.00, '2016-02-20'),
('1000004', 'Carla Mendes Ribeiro',       'carla.ribeiro@ifrj.edu.br',   'Doutor',       12500.00, '2011-09-05'),
('1000005', 'Bruno Almeida Pereira',      'bruno.pereira@ifrj.edu.br',   'Mestre',        9800.00, '2018-03-15'),
('1000006', 'Fernanda Rocha Dias',        'fernanda.dias@ifrj.edu.br',   'Especialista',  7200.00, '2019-08-01'),
('1000007', 'Gustavo Henrique Martins',   'gustavo.martins@ifrj.edu.br', 'Doutor',       12500.00, '2013-02-10'),
('1000008', 'Patricia Gomes Barbosa',     'patricia.barbosa@ifrj.edu.br','Mestre',        9800.00, '2017-08-22'),
('1000009', 'Diego Fernandes Cardoso',    'diego.cardoso@ifrj.edu.br',   'Mestre',        9800.00, '2020-03-02'),
('1000010', 'Juliana Teixeira Nunes',     'juliana.nunes@ifrj.edu.br',   'Doutor',       12500.00, '2015-09-14'),
('1000011', 'Marcelo Vieira Castro',      'marcelo.castro@ifrj.edu.br',  'Especialista',  7200.00, '2021-02-01'),
('1000012', 'Beatriz Lopes Moreira',      'beatriz.moreira@ifrj.edu.br', 'Mestre',        9800.00, '2019-03-18');

-- ---------- ALUNO (15 registros) ----------
-- id_curso referencia curso(1..10)
INSERT INTO aluno (matricula, nome, email, data_nascimento, data_ingresso, id_curso) VALUES
('20251NIT001', 'Pietro Carvalho Santos',     'pietro.santos@aluno.ifrj.edu.br',    '2003-05-12', '2025-08-01', 1),
('20251NIT002', 'Ana Luiza Ferreira',         'ana.ferreira@aluno.ifrj.edu.br',     '2004-01-22', '2025-08-01', 1),
('20251NIT003', 'Joao Pedro Azevedo',         'joao.azevedo@aluno.ifrj.edu.br',     '2002-11-30', '2025-08-01', 2),
('20251NIT004', 'Larissa Monteiro Pinto',     'larissa.pinto@aluno.ifrj.edu.br',    '2003-07-08', '2025-08-01', 2),
('20241NIT005', 'Gabriel Araujo Cunha',       'gabriel.cunha@aluno.ifrj.edu.br',    '2002-03-19', '2024-03-01', 3),
('20241NIT006', 'Camila Barros Tavares',      'camila.tavares@aluno.ifrj.edu.br',   '2003-09-25', '2024-03-01', 1),
('20242NIT007', 'Lucas Ramos Figueiredo',     'lucas.figueiredo@aluno.ifrj.edu.br', '2004-04-14', '2024-08-01', 4),
('20242NIT008', 'Isabela Cardoso Melo',       'isabela.melo@aluno.ifrj.edu.br',     '2003-12-02', '2024-08-01', 5),
('20231NIT009', 'Matheus Oliveira Brito',     'matheus.brito@aluno.ifrj.edu.br',    '2001-06-17', '2023-03-01', 5),
('20231NIT010', 'Sofia Nascimento Reis',      'sofia.reis@aluno.ifrj.edu.br',       '2002-08-29', '2023-03-01', 3),
('20251NIT011', 'Vinicius Duarte Campos',     'vinicius.campos@aluno.ifrj.edu.br',  '2004-02-05', '2025-08-01', 6),
('20251NIT012', 'Helena Cavalcanti Lima',     'helena.lima@aluno.ifrj.edu.br',      '2003-10-11', '2025-08-01', 7),
('20242NIT013', 'Felipe Moraes Antunes',      'felipe.antunes@aluno.ifrj.edu.br',   '2002-05-23', '2024-08-01', 10),
('20242NIT014', 'Beatriz Souza Cordeiro',     'beatriz.cordeiro@aluno.ifrj.edu.br', '2003-03-30', '2024-08-01', 10),
('20231NIT015', 'Thiago Pereira Macedo',      'thiago.macedo@aluno.ifrj.edu.br',    '2001-12-09', '2023-03-01', 9);

-- ---------- DISCIPLINA (12 registros) ----------
-- id_curso referencia curso(1..10)
INSERT INTO disciplina (codigo, nome, carga_horaria, periodo, ementa, id_curso) VALUES
('BD1-0001', 'Banco de Dados I',                 80, 4, 'Modelagem relacional, SQL DDL/DML e normalizacao.', 1),
('PRG-0003', 'Programacao III',                  80, 3, 'Desenvolvimento web com JavaScript.',               1),
('POO-0002', 'Programacao Orientada a Objetos',  80, 2, 'Encapsulamento, heranca e polimorfismo em Java.',   1),
('EST-0001', 'Estrutura de Dados',               80, 3, 'Listas, pilhas, filas, arvores e grafos.',          1),
('RED-0004', 'Redes de Computadores',            60, 4, 'Modelo OSI, TCP/IP e roteamento.',                  3),
('SIS-0001', 'Sistemas Operacionais',            80, 5, 'Processos, memoria e escalonamento.',               2),
('CAL-0001', 'Calculo I',                       100, 1, 'Limites, derivadas e integrais.',                   5),
('FIS-0002', 'Fisica II',                        80, 2, 'Eletromagnetismo e ondas.',                         5),
('AUT-0003', 'Sistemas de Controle',             60, 5, 'Controle classico e moderno.',                      7),
('MAN-0001', 'Manutencao Preditiva',             40, 3, 'Tecnicas de monitoramento de condicao.',            6),
('DAT-0001', 'Aprendizado de Maquina',           80, 4, 'Modelos supervisionados e nao supervisionados.',   10),
('TEL-0002', 'Comunicacoes Digitais',            60, 4, 'Modulacao digital e teoria da informacao.',         9);

-- ---------- TURMA (12 registros) ----------
-- id_disciplina referencia disciplina(1..12); id_professor referencia professor(1..12)
-- (a turma 12 propositalmente fica SEM professor para ilustrar id_professor NULL)
INSERT INTO turma (id_disciplina, id_professor, ano, semestre, sala, vagas, data_inicio) VALUES
( 1,  1, 2026, 1, 'Lab-201', 35, '2026-03-09'),
( 2,  1, 2026, 1, 'Lab-202', 35, '2026-03-09'),
( 3,  3, 2026, 1, 'Sala-105',40, '2026-03-10'),
( 4,  5, 2026, 1, 'Lab-203', 30, '2026-03-10'),
( 5,  9, 2026, 1, 'Sala-110',45, '2026-03-11'),
( 6,  8, 2026, 1, 'Sala-108',40, '2026-03-11'),
( 7,  4, 2026, 1, 'Sala-201',50, '2026-03-12'),
( 8,  7, 2026, 1, 'Lab-Fis', 30, '2026-03-12'),
( 9, 11, 2026, 1, 'Sala-115',35, '2026-03-13'),
(10,  6, 2026, 1, 'Sala-120',40, '2026-03-13'),
(11,  2, 2026, 1, 'Lab-Dat', 30, '2026-03-14'),
(12, NULL,2026, 1, 'Sala-130',40, '2026-03-14');

-- ---------- MATRICULA (15 registros) ----------
-- id_aluno referencia aluno(1..15); id_turma referencia turma(1..12)
INSERT INTO matricula (id_aluno, id_turma, data_matricula, status, nota_final, frequencia) VALUES
( 1,  1, '2026-03-01', 'Cursando',  NULL,  92),
( 1,  2, '2026-03-01', 'Cursando',  NULL,  88),
( 2,  1, '2026-03-01', 'Cursando',  NULL,  75),
( 2,  3, '2026-03-01', 'Aprovado',  8.50,  95),
( 3,  6, '2026-03-02', 'Cursando',  NULL,  80),
( 4,  6, '2026-03-02', 'Reprovado', 4.20,  60),
( 5,  5, '2026-03-03', 'Aprovado',  9.10,  98),
( 6,  1, '2026-03-03', 'Cursando',  NULL,  85),
( 7,  7, '2026-03-04', 'Trancado',  NULL,  30),
( 8,  8, '2026-03-04', 'Aprovado',  7.80,  90),
( 9,  8, '2026-03-05', 'Aprovado',  6.50,  82),
(10,  5, '2026-03-05', 'Cursando',  NULL,  77),
(11, 10, '2026-03-06', 'Cursando',  NULL,  70),
(13, 11, '2026-03-06', 'Aprovado',  9.50,  99),
(14, 11, '2026-03-07', 'Cursando',  NULL,  88);


-- =====================================================================
-- FIM DO SCRIPT
-- =====================================================================
