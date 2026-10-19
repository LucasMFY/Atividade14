-- Parte 1: INNER JOIN com 2 a 3 tabelas

-- 1. Liste o nome de cada paciente internado, o motivo e a data de entrada da internação.
SELECT p."nome_paciente", i."motivo", i."dt_hora_entrada"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente";

-- 2. Exiba o nome do paciente, o número do quarto, o tipo do quarto, o número do leito e o tipo do leito de cada internação.
SELECT p."nome_paciente", q."num_quarto", l."num_leito", l."tipo_leito"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
JOIN "quarto" q ON q."num_quarto" = i."num_quarto"
JOIN "leito" l ON l."num_leito" = i."num_leito" AND l."num_quarto" = i."num_quarto";

-- 3. Liste o nome de cada paciente que tem convênio, com o nome do convênio, o tipo de plano e o número de associado.
SELECT p."nome_paciente", c."nome_convenio", a."tipo_de_plano", a."numero_associado"
FROM "paciente" p
JOIN "associado" a ON a."id_paciente" = p."id_paciente"
JOIN "convenio_medico" c ON c."id_convenio_medico" = a."id_convenio_medico";

-- 4. Mostre o nome, o CRM e a especialidade (de medico_efetivo) de cada médico efetivo.
SELECT m."nome_medico", m."crm", ed."nome_especialidade"
FROM "medico" m
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = m."cod_funcional"
JOIN "especializacao" ez ON ez."medico_cod_funcional" = m."cod_funcional"
JOIN "especialidade" ed ON ed."id_especialidade" = ez."especialidade_id_especialidade";

-- 5. Exiba o nome de cada médico e o nome de cada especialidade registrada em especializacao.
SELECT m."nome_medico", ed."nome_especialidade"
FROM "medico" m
JOIN "especializacao" ez ON ez."medico_cod_funcional" = m."cod_funcional"
JOIN "especialidade" ed ON ed."id_especialidade" = ez."especialidade_id_especialidade";

-- 6. Liste todos os leitos com o tipo do leito, o tipo do quarto e a capacidade do quarto.
SELECT l."tipo_leito", q."tipo_quarto", q."capacidade_leitos"
FROM "quarto" q
JOIN "leito" l ON l."num_quarto" = q."num_quarto";

-- Parte 2: JOINs com 4 ou mais tabelas

-- 1. Para cada internação, exiba o nome do paciente, o nome do médico efetivo responsável, o motivo e o número do quarto.
SELECT p."nome_paciente", m."nome_medico", i."motivo", q."num_quarto"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
JOIN "quarto" q ON q."num_quarto" = i."num_quarto";

-- 2. Liste o paciente, o convênio, o tipo de plano, o médico responsável e o tipo do quarto de cada internação (use associado e convenio_medico).
SELECT p."nome_paciente", c."nome_convenio", a."tipo_de_plano", m."nome_medico", q."tipo_quarto"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
JOIN "associado" a ON a."id_paciente" = p."id_paciente"
JOIN "convenio_medico" c ON c."id_convenio_medico" = a."id_convenio_medico"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
JOIN "quarto" q ON q."num_quarto" = i."num_quarto";

-- 3. Exiba o nome do paciente, o médico responsável e a especialidade dele (via especializacao e especialidade) das internações em andamento.
SELECT p."nome_paciente", m."nome_medico", ed."nome_especialidade"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
JOIN "especializacao" ez ON ez."medico_cod_funcional" = m."cod_funcional"
JOIN "especialidade" ed ON ed."id_especialidade" = ez."especialidade_id_especialidade";

-- 4. Liste os pacientes internados em quartos do tipo UTI, com convênio e médico responsável.
SELECT p."nome_paciente", /*q."tipo_quarto", c."nome_convenio",*/ m."nome_medico"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
JOIN "associado" a ON a."id_paciente" = p."id_paciente"
JOIN "convenio_medico" c ON c."id_convenio_medico" = a."id_convenio_medico"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
JOIN "quarto" q ON q."num_quarto" = i."num_quarto"
WHERE
	q."tipo_quarto" = 'UTI' AND
	a."id_convenio_medico" IS NOT NULL AND
	i."cod_funcional_efetivo" IS NOT NULL;

