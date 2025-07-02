-- =====================================================================
-- FUNÇÃO DE TRIGGER (Executar uma única vez no início)
-- =====================================================================
CREATE OR REPLACE FUNCTION public.update_row_update_time() 
RETURNS TRIGGER AS 
$$
BEGIN
    NEW.row_update_time := NOW();
    RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

COMMENT ON FUNCTION public.update_row_update_time() IS 'Função de trigger geral para atualizar os metadados de uma linha sempre que um UPDATE ocorrer.';


-- =====================================================================
-- TABELAS DE DOMÍNIO (Lookup Tables)
-- =====================================================================

-- Tabela: Status_Agendamento
DROP TABLE IF EXISTS public.status_agendamento CASCADE;
CREATE TABLE public.status_agendamento (
    status_agendamento_id SMALLINT PRIMARY KEY,
    status_agendamento_descricao VARCHAR(50) NOT NULL
);
COMMENT ON TABLE public.status_agendamento IS 'Tabela de domínio para os status de um agendamento.';
INSERT INTO public.status_agendamento (status_agendamento_id, status_agendamento_descricao) VALUES
(1, 'Confirmado'),
(2, 'Cancelado pelo Usuário'),
(3, 'Cancelado pelo Sistema'),
(4, 'Concluído'),
(5, 'Não Compareceu');

-- Tabela: Status_Sistema
DROP TABLE IF EXISTS public.status_sistema CASCADE;
CREATE TABLE public.status_sistema (
    status_sistema_id SMALLINT PRIMARY KEY,
    status_sistema_descricao VARCHAR(50) NOT NULL
);
COMMENT ON TABLE public.status_sistema IS 'Tabela de domínio para os status de um sistema externo.';
INSERT INTO public.status_sistema (status_sistema_id, status_sistema_descricao) VALUES
(1, 'Online'),
(2, 'Offline'),
(3, 'Em Manutenção');

-- Tabela: Categoria_Endereço
DROP TABLE IF EXISTS public.categoria_endereco CASCADE;
CREATE TABLE public.categoria_endereco (
    categoria_endereco_id SMALLINT PRIMARY KEY,
    categoria_endereco_descricao VARCHAR(50) NOT NULL
);

COMMENT ON TABLE public.categoria_endereco IS 'Tabela de domínio para as categorias de endereço.';
INSERT INTO public.categoria_endereco (categoria_endereco_id, categoria_endereco_descricao) VALUES
(1, 'Polo de Atendimento'),
(2, 'Endereço de Cidadão');

