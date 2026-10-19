-- Parte 1: Functions (10)

-- Crie fn_idade_paciente(p_id_paciente INT), que retorna a idade em anos do paciente. Retorne NULL se o paciente não existir.
CREATE OR REPLACE FUNCTION fn_idade_paciente(
    "p_id_paciente" INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    "idade_paciente" INTEGER;
BEGIN
    SELECT DATE_PART('year', AGE(CURRENT_DATE, "data_nascimento_paciente"))
    INTO "idade_paciente"
    FROM "paciente"
    WHERE "id_paciente" = "p_id_paciente";

    RETURN "idade_paciente";
END;
$$;

SELECT fn_idade_paciente(1);

-- Crie fn_dias_internacao(p_num_internacao INT), que retorna quantos dias durou a internação. Se ainda não tiver dt_hora_saida, conte até o momento atual.
CREATE OR REPLACE FUNCTION fn_dias_internacao(
    "p_num_internacao" INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	"data_saida" TIMESTAMP;
	"data_entrada" TIMESTAMP;
    "dias_internacao" INTEGER;
BEGIN

	SELECT "dt_hora_saida", "dt_hora_entrada"
	INTO "data_saida", "data_entrada"
	FROM "internacao"
	WHERE "num_internacao" = "p_num_internacao";

	IF("data_saida" IS NULL) THEN
		SELECT DATE_PART('days', AGE(CURRENT_DATE, "data_entrada"))
		INTO "dias_internacao";
	ELSE
		SELECT DATE_PART('days', AGE("data_saida", "data_entrada"))
		INTO "dias_internacao";

	END IF;

    RETURN "dias_internacao";
END;
$$;

SELECT fn_dias_internacao(2);

-- Crie fn_leito_ocupado(p_num_leito INT, p_num_quarto INT), que retorna TRUE se o leito tem uma internação sem dt_hora_saida. Lembre que a chave do leito é composta.
CREATE OR REPLACE FUNCTION fn_leito_ocupado(
    "p_num_leito" INTEGER,
	"p_num_quarto" INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
AS $$
DECLARE
    "leito_ocupado" BOOLEAN;
	"numero_da_internacao" INTEGER;
BEGIN
    SELECT "num_internacao"
    INTO "numero_da_internacao"
    FROM "internacao"
	WHERE
		"num_leito" = "p_num_leito" AND
		"num_quarto" = "p_num_quarto" AND
		"dt_hora_saida" IS NULL;

	IF ("numero_da_internacao" IS NULL) THEN
		"leito_ocupado" := FALSE;
	ELSE
		"leito_ocupado" := TRUE;
	END IF;

    RETURN "leito_ocupado";
END;
$$;

SELECT fn_leito_ocupado(1, 102);

-- Crie fn_leitos_livres(p_num_quarto INT), que retorna a quantidade de leitos livres do quarto, ou seja, leitos cadastrados menos leitos ocupados.
CREATE OR REPLACE FUNCTION fn_leitos_livres(
    "p_num_quarto" INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
	"quantidade_de_leitos_totais" INTEGER;
	"quantidade_de_leitos_ocupados" INTEGER;
    "quantidade_de_leitos_livres" INTEGER;
BEGIN

	SELECT "capacidade_leitos"
	INTO "quantidade_de_leitos_totais"
	FROM "quarto"
	WHERE "num_quarto" = "p_num_quarto";

    SELECT COUNT(*)
    INTO "quantidade_de_leitos_ocupados"
    FROM "internacao"
    WHERE "num_quarto" = "p_num_quarto" AND "dt_hora_saida" IS NULL;

	SELECT ("quantidade_de_leitos_totais" - "quantidade_de_leitos_ocupados")
	INTO "quantidade_de_leitos_livres";

    RETURN "quantidade_de_leitos_livres";
END;
$$;

SELECT fn_leitos_livres(102);

-- Crie fn_taxa_ocupacao(p_num_quarto INT), que retorna a taxa de ocupação do quarto em porcentagem (NUMERIC com 1 casa decimal), calculada sobre capacidade_leitos.
CREATE OR REPLACE FUNCTION fn_taxa_ocupacao(
    "p_num_quarto" INTEGER
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
	"quantidade_de_leitos_totais" INTEGER;
	"quantidade_de_leitos_ocupados" INTEGER;
    "taxa_de_ocupacao" NUMERIC;
BEGIN
    SELECT "capacidade_leitos"
	INTO "quantidade_de_leitos_totais"
	FROM "quarto"
	WHERE "num_quarto" = "p_num_quarto";

	IF "quantidade_de_leitos_totais" IS NULL OR "quantidade_de_leitos_totais" = 0 THEN
        RETURN 0.0;
    END IF;

    SELECT COUNT(*)
    INTO "quantidade_de_leitos_ocupados"
    FROM "internacao"
    WHERE "num_quarto" = "p_num_quarto" AND "dt_hora_saida" IS NULL;

	SELECT ROUND(("quantidade_de_leitos_ocupados"::NUMERIC / "quantidade_de_leitos_totais") * 100, 1)
    INTO "taxa_de_ocupacao";

    RETURN "taxa_de_ocupacao";
END;
$$;

SELECT fn_taxa_ocupacao(102);

-- Crie fn_nome_convenio(p_id_paciente INT), que retorna o nome do convênio do paciente ou o texto 'Sem convênio' caso ele não seja associado.
CREATE OR REPLACE FUNCTION fn_nome_convenio(
    "p_id_paciente" INTEGER
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    "convenio" VARCHAR;
BEGIN
	SELECT c."nome_convenio"
	INTO "convenio"
	FROM "paciente" p
	JOIN "associado" a ON a."id_paciente" = p."id_paciente"
	JOIN "convenio_medico" c ON c."id_convenio_medico" = a."id_convenio_medico"
	WHERE p."id_paciente" = "p_id_paciente";

	IF ("convenio" IS NULL) THEN
		"convenio" := 'Sem convênio';
	END IF;

    RETURN "convenio";
END;
$$;

SELECT fn_nome_convenio(1);

-- Crie fn_internacoes_medico(p_cod_funcional INT), que retorna quantas internações em andamento o médico efetivo tem sob sua responsabilidade.
CREATE OR REPLACE FUNCTION fn_internacoes_medico(
    "p_cod_funcional" INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    "quantidade" INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO "quantidade"
    FROM "internacao" i
	JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
	JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
    WHERE m."cod_funcional" = "p_cod_funcional" AND i."dt_hora_alta" IS NULL;

    RETURN "quantidade";
END;
$$;

SELECT fn_internacoes_medico(5);

-- Crie fn_internacoes_ativas(), que retorna uma tabela (RETURNS TABLE) com paciente, quarto, leito, motivo e dias de internação de todas as internações em andamento.
DROP FUNCTION fn_internacoes_ativas();
CREATE OR REPLACE FUNCTION fn_internacoes_ativas()
RETURNS TABLE (
    nome_paciente VARCHAR(45),
    num_quarto    SMALLINT,
    num_leito     SMALLINT,
    motivo        VARCHAR(35),
    dias          INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        p."nome_paciente",
        i."num_quarto",
        i."num_leito",
        i."motivo",
        (CURRENT_DATE - i."dt_hora_entrada"::DATE)
    FROM "internacao" i
    JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
    WHERE i."dt_hora_saida" IS NULL;
END;
$$;

SELECT fn_internacoes_ativas();

-- Crie fn_medicos_por_especialidade(p_nome TEXT), que retorna uma tabela com o nome e o CRM dos médicos que possuem aquela especialidade em especializacao.
CREATE OR REPLACE FUNCTION fn_medicos_por_especialidade(
	"p_nome" TEXT
)
RETURNS TABLE (
    "nome_medico" VARCHAR(45),
    "crm" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        m."nome_medico",
        m."crm"
    FROM "medico" m
    JOIN "especializacao" ez ON ez."medico_cod_funcional" = m."cod_funcional"
	JOIN "especialidade" ed ON ed."id_especialidade" = ez."especialidade_id_especialidade"
    WHERE ed."nome_especialidade" = "p_nome";
END;
$$;

SELECT fn_medicos_por_especialidade('Clinica Geral');

-- Crie fn_historico_paciente(p_id_paciente INT), que retorna uma tabela com todas as internações do paciente (entrada, saída, motivo, quarto, médico responsável) da mais recente para a mais antiga.
CREATE OR REPLACE FUNCTION fn_historico_paciente(
	"p_id_paciente" INTEGER
)
RETURNS TABLE (
	"dt_hora_entrada" TIMESTAMP,
	"dt_hora_saida" TIMESTAMP,
	"motivo" VARCHAR(35),
	"quarto" SMALLINT,
	"cod_funcional_efetivo" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        i."dt_hora_entrada",
        i."dt_hora_saida",
		i."motivo",
		i."num_quarto",
		i."cod_funcional_efetivo"
    FROM "internacao" i
    WHERE i."id_paciente" = "p_id_paciente"
	ORDER BY i."dt_hora_entrada" DESC;
END;
$$;

SELECT fn_historico_paciente(1);

-- Parte 2: Procedures (10)

-- Crie sp_cadastrar_paciente(...), que recebe os dados do paciente e insere na tabela. Valide se sexo é 'M' ou 'F' e levante uma exceção com mensagem clara caso não seja.
CREATE OR REPLACE PROCEDURE sp_cadastrar_paciente(
    id_paciente INTEGER,
    nome_paciente VARCHAR(45),
    data_nascimento_paciente DATE,
    sexo_paciente CHAR(1),
    nome_responsavel VARCHAR(45)
)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (sexo_paciente NOT IN ('M', 'F')) THEN
		RAISE EXCEPTION 'sexo_paciente esta invalido porque não é M ou F';
	END IF;

    INSERT INTO "paciente" (
		"id_paciente",
		"nome_paciente",
		"data_nascimento_paciente",
		"sexo_paciente",
		"nome_responsavel"
	)
    VALUES (id_paciente, nome_paciente, data_nascimento_paciente, sexo_paciente, nome_responsavel);
END;
$$;

CALL sp_cadastrar_paciente(6, 'Not João Pereira', '1966-09-30', 'M', NULL);

-- Crie sp_associar_convenio(p_id_paciente, p_id_convenio, p_plano, p_numero), que verifica se o paciente e o convênio existem e se a associação já não foi feita antes de inserir em associado.
CREATE OR REPLACE PROCEDURE sp_associar_convenio(
    "p_id_paciente" INTEGER,
    "p_id_convenio" INTEGER,
    "p_plano" VARCHAR(45),
    "p_numero" INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    "paciente_existe"   INTEGER;
	"convenio_existe"   INTEGER;
	"associacao_existe" INTEGER;
BEGIN

	SELECT COUNT(*)
	INTO "paciente_existe"
	FROM "paciente"
	WHERE "id_paciente" = "p_id_paciente";

	IF ("paciente_existe" = 0) THEN
		RAISE EXCEPTION 'Paciente nao existe';
	END IF;

	SELECT COUNT(*)
	INTO "convenio_existe"
	FROM "convenio_medico"
	WHERE "id_convenio_medico" = "p_id_convenio";

	IF ("convenio_existe" = 0) THEN
		RAISE EXCEPTION 'Convenio nao existe';
	END IF;

	SELECT COUNT(*)
	INTO "associacao_existe"
	FROM "associado"
	WHERE "id_paciente" = "p_id_paciente" AND "id_convenio_medico" = "p_id_convenio";

	IF ("associacao_existe" > 0) THEN
		RAISE EXCEPTION 'Associacao ja existe';
	END IF;

    INSERT INTO "associado" (
		"id_paciente",
		"id_convenio_medico",
		"tipo_de_plano",
		"numero_associado"
	)
    VALUES ("p_id_paciente", "p_id_convenio", "p_plano", "p_numero");
END;
$$;

CALL sp_associar_convenio(6, 2, 'Premium', 123456);

-- Crie sp_internar_paciente(p_id_paciente, p_num_leito, p_num_quarto, p_motivo, p_cod_medico), que valida se o leito está livre e se o paciente é associado, e depois insere a internação com situacao_internacao = 'Em Andamento'.
CREATE OR REPLACE PROCEDURE sp_internar_paciente(
    "p_id_paciente" INTEGER,
    "p_num_leito" SMALLINT,
    "p_num_quarto" SMALLINT,
    "p_motivo" VARCHAR(35),
    "p_cod_medico" INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
	"leito_livre" BOOLEAN;
	"esta_associado" INTEGER;
BEGIN
	SELECT fn_leito_ocupado("p_num_leito", "p_num_quarto")
	INTO "leito_livre";
	
	IF ("leito_livre" = FALSE) THEN
		RAISE EXCEPTION 'O leito esta ocupado';
	END IF;

	SELECT COUNT(*)
	INTO "esta_associado"
	FROM "associado"
	WHERE "id_paciente" = "p_id_paciente";

	IF ("esta_associado" = 0) THEN
		RAISE EXCEPTION 'O paciente nao esta associado a nenhum convenio';
	END IF;

    INSERT INTO "internacao" (
		"dt_hora_entrada",
		"dt_hora_saida",
		"dt_hora_alta",
		"motivo",
		"situacao_internacao",
		"id_paciente",
		"num_leito",
		"num_quarto",
		"id_paciente_associado",
		"cod_funcional_efetivo"
	)
    VALUES (
		CURRENT_TIMESTAMP,
		NULL,
		NULL,
		"p_motivo",
		'Em Andamento',
		"p_id_paciente",
		"p_num_leito",
		"p_num_quarto",
		NULL,
		"p_cod_medico"
	);
END;
$$;

CALL sp_internar_paciente(
    5::integer, 
    101::smallint, 
    2::smallint, 
    'Nada'::varchar(35), 
    1::integer
);

-- Crie sp_dar_alta(p_num_internacao), que preenche dt_hora_alta com o momento atual e muda a situação para 'Alta'. Levante exceção se a internação não existir ou já tiver alta.
CREATE OR REPLACE PROCEDURE sp_dar_alta(
    "p_num_internacao" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE "internacao"
	SET "dt_hora_alta" = CURRENT_TIMESTAMP, "situacao_internacao" = 'Alta'
	WHERE "num_internacao" = "p_num_internacao";
END;
$$;

CALL sp_dar_alta(2);

-- Crie sp_registrar_saida(p_num_internacao), que preenche dt_hora_saida com o momento atual, mas só se a alta já tiver sido dada.
CREATE OR REPLACE PROCEDURE sp_registrar_saida(
    "p_num_internacao" INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
	"alta" TIMESTAMP;
BEGIN

	SELECT "dt_hora_alta"
	INTO "alta"
	FROM "internacao"
	WHERE "num_internacao" = "p_num_internacao";

	IF ("alta" IS NULL) THEN
		RAISE EXCEPTION 'Ainda nao foi computada a alta';
	END IF;

	UPDATE "internacao"
	SET "dt_hora_saida" = CURRENT_TIMESTAMP
	WHERE "num_internacao" = "p_num_internacao";
END;
$$;

CALL sp_registrar_saida(2);

-- Crie sp_transferir_paciente(p_num_internacao, p_novo_leito, p_novo_quarto), que move uma internação em andamento para outro leito, desde que ele esteja livre.
CREATE OR REPLACE PROCEDURE sp_transferir_paciente(
	"p_num_internacao" INTEGER,
	"p_novo_leito" SMALLINT,
	"p_novo_quarto" SMALLINT
)
LANGUAGE plpgsql
AS $$
DECLARE
	"leito_disponivel" BOOLEAN;
BEGIN
	SELECT fn_leito_ocupado("p_novo_leito", "p_novo_quarto")
	INTO "leito_disponivel";
	
	IF ("leito_disponivel" = FALSE) THEN
		RAISE EXCEPTION 'O leito esta ocupado';
	END IF;

	UPDATE "internacao"
	SET "num_leito" = "p_novo_leito", "num_quarto" = "p_novo_quarto"
	WHERE "num_internacao" = "p_num_internacao";
END;
$$;

CALL sp_transferir_paciente(2::INTEGER, 3::SMALLINT, 103::SMALLINT);

-- Crie sp_cadastrar_medico_efetivo(p_nome, p_sexo, p_nascimento, p_crm, p_especialidade), que insere em medico e em medico_efetivo, e também registra a especialidade em especializacao (buscando o id pelo nome). Tudo deve ocorrer na mesma transação.
CREATE OR REPLACE PROCEDURE sp_cadastrar_medico_efetivo(
    "p_nome" VARCHAR(45),
	"p_sexo" CHAR(1),
	"p_nascimento" DATE,
	"p_crm" INTEGER,
	"p_especialidade" VARCHAR(45)
)
LANGUAGE plpgsql
AS $$
DECLARE
	"id_do_medico" INTEGER;
	"id_da_especialidade" INTEGER;
BEGIN
	INSERT INTO "medico" ("nome_medico", "sexo_medico", "data_nascimento", "situacao_medico", "crm")
	VALUES ("p_nome", "p_sexo", "p_nascimento", 'Ativo', "p_crm")
	RETURNING "cod_funcional" INTO "id_do_medico";

	INSERT INTO "medico_efetivo" ("cod_funcional_efetivo", "especialidade")
	VALUES ("id_do_medico", "p_especialidade");

	SELECT "id_especialidade"
	INTO "id_da_especialidade"
	FROM "especialidade"
	WHERE "nome_especialidade" = "p_especialidade";
	
	INSERT INTO "especializacao" ("medico_cod_funcional", "especialidade_id_especialidade")
	VALUES ("id_do_medico", "id_da_especialidade");

END;
$$;

CALL sp_cadastrar_medico_efetivo('Jão', 'M', '01-01-2001', 1234567, 'Cardiologia');

-- Crie sp_cadastrar_residente(p_nome, p_sexo, p_nascimento, p_crm, p_cod_orientador, p_data_inicio), que insere em medico (com situação 'Em Treinamento') e em medico_residente, validando que o orientador é um médico efetivo.
CREATE OR REPLACE PROCEDURE sp_cadastrar_medico_efetivo(
    "p_nome" VARCHAR(45),
	"p_sexo" CHAR(1),
	"p_nascimento" DATE,
	"p_crm" INTEGER,
	"p_cod_orientador" INTEGER,
	"p_data_inicio" DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
	"medico_efetivo" INTEGER;
	"id_do_medico" INTEGER;
	"id_da_especialidade" INTEGER;
BEGIN
	SELECT COUNT(*)
	INTO "medico_efetivo"
	FROM "medico" m
	JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = m."cod_funcional"
	WHERE m."cod_funcional" = "p_cod_orientador";

	IF ("medico_efetivo" = 0) THEN
		RAISE EXCEPTION 'O medico nao e efetivo';
	END IF;

	INSERT INTO "medico" ("nome_medico", "sexo_medico", "data_nascimento", "situacao_medico", "crm")
	VALUES ("p_nome", "p_sexo", "p_nascimento", 'Em Treinamento', "p_crm")
	RETURNING "cod_funcional" INTO "id_do_medico";

	INSERT INTO "medico_residente" ("cod_funcional_residente", "medico_efetivo_cod_funcional_efetivo", "data_inicio_orientacao")
	VALUES ("id_do_medico", "p_cod_orientador", "p_data_inicio");

END;
$$;

CALL sp_cadastrar_medico_efetivo('jaojao', 'M', '1980-08-25', 456, 2, '02-02-2002');

-- Crie sp_encerrar_orientacao(p_cod_residente), que preenche data_termino_orientacao com a data atual, se ela ainda estiver nula.
CREATE OR REPLACE PROCEDURE sp_encerrar_orientacao(
    IN p_cod_residente INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE medico_residente
    SET data_termino_orientacao = CURRENT_DATE
    WHERE cod_funcional_residente = p_cod_residente
      AND data_termino_orientacao IS NULL;
END;
$$;

CALL sp_encerrar_orientacao(4);

-- Crie sp_limpar_internacoes(p_dias INT, INOUT p_removidas INT), que exclui as internações encerradas há mais de p_dias dias (pela dt_hora_saida) e devolve, no parâmetro INOUT, quantas foram removidas.
CREATE OR REPLACE PROCEDURE sp_limpar_internacoes(
    IN p_dias INT,
    INOUT p_removidas INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    DELETE FROM internacao
    WHERE dt_hora_saida IS NOT NULL
      AND dt_hora_saida < CURRENT_TIMESTAMP - (p_dias * INTERVAL '1 day');

    GET DIAGNOSTICS p_removidas = ROW_COUNT;
END;
$$;

CALL sp_limpar_internacoes(30, 0);

-- Parte 3: Triggers (10)

-- Cada exercício exige a function de trigger (RETURNS TRIGGER) e o comando CREATE TRIGGER.

-- BEFORE INSERT em internacao: impeça a internação em um leito que já tenha outra em andamento.
CREATE OR REPLACE FUNCTION cadastra_internacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	count_internacao_leito INTEGER;
BEGIN
    SELECT COUNT(*)
	INTO count_internacao_leito
	FROM "internacao"
	WHERE "leito" = NEW."num_leito" AND "dt_hora_saida" IS NULL;
	
	IF count_internacao_leito > 0 THEN
        RAISE EXCEPTION 'Leito ocupado';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_leito_ocupado
BEFORE INSERT
ON "internacao"
FOR EACH ROW
EXECUTE FUNCTION cadastra_internacao();

-- BEFORE INSERT OR UPDATE em internacao: garanta que dt_hora_saida e dt_hora_alta não sejam anteriores a dt_hora_entrada.
CREATE OR REPLACE FUNCTION confere_dt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	IF (NEW."dt_hora_entrada" > NEW."dt_hora_saida") THEN
        RAISE EXCEPTION 'Data saida esta menor do que a data entrada';
	ELSIF (NEW."dt_hora_entrada" > NEW."dt_hora_alta") THEN
		RAISE EXCEPTION 'Data alta esta menor do que a data entrada';
    END IF;
	
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_datas
BEFORE INSERT OR UPDATE
ON "internacao"
FOR EACH ROW
EXECUTE FUNCTION confere_dt();

-- BEFORE INSERT em internacao: se situacao_internacao vier nula, preencha com 'Em Andamento', e se dt_hora_saida vier preenchida, preencha com 'Alta'.
CREATE OR REPLACE FUNCTION confere_dt()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
	IF (NEW."dt_hora_entrada" > NEW."dt_hora_saida") THEN
        RAISE EXCEPTION 'Data saida esta menor do que a data entrada';
	ELSIF (NEW."dt_hora_entrada" > NEW."dt_hora_alta") THEN
		RAISE EXCEPTION 'Data alta esta menor do que a data entrada';
    END IF;
	
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_datas
BEFORE INSERT OR UPDATE
ON "internacao"
FOR EACH ROW
EXECUTE FUNCTION confere_dt();

-- BEFORE INSERT em internacao: como id_paciente_associado referencia paciente, valide que ele é igual a id_paciente e que esse paciente tem pelo menos um registro em associado.
CREATE OR REPLACE FUNCTION confere_associado()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	"associacoes" INTEGER;
BEGIN

	SELECT COUNT(*)
	INTO "associacoes"
	FROM "paciente" p
	JOIN "associado" a ON a."id_paciente" = NEW."id_paciente_associado"
	WHERE NEW."id_paciente_associado" = p."id_paciente";
	
	IF ("associacoes" = 0) THEN
        RAISE EXCEPTION 'Erro';
    END IF;
	
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_associado
BEFORE INSERT
ON "internacao"
FOR EACH ROW
EXECUTE FUNCTION confere_associado();

-- BEFORE INSERT em leito: impeça cadastrar mais leitos do que a capacidade_leitos do quarto.
CREATE OR REPLACE FUNCTION confere_quarto()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
	"capacidade_quarto" SMALLINT;
	"leitos_atualmente_quarto" INTEGER;
BEGIN

	SELECT "capacidade_leitos"
    INTO "capacidade_quarto"
    FROM "quarto"
    WHERE "num_quarto" = NEW."num_quarto";

    SELECT COUNT(*)
    INTO "leitos_atualmente_quarto"
    FROM "leito"
    WHERE "num_quarto" = NEW."num_quarto";

	IF ("capacidade_quarto" <= "leitos_atualmente_quarto") THEN
        RAISE EXCEPTION 'Quarto cheio';
    END IF;
	
    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_quarto
BEFORE INSERT
ON "leito"
FOR EACH ROW
EXECUTE FUNCTION confere_quarto();

-- BEFORE INSERT OR UPDATE em medico_residente: só aceite como residente quem tem situacao_medico = 'Em Treinamento', e só aceite como orientador quem está 'Ativo'.
CREATE OR REPLACE FUNCTION valida_medico_residente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_situacao_residente CHAR(15);
    v_situacao_orientador CHAR(15);
BEGIN
    SELECT situacao_medico
    INTO v_situacao_residente
    FROM medico
    WHERE cod_funcional = NEW.cod_funcional_residente;

    SELECT m.situacao_medico
    INTO v_situacao_orientador
    FROM medico m
    JOIN medico_efetivo me
      ON me.cod_funcional_efetivo = m.cod_funcional
    WHERE me.cod_funcional_efetivo =
          NEW.medico_efetivo_cod_funcional_efetivo;

    IF v_situacao_residente <> 'Em Treinamento' THEN
        RAISE EXCEPTION
            'O médico residente deve estar Em Treinamento';
    END IF;

    IF v_situacao_orientador <> 'Ativo' THEN
        RAISE EXCEPTION
            'O médico orientador deve estar Ativo';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_valida_medico_residente
BEFORE INSERT OR UPDATE
ON medico_residente
FOR EACH ROW
EXECUTE FUNCTION valida_medico_residente();

-- BEFORE INSERT OR UPDATE em paciente: se o paciente tiver menos de 18 anos, nome_responsavel é obrigatório.
CREATE OR REPLACE FUNCTION valida_responsavel_paciente()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF AGE(CURRENT_DATE, NEW.data_nascimento_paciente)
       < INTERVAL '18 years'
       AND NULLIF(TRIM(NEW.nome_responsavel), '') IS NULL THEN

        RAISE EXCEPTION
            'Pacientes menores de 18 anos devem ter um responsável';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_valida_responsavel_paciente
BEFORE INSERT OR UPDATE
ON paciente
FOR EACH ROW
EXECUTE FUNCTION valida_responsavel_paciente();

-- AFTER INSERT OR UPDATE OR DELETE em internacao: crie a tabela log_internacao (id, operação, data/hora, usuário via current_user, situação antiga e nova) e registre cada alteração nela.
CREATE TABLE IF NOT EXISTS log_internacao (
    id SERIAL PRIMARY KEY,
    operacao VARCHAR(10) NOT NULL,
    data_hora TIMESTAMP WITH TIME ZONE NOT NULL
        DEFAULT CURRENT_TIMESTAMP,
    usuario NAME NOT NULL DEFAULT CURRENT_USER,
    situacao_antiga CHAR(15),
    situacao_nova CHAR(15)
);

CREATE OR REPLACE FUNCTION registra_log_internacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO log_internacao (
            operacao, usuario,
            situacao_antiga, situacao_nova
        )
        VALUES (
            TG_OP, CURRENT_USER,
            NULL, NEW.situacao_internacao
        );

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO log_internacao (
            operacao, usuario,
            situacao_antiga, situacao_nova
        )
        VALUES (
            TG_OP, CURRENT_USER,
            OLD.situacao_internacao,
            NEW.situacao_internacao
        );

        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO log_internacao (
            operacao, usuario,
            situacao_antiga, situacao_nova
        )
        VALUES (
            TG_OP, CURRENT_USER,
            OLD.situacao_internacao, NULL
        );

        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER trigger_log_internacao
AFTER INSERT OR UPDATE OR DELETE
ON internacao
FOR EACH ROW
EXECUTE FUNCTION registra_log_internacao();

-- BEFORE UPDATE em internacao: impeça reabrir uma internação (mudar de 'Alta' para 'Em Andamento') e impeça alterar dt_hora_entrada.
CREATE OR REPLACE FUNCTION valida_update_internacao()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.dt_hora_entrada IS DISTINCT FROM OLD.dt_hora_entrada THEN
        RAISE EXCEPTION
            'Não é permitido alterar a data e hora de entrada';
    END IF;

    IF OLD.situacao_internacao = 'Alta'
       AND NEW.situacao_internacao = 'Em Andamento' THEN
        RAISE EXCEPTION
            'Não é permitido reabrir uma internação com Alta';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trigger_valida_update_internacao
BEFORE UPDATE
ON internacao
FOR EACH ROW
EXECUTE FUNCTION valida_update_internacao();

-- BEFORE DELETE em medico_efetivo: bloqueie a exclusão se o médico tiver internações em andamento ou residentes com orientação ainda ativa.
CREATE OR REPLACE FUNCTION valida_delete_medico_efetivo()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM internacao
        WHERE cod_funcional_efetivo = OLD.cod_funcional_efetivo
          AND situacao_internacao = 'Em Andamento'
    ) THEN
        RAISE EXCEPTION
            'Não é possível excluir: médico possui internações em andamento';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM medico_residente
        WHERE medico_efetivo_cod_funcional_efetivo =
              OLD.cod_funcional_efetivo
          AND data_termino_orientacao IS NULL
    ) THEN
        RAISE EXCEPTION
            'Não é possível excluir: médico possui orientações ativas';
    END IF;

    RETURN OLD;
END;
$$;

CREATE TRIGGER trigger_valida_delete_medico_efetivo
BEFORE DELETE
ON medico_efetivo
FOR EACH ROW
EXECUTE FUNCTION valida_delete_medico_efetivo();