-- 5. Mostre as internações encerradas com paciente, quarto, leito, médico e convênio, ordenadas pela data de entrada.
SELECT p."nome_paciente", i."num_quarto", i."num_leito", m."nome_medico", c."nome_convenio"
FROM "internacao" i
JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
JOIN "associado" a ON a."id_paciente" = p."id_paciente"
JOIN "convenio_medico" c ON c."id_convenio_medico" = a."id_convenio_medico"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
JOIN "quarto" q ON q."num_quarto" = i."num_quarto"
JOIN "leito" l ON l."num_quarto" = q."num_quarto"
WHERE i."dt_hora_alta" IS NOT NULL
ORDER BY "dt_hora_entrada" ASC;

-- Parte 3: Self JOIN e JOIN múltiplo na mesma tabela

-- 1. Liste cada médico residente com o nome do médico efetivo que o orienta (duas vezes medico) e o período de orientação.
SELECT mrm."nome_medico", mem."nome_medico", AGE(current_date, mr."data_inicio_orientacao")
FROM "medico_residente" mr
JOIN "medico" mrm ON mrm."cod_funcional" = mr."cod_funcional_residente"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = mr."medico_efetivo_cod_funcional_efetivo"
JOIN "medico" mem ON mem."cod_funcional" = me."cod_funcional_efetivo";

-- 2. Exiba o nome de cada médico efetivo e o nome dos residentes que ele orienta.
SELECT mem."nome_medico", mrm."nome_medico"
FROM "medico_residente" mr
JOIN "medico" mrm ON mrm."cod_funcional" = mr."cod_funcional_residente"
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = mr."medico_efetivo_cod_funcional_efetivo"
JOIN "medico" mem ON mem."cod_funcional" = me."cod_funcional_efetivo";

-- 3. Liste os pares de pacientes que têm o mesmo convênio (self join em associado, sem repetir pares nem parear o paciente consigo mesmo).
SELECT p1."nome_paciente", p2."nome_paciente"
FROM "paciente" p1
JOIN "associado" a1 ON a1."id_paciente" = p1."id_paciente"
JOIN "associado" a2 ON a2."id_convenio_medico" = a1."id_convenio_medico"
JOIN "paciente" p2 ON p2."id_paciente" = a2."id_paciente" AND p2."id_paciente" <> p1."id_paciente";

-- 4. Liste os pares de médicos que compartilham a mesma especialidade em especializacao.
SELECT m1."nome_medico", m2."nome_medico"
FROM "medico" m1
JOIN "especializacao" e1 ON e1."medico_cod_funcional" = m1."cod_funcional"
JOIN "especializacao" e2 ON e2."especialidade_id_especialidade" = e1."especialidade_id_especialidade"
JOIN "medico" m2 ON m2."cod_funcional" = e2."medico_cod_funcional" AND m2."cod_funcional" > m1."cod_funcional";

-- 5. Liste os pares de pacientes que já foram internados no mesmo quarto (self join em internacao).
SELECT p1."nome_paciente", p2."nome_paciente"
FROM "paciente" p1
JOIN "internacao" i1 ON i1."id_paciente" = p1."id_paciente"
JOIN "internacao" i2 ON i2."num_internacao" = i1."num_internacao"
JOIN "paciente" p2 ON p2."id_paciente" > i2."id_paciente" AND i1."num_quarto" = i2."num_quarto";
/*
SELECT p1."nome_paciente", p2."nome_paciente"
FROM "paciente" p1
JOIN "internacao" i1 ON i1."id_paciente" = p1."id_paciente"
JOIN "paciente" p2 ON p2."id_paciente" > i1."id_paciente";
*/