-- =====================================================================
-- SCRIPT PARA TABELA: Endereco
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.endereco_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.endereco CASCADE;
/* Create Table */
CREATE TABLE public.endereco
(
	endereco_id integer NOT NULL DEFAULT NEXTVAL(('endereco_id_seq'::text)::regclass), -- Chave primária da tabela.
	endereco_logradouro varchar(256) NOT NULL, -- Nome da rua, avenida, etc.
	endereco_numero varchar(10) NULL, -- Número do imóvel, incluindo complementos como 'A' ou 'S/N'.
	endereco_complemento varchar(64) NULL, -- Complemento como apartamento, bloco, etc.
	endereco_bairro varchar(64) NOT NULL, -- Bairro.
	endereco_cidade varchar(64) NOT NULL, -- Cidade.
	endereco_estado varchar(2) NOT NULL, -- Sigla do estado (UF).
	endereco_cep varchar(9) NOT NULL, -- CEP no formato '12345-678'.
	categoria_endereco_id smallint NOT NULL,
	row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.endereco ADD CONSTRAINT endereco_pk PRIMARY KEY (endereco_id);
/* Create Foreign Key */
ALTER TABLE public.endereco ADD CONSTRAINT endereco_fk1 FOREIGN KEY (categoria_endereco_id) REFERENCES public.categoria_endereco (categoria_endereco_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER endereco_upd_trigger BEFORE UPDATE ON public.endereco FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.endereco IS 'Armazena informações de endereço para cidadãos e polos de atendimento.';
CREATE SEQUENCE public.endereco_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Cidadao
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.cidadao_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.cidadao CASCADE;
/* Create Table */
CREATE TABLE public.cidadao
(
	cidadao_id integer NOT NULL DEFAULT NEXTVAL(('cidadao_id_seq'::text)::regclass),
	cidadao_nome varchar(256) NOT NULL,
	cidadao_sobrenome varchar(64) NOT NULL,
	cidadao_cpf varchar(11) NOT NULL,
	cidadao_nacionalidade varchar(64) NOT NULL,
	cidadao_telefone varchar(20) NOT NULL,
	endereco_id integer NOT NULL,
	row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary and Unique Keys */
ALTER TABLE public.cidadao ADD CONSTRAINT cidadao_pk PRIMARY KEY (cidadao_id);
ALTER TABLE public.cidadao ADD CONSTRAINT cidadao_uk1 UNIQUE (cidadao_cpf);
/* Create Foreign Key */
ALTER TABLE public.cidadao ADD CONSTRAINT cidadao_fk1 FOREIGN KEY (endereco_id) REFERENCES public.endereco (endereco_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER cidadao_upd_trigger BEFORE UPDATE ON public.cidadao FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.cidadao IS 'Armazena as informações dos cidadãos.';
CREATE SEQUENCE public.cidadao_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Polo_Atendimento
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.polo_atendimento_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.polo_atendimento CASCADE;
/* Create Table */
CREATE TABLE public.polo_atendimento
(
	polo_atendimento_id integer NOT NULL DEFAULT NEXTVAL(('polo_atendimento_id_seq'::text)::regclass),
	polo_atendimento_nome varchar(256) NOT NULL,
	polo_atendimento_mesas integer NOT NULL,
	endereco_id integer NOT NULL,
	row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.polo_atendimento ADD CONSTRAINT polo_atendimento_pk PRIMARY KEY (polo_atendimento_id);
/* Create Foreign Key */
ALTER TABLE public.polo_atendimento ADD CONSTRAINT polo_atendimento_fk1 FOREIGN KEY (endereco_id) REFERENCES public.endereco (endereco_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER polo_atendimento_upd_trigger BEFORE UPDATE ON public.polo_atendimento FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.polo_atendimento IS 'Armazena os postos de atendimento do Poupatempo.';
COMMENT ON COLUMN public.polo_atendimento.polo_atendimento_mesas IS 'Capacidade total de atendimentos simultâneos no posto.';
CREATE SEQUENCE public.polo_atendimento_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Orgao
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.orgao_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.orgao CASCADE;
/* Create Table */
CREATE TABLE public.orgao (
    orgao_id integer NOT NULL DEFAULT NEXTVAL(('orgao_id_seq'::text)::regclass),
    orgao_nome varchar(64) NOT NULL,
	orgao_descricao varchar(256) NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.orgao ADD CONSTRAINT orgao_pk PRIMARY KEY (orgao_id);
/* Create Trigger */
CREATE TRIGGER orgao_upd_trigger BEFORE UPDATE ON public.orgao FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.orgao IS 'Órgãos governamentais responsáveis pelos serviços (ex: Detran, IIRGD).';
CREATE SEQUENCE public.orgao_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Categoria
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.categoria_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.categoria CASCADE;
/* Create Table */
CREATE TABLE public.categoria (
    categoria_id integer NOT NULL DEFAULT NEXTVAL(('categoria_id_seq'::text)::regclass),
    categoria_nome varchar(256) NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.categoria ADD CONSTRAINT categoria_pk PRIMARY KEY (categoria_id);
/* Create Trigger */
CREATE TRIGGER categoria_upd_trigger BEFORE UPDATE ON public.categoria FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.categoria IS 'Categorias para agrupar os serviços (ex: Veículos, Documentos Pessoais).';
CREATE SEQUENCE public.categoria_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Sistema
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.sistema_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.sistema CASCADE;
/* Create Table */
CREATE TABLE public.sistema (
    sistema_id integer NOT NULL DEFAULT NEXTVAL(('sistema_id_seq'::text)::regclass),
    sistema_nome varchar(256) NOT NULL,
    status_sistema_id smallint NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.sistema ADD CONSTRAINT sistema_pk PRIMARY KEY (sistema_id);
/* Create Foreign Key */
ALTER TABLE public.sistema ADD CONSTRAINT sistema_fk1 FOREIGN KEY (status_sistema_id) REFERENCES public.status_sistema(status_sistema_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER sistema_upd_trigger BEFORE UPDATE ON public.sistema FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.sistema IS 'Sistemas externos dos quais os serviços dependem (ex: sistema do Detran).';
CREATE SEQUENCE public.sistema_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Servico
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.servico_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.servico CASCADE;
/* Create Table */
CREATE TABLE public.servico (
    servico_id integer NOT NULL DEFAULT NEXTVAL(('servico_id_seq'::text)::regclass),
    servico_nome varchar(256) NOT NULL,
    orgao_id integer NOT NULL,
    categoria_id integer NOT NULL,
    sistema_id integer NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.servico ADD CONSTRAINT servico_pk PRIMARY KEY (servico_id);
/* Create Foreign Keys */
ALTER TABLE public.servico ADD CONSTRAINT servico_fk1 FOREIGN KEY (orgao_id) REFERENCES public.orgao(orgao_id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE public.servico ADD CONSTRAINT servico_fk2 FOREIGN KEY (categoria_id) REFERENCES public.categoria(categoria_id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE public.servico ADD CONSTRAINT servico_fk3 FOREIGN KEY (sistema_id) REFERENCES public.sistema(sistema_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER servico_upd_trigger BEFORE UPDATE ON public.servico FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.servico IS 'Catálogo de serviços específicos oferecidos (ex: "Primeira Habilitação").';
CREATE SEQUENCE public.servico_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Horario_Atendimento
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.horario_atendimento_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.horario_atendimento CASCADE;
/* Create Table */
CREATE TABLE public.horario_atendimento (
    horario_atendimento_id integer NOT NULL DEFAULT NEXTVAL(('horario_atendimento_id_seq'::text)::regclass),
    horario_atendimento_dia_semana smallint NOT NULL, -- 1=Domingo, 2=Segunda, etc.
    horario_atendimento_hora_inicio time NOT NULL,
    horario_atendimento_hora_fim time NOT NULL,
    horario_atendimento_duracao_slot_minutos integer NOT NULL,
    polo_atendimento_id integer NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.horario_atendimento ADD CONSTRAINT horario_atendimento_pk PRIMARY KEY (horario_atendimento_id);
/* Create Foreign Key */
ALTER TABLE public.horario_atendimento ADD CONSTRAINT horario_atendimento_fk1 FOREIGN KEY (polo_atendimento_id) REFERENCES public.polo_atendimento(polo_atendimento_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER horario_atendimento_upd_trigger BEFORE UPDATE ON public.horario_atendimento FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.horario_atendimento IS 'Define a grade de horários padrão de cada posto de atendimento.';
CREATE SEQUENCE public.horario_atendimento_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Periodo_Excecao
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.periodo_excecao_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.periodo_excecao CASCADE;
/* Create Table */
CREATE TABLE public.periodo_excecao (
	periodo_excecao_id integer NOT NULL DEFAULT NEXTVAL(('periodo_excecao_id_seq'::text)::regclass),
    polo_atendimento_id integer NULL,
	periodo_excecao_data_hora_inicio timestamp NOT NULL,
	periodo_excecao_data_hora_fim timestamp NOT NULL,
	periodo_excecao_descricao varchar(256) NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.periodo_excecao ADD CONSTRAINT periodo_excecao_pk PRIMARY KEY (periodo_excecao_id);
/* Create Foreign Key */
ALTER TABLE public.periodo_excecao ADD CONSTRAINT periodo_excecao_fk1 FOREIGN KEY (polo_atendimento_id) REFERENCES public.polo_atendimento(polo_atendimento_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER periodo_excecao_upd_trigger BEFORE UPDATE ON public.periodo_excecao FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.periodo_excecao IS 'Armazena exceções à grade padrão, como feriados e manutenções.';
CREATE SEQUENCE public.periodo_excecao_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- SCRIPT PARA TABELA: Agendamento
-- =====================================================================
/* Drop Sequence */
DROP SEQUENCE IF EXISTS public.agendamento_id_seq;
/* Drop Table */
DROP TABLE IF EXISTS public.agendamento CASCADE;
/* Create Table */
CREATE TABLE public.agendamento (
    agendamento_id integer NOT NULL DEFAULT NEXTVAL(('agendamento_id_seq'::text)::regclass),
    agendamento_data_hora timestamp NOT NULL,
    cidadao_id integer NOT NULL,
    servico_id integer NOT NULL,
    polo_atendimento_id integer NOT NULL,
    status_agendamento_id smallint NOT NULL,
    row_creation_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_update_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	row_creation_user varchar(30) NOT NULL DEFAULT 'system',
	row_update_user varchar(30) NOT NULL DEFAULT 'system',
	row_is_deleted boolean NOT NULL DEFAULT False
);
/* Create Primary Key */
ALTER TABLE public.agendamento ADD CONSTRAINT agendamento_pk PRIMARY KEY (agendamento_id);
/* Create Foreign Keys */
ALTER TABLE public.agendamento ADD CONSTRAINT agendamento_fk1 FOREIGN KEY (cidadao_id) REFERENCES public.cidadao(cidadao_id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE public.agendamento ADD CONSTRAINT agendamento_fk2 FOREIGN KEY (servico_id) REFERENCES public.servico(servico_id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE public.agendamento ADD CONSTRAINT agendamento_fk3 FOREIGN KEY (polo_atendimento_id) REFERENCES public.polo_atendimento(polo_atendimento_id) ON DELETE No Action ON UPDATE No Action;
ALTER TABLE public.agendamento ADD CONSTRAINT agendamento_fk4 FOREIGN KEY (status_agendamento_id) REFERENCES public.status_agendamento(status_agendamento_id) ON DELETE No Action ON UPDATE No Action;
/* Create Trigger */
CREATE TRIGGER agendamento_upd_trigger BEFORE UPDATE ON public.agendamento FOR EACH ROW EXECUTE PROCEDURE update_row_update_time();
/* Create Comments and Sequence */
COMMENT ON TABLE public.agendamento IS 'Tabela principal que armazena todos os agendamentos realizados.';
CREATE SEQUENCE public.agendamento_id_seq INCREMENT 1 START 1;


-- =====================================================================
-- ÍNDICES PARA OTIMIZAÇÃO DE CONSULTAS
-- =====================================================================
CREATE INDEX idx_agendamento_data_hora ON public.agendamento (agendamento_data_hora);
CREATE INDEX idx_agendamento_polo_id ON public.agendamento (polo_atendimento_id);
CREATE INDEX idx_agendamento_polo_data ON public.agendamento (polo_atendimento_id, agendamento_data_hora);
CREATE INDEX idx_horario_polo_dia ON public.horario_atendimento (polo_atendimento_id, horario_dia_semana);
CREATE INDEX idx_excecao_polo ON public.periodo_excecao (polo_atendimento_id);