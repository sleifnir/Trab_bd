
-- Função que retorna todas as informações dos individuos que são ficha limpa,
-- ou seja, individuos que não tem processos ou individuos que tem processos não procedentes.
CREATE OR REPLACE FUNCTION obter_individuos_ficha_limpa()
RETURNS TABLE (CPF VARCHAR(11), RG VARCHAR(9), Nome VARCHAR(64), Data_Nascimento Date,
				ProcessoID INTEGER, Procedente BOOL, Data_Inicio_Proc DATE, Data_Termino_Proc DATE)
AS $obter_fichas_limpas$
BEGIN
    RETURN QUERY
    SELECT i.*, p.* FROM individuo i LEFT JOIN individuo_processos ip ON I.cpf = ip.cpf
	LEFT JOIN processojuridico p ON ip.processoid = p.processoid
		WHERE p.procedente IS NULL OR p.procedente = FALSE;
END;
$obter_fichas_limpas$ LANGUAGE plpgsql;

-- Chamando a função
SELECT * FROM obter_individuos_ficha_limpa()

-- Função que recebe um CPF como parâmetro e testa se o individuo é ficha limpa
CREATE OR REPLACE FUNCTION check_ficha_limpa(p_cpf VARCHAR)
RETURNS BOOL
AS $check_ficha_limpa$
BEGIN
    RETURN EXISTS (
        SELECT cpf FROM obter_individuos_ficha_limpa()
        WHERE CPF = p_cpf
    );

END;
$check_ficha_limpa$ LANGUAGE plpgsql;

-- Trigger para permitir que somente individuos ficha limpa sejam candidatos
CREATE OR REPLACE FUNCTION check_ficha_limpa()
RETURNS TRIGGER AS $check_ficha_limpa$
BEGIN
    IF NOT EXISTS (SELECT CPF FROM obter_individuos_ficha_limpa() WHERE CPF = NEW.CPF) THEN
        RAISE EXCEPTION 'Indivíduo com CPF % não é ficha limpa. Consta processo procedente em seu nome', NEW.CPF;
    END IF;
    RETURN NEW;
END;
$check_ficha_limpa$ LANGUAGE plpgsql;
-- Implementando o Trigger na tabela Candidato

--DROP TRIGGER check_ficha_before_insert ON Candidato;

CREATE TRIGGER check_ficha_before_insert
	BEFORE INSERT OR UPDATE ON Candidato
	FOR EACH ROW
	EXECUTE FUNCTION check_ficha_limpa();