-- 6. Exiba, para cada internação, o nome do paciente internado e o nome do paciente referenciado em id_paciente_associado (dois JOINs em paciente), destacando os casos em que são pessoas diferentes.
SELECT p1."nome_paciente", p2."nome_paciente"
FROM "paciente" p1
JOIN "internacao" i1 ON i1."id_paciente" = p1."id_paciente"
JOIN "paciente" p2 ON p2."id_paciente" > i1."id_paciente_associado";

-- Parte 4: LEFT, RIGHT, FULL e CROSS JOIN

-- 1. Liste todos os pacientes e suas internações, incluindo os que nunca foram internados.
SELECT p."nome_paciente", i."num_internacao"
FROM "paciente" p
LEFT JOIN "internacao" i ON i."id_paciente" = p."id_paciente";

-- 2. Liste todos os quartos com seus leitos, incluindo quartos que não têm nenhum leito cadastrado.
SELECT q."num_quarto", l."num_leito"
FROM "quarto" q
LEFT JOIN "leito" l ON l."num_quarto" = q."num_quarto";

-- 3. Liste os leitos que nunca foram usados em nenhuma internação.
SELECT l."num_leito", q."num_quarto", i."num_internacao"
FROM "leito" l
JOIN "quarto" q ON q."num_quarto" = l."num_quarto"
LEFT JOIN "internacao" i ON l."num_leito" <> i."num_leito" AND l."num_quarto" <> q."num_quarto";

-- 4. Liste os médicos que não têm nenhuma especialização cadastrada.
SELECT m."nome_medico", e."especialidade_id_especialidade"
FROM "medico" m
LEFT JOIN "especializacao" e ON e."medico_cod_funcional" = m."cod_funcional"
WHERE e."especialidade_id_especialidade" IS NULL;

-- 5. Liste os convênios que não têm nenhum paciente associado.
SELECT c."nome_convenio"
FROM "convenio_medico" c
LEFT JOIN "associado" a ON a."id_convenio_medico" = c."id_convenio_medico"
WHERE a."id_paciente" IS NULL;

-- 6. Liste os pacientes sem convênio.
SELECT p."nome_paciente"
FROM "paciente" p
LEFT JOIN "associado" a ON a."id_paciente" = p."id_paciente"
WHERE a."id_convenio_medico" IS NULL;

-- 7. Liste os médicos efetivos que nunca foram responsáveis por uma internação.
SELECT m."nome_medico"
FROM "medico" m
JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = m."cod_funcional"
LEFT JOIN "internacao" i ON i."cod_funcional_efetivo" = me."cod_funcional_efetivo"
WHERE i."cod_funcional_efetivo" IS NULL;

-- 8. Use FULL JOIN entre medico_efetivo (campo especialidade) e especialidade (campo nome_especialidade) para encontrar especialidades sem médico efetivo e médicos efetivos com especialidade não cadastrada.
SELECT m."nome_medico", ep."nome_especialidade"
FROM "medico" m
FULL JOIN "especializacao" es ON es."medico_cod_funcional" = m."cod_funcional"
FULL JOIN "especialidade" ep ON ep."id_especialidade" = es."especialidade_id_especialidade"
WHERE es."medico_cod_funcional" IS NULL OR es."especialidade_id_especialidade" IS NULL;

-- 9. Use CROSS JOIN entre médicos efetivos e especialidades para gerar todas as combinações, e depois, com LEFT JOIN em especializacao, mostre apenas as combinações que ainda não existem.
SELECT 
    me."cod_funcional_efetivo",
    ep."id_especialidade",
    ep."nome_especialidade"
FROM "medico_efetivo" me
CROSS JOIN "especialidade" ep
LEFT JOIN "especializacao" es 
    ON es."medico_cod_funcional" = me."cod_funcional_efetivo" 
   AND es."especialidade_id_especialidade" = ep."id_especialidade"
WHERE es."medico_cod_funcional" IS NULL;

-- Parte 5: JOIN com agregação

