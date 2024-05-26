
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


CREATE OR REPLACE FUNCTION check_election_votes()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Eleito IS TRUE THEN
        -- Verificar se o pleito correspondente tem votos
        PERFORM 1 FROM Pleito WHERE PleitoID = NEW.PleitoID AND Votos IS NOT NULL;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Um candidato só pode ser eleito se o pleito correspondente tiver uma contagem de votos.';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_election_votes
BEFORE INSERT OR UPDATE ON Candidatura
FOR EACH ROW
EXECUTE FUNCTION check_election_votes();

--A equipe precisa ser criada com um membro?? como garantir qual membro?
/*
CREATE OR REPLACE FUNCTION check_equipe_membros() RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = NEW.EquipeID) < 1 THEN
        RAISE EXCEPTION 'A EquipeDeApoio deve ser composta por vários indivíduos.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER equipe_membros_trigger
AFTER INSERT OR UPDATE ON Apoiador_Equipe
FOR EACH ROW EXECUTE PROCEDURE check_equipe_membros();
*/

CREATE OR REPLACE FUNCTION update_qntmembros() RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE EquipeDeApoio
        SET qntMembros = (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = NEW.EquipeID)
        WHERE EquipeID = NEW.EquipeID;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE EquipeDeApoio
        SET qntMembros = (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = OLD.EquipeID)
        WHERE EquipeID = OLD.EquipeID;
    ELSIF TG_OP = 'UPDATE' THEN
        IF NEW.EquipeID <> OLD.EquipeID THEN
            -- Update count for the old team
            UPDATE EquipeDeApoio
            SET qntMembros = (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = OLD.EquipeID)
            WHERE EquipeID = OLD.EquipeID;

            -- Update count for the new team
            UPDATE EquipeDeApoio
            SET qntMembros = (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = NEW.EquipeID)
            WHERE EquipeID = NEW.EquipeID;
        ELSE
            UPDATE EquipeDeApoio
            SET qntMembros = (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = NEW.EquipeID)
            WHERE EquipeID = NEW.EquipeID;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

--DROP TRIGGER update_qntmembros_trigger ON Apoiador_equipe

CREATE TRIGGER update_qntmembros_trigger
AFTER INSERT OR DELETE OR UPDATE ON Apoiador_Equipe
FOR EACH ROW EXECUTE PROCEDURE update_qntmembros();