-- 1. Conte as internações por convênio, incluindo convênios com zero internações.
SELECT c."nome_convenio", COUNT(i."num_internacao")
FROM "convenio_medico" c
JOIN "associado" a ON a."id_paciente" = c."id_convenio_medico"
JOIN "paciente" p ON p."id_paciente" = a."id_paciente"
LEFT JOIN "internacao" i ON i."id_paciente" = p."id_paciente"
GROUP BY c."nome_convenio";

-- 2. Conte as internações por tipo de quarto.
SELECT q."tipo_quarto", COUNT(i."num_internacao")
FROM "quarto" q
LEFT JOIN "internacao" i ON i."num_quarto" = q."num_quarto"
GROUP BY q."tipo_quarto";

-- 3. Para cada quarto, compare capacidade_leitos com a quantidade real de leitos cadastrados e liste os quartos em que os valores não batem.
WITH leitos_por_quarto AS (
    SELECT 
        q."num_quarto", -- ou "numero_quarto" dependendo do seu schema
        q."capacidade_leitos",
        COUNT(l."num_leito") AS "leitos_reais"
    FROM "quarto" q
    LEFT JOIN "leito" l ON l."num_quarto" = q."num_quarto"
    GROUP BY q."num_quarto", q."capacidade_leitos"
)
SELECT 
    "num_quarto",
    "capacidade_leitos",
    "leitos_reais"
FROM leitos_por_quarto
WHERE "capacidade_leitos" <> "leitos_reais";

-- 4. Mostre cada médico efetivo com a quantidade de residentes que ele orienta, incluindo os que não orientam ninguém.
SELECT 
    me."cod_funcional_efetivo",
    m."nome_medico",
    COUNT(r."cod_funcional_residente") AS "total_residentes"
FROM "medico_efetivo" me
JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
LEFT JOIN "medico_residente" r ON r."cod_funcional_residente" = me."cod_funcional_efetivo"
GROUP BY 
    me."cod_funcional_efetivo", 
    m."nome_medico";

-- Parte 6: JOIN com subconsulta ou CTE

-- 1. Usando uma CTE, liste as internações em andamento com paciente, quarto e médico, e depois filtre apenas as de quartos que não são Enfermaria.
WITH "table1" AS (
	SELECT p."nome_paciente", q."num_quarto", q."tipo_quarto", m."nome_medico"
	FROM "internacao" i
	JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
	JOIN "quarto" q ON q."num_quarto" = i."num_quarto"
	JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
	JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
	WHERE i."dt_hora_alta" IS NULL
)
SELECT "nome_paciente", "num_quarto", "tipo_quarto", "nome_medico"
FROM "table1"
WHERE "tipo_quarto" <> 'Enfermaria';

-- 2. Liste os médicos que são responsáveis por internações de pacientes associados a um convênio específico (por exemplo, Unimed), usando IN ou EXISTS combinado com JOINs.
SELECT "nome_medico"
FROM "medico"
WHERE "nome_medico" IN (
	SELECT m."nome_medico"
	FROM "internacao" i
	JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
	JOIN "associado" a ON a."id_paciente" = p."id_paciente"
	JOIN "convenio_medico" c ON c."id_convenio_medico" = a."id_convenio_medico"
	JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
	JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
	WHERE c."nome_convenio" = 'Unimed'
);

-- 3. Liste os pacientes cuja internação teve como responsável um médico com a especialidade Pediatria cadastrada em especializacao, usando uma subconsulta correlacionada ou uma CTE.
SELECT "nome_paciente"
FROM "paciente"
WHERE "nome_paciente" IN (
	SELECT p."nome_paciente"
	FROM "internacao" i
	JOIN "paciente" p ON p."id_paciente" = i."id_paciente"
	JOIN "medico_efetivo" me ON me."cod_funcional_efetivo" = i."cod_funcional_efetivo"
	JOIN "medico" m ON m."cod_funcional" = me."cod_funcional_efetivo"
	JOIN "especializacao" ez ON ez."medico_cod_funcional" = m."cod_funcional"
	JOIN "especialidade" ed ON ed."id_especialidade" = ez."especialidade_id_especialidade"
	WHERE ed."nome_especialidade" = 'Pediatria'
);
