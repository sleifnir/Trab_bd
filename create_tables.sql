CREATE TABLE Individuo (
    CPF VARCHAR(11),
    RG VARCHAR(9) NOT NULL,
    Nome VARCHAR(64) NOT NULL,
    DataNasc DATE NOT NULL,
    
    CONSTRAINT CK_Individuo_RG CHECK (length(RG) >= 9),
   	CONSTRAINT CK_Individuo_CPF CHECK (length(CPF) >= 11),
   	CONSTRAINT CK_Individuo_ANO CHECK
   		(DataNasc BETWEEN '1900-01-01' AND '2006-01-01'),
    CONSTRAINT PK_Individuo PRIMARY KEY (CPF),
    CONSTRAINT UN_Individuo_RG UNIQUE (RG)
);

CREATE TABLE ProcessoJuridico(
	ProcessoID SERIAL,
	Procedente BOOL,
	DataInicio DATE NOT NULL,
	DataTermino DATE DEFAULT NULL,

	CONSTRAINT CK_ProcessoJuridico_Data CHECK
		(DataTermino IS NULL OR DataTermino > DataInicio),
	CONSTRAINT CK_ProcessoJuridico_Procedente CHECK 
		(Procedente IS NULL AND DataTermino IS NULL
		OR Procedente IS NOT NULL AND DataTermino IS NOT NULL),
	CONSTRAINT PK_ProcessoJuridico PRIMARY KEY (ProcessoID)
);

CREATE TABLE Individuo_Processos(
	ProcessoID SERIAL,
	CPF VARCHAR(11),
	
	CONSTRAINT PK_Individuo_Processos PRIMARY KEY (ProcessoID, CPF),
	CONSTRAINT FK_Individuo_Processos_ProcessoID FOREIGN KEY (ProcessoID)
		REFERENCES ProcessoJuridico(ProcessoID)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Individuo_Processos_CPF FOREIGN KEY (CPF)
		REFERENCES Individuo(CPF)
			ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE TABLE Partido (
	Sigla VARCHAR(8),
	Nome VARCHAR(64) NOT NULL,
	Numero INTEGER NOT NULL,
	QntMembros INTEGER NOT NULL,
	ProgramaSaude VARCHAR(2048) NOT NULL,
	ProgramaEducacao VARCHAR(2048) NOT NULL,
	ProgramaEconomia VARCHAR(2048) NOT NULL,
	
	CONSTRAINT PK_Partido PRIMARY KEY (Sigla),
	CONSTRAINT UN_Partido_Nome UNIQUE (Nome),
	CONSTRAINT UN_Partido_Numero UNIQUE (Numero),
	CONSTRAINT UN_Partido_Sigla UNIQUE (Sigla)
);

CREATE TABLE Candidato(
	CPF VARCHAR(11),
	Numero INTEGER NOT NULL,
	Partido_Sigla VARCHAR(8) NOT NULL,
	
	CONSTRAINT PK_Candidato PRIMARY KEY (CPF),
	CONSTRAINT UN_Candidato_Numero UNIQUE (Numero),
	CONSTRAINT FK_Candidato_CPF FOREIGN KEY (CPF)
		REFERENCES Individuo (CPF)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Candidato_PartidoSigla FOREIGN KEY (Partido_Sigla)
		REFERENCES Partido (Sigla)
			ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Cargo(
	CargoID SERIAL,
	Nome VARCHAR(64) NOT NULL,
	Referencia VARCHAR(64) NOT NULL,
	QntEleitos INTEGER NOT NULL,

	CONSTRAINT PK_Cargo PRIMARY KEY (CargoID),
	CONSTRAINT UN_Cargo UNIQUE (Nome, Referencia)
);

CREATE TABLE Pleito(
	PleitoID SERIAL,
	Votos INTEGER,
	
	CONSTRAINT PK_Pleito PRIMARY KEY (PleitoID)
);

CREATE TABLE Candidatura(
	CandidaturaID SERIAL,
	CPF VARCHAR(11),
	ANO SMALLINT NOT NULL,
	CargoID SERIAL NOT NULL,
	Vice VARCHAR(11) DEFAULT NULL,
	PleitoID SERIAL NOT NULL,
	Eleito BOOL DEFAULT NULL,
	
	CONSTRAINT CK_Candidatura_Ano CHECK (ANO >= 2000 AND ANO <= 2025),
	CONSTRAINT PK_Candidatura PRIMARY KEY (CandidaturaID),
	CONSTRAINT UN_Candidatura UNIQUE (CPF,ANO),
	CONSTRAINT FK_Candidatura_CPF FOREIGN KEY (CPF)
		REFERENCES Individuo(CPF)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Candidatura_CargoID FOREIGN KEY (CargoID)
		REFERENCES Cargo(CargoID)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Candidatura_Vice FOREIGN KEY (Vice)
		REFERENCES Individuo(CPF)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Candidatura_Pleito FOREIGN KEY (PleitoID)
		REFERENCES Pleito(PleitoID)
			ON DELETE CASCADE ON UPDATE CASCADE
);

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


CREATE TABLE Empresa(
	CNPJ VARCHAR(14),
	Nome VARCHAR(128) NOT NULL,

	CONSTRAINT CK_Empresa_CNPJ CHECK (length(CNPJ) >= 14),
	CONSTRAINT PK_Empresa PRIMARY KEY (CNPJ),
	CONSTRAINT UN_Empresa UNIQUE (Nome)
);

CREATE TABLE Empresa_Doacao(
	CNPJ VARCHAR(14),
	CandidaturaID SERIAL,
	Valor DECIMAL(12,2) NOT NULL,

	CONSTRAINT PK_Empresa_Doacao PRIMARY KEY (CNPJ, CandidaturaID),
	CONSTRAINT FK_Empresa_Doacao_CNPJ FOREIGN KEY (CNPJ)
		REFERENCES Empresa(CNPJ)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Empresa_Doacao_CandidaturaID FOREIGN KEY (CandidaturaID)
		REFERENCES Candidatura(CandidaturaID)
			ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE DoacaoDeCampanha(
	CPF VARCHAR(11),
	CandidaturaID SERIAL,
	DataDoacao DATE,
	Valor DECIMAL(12,2) NOT NULL,

	CONSTRAINT PK_DoacaoDeCampanha PRIMARY KEY (CPF, CandidaturaID, DataDoacao),
	CONSTRAINT FK_DoacaoDeCampanha_CPF FOREIGN KEY (CPF)
		REFERENCES Individuo(CPF)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_DoacaoDeCampanha_CandidaturaID FOREIGN KEY (CandidaturaID)
		REFERENCES Candidatura(CandidaturaID)
			ON DELETE CASCADE ON UPDATE CASCADE
);


create table EquipeDeApoio(
	EquipeID SERIAL,
	ANO SMALLINT NOT NULL,
	qntMembros SMALLINT NOT NULL,
	CandidaturaID SERIAL not NULL,

	CONSTRAINT PK_EquipeID PRIMARY KEY (EquipeID),
	CONSTRAINT FK_EquipeDeApoio_CandidaturaID FOREIGN KEY (CandidaturaID)
		REFERENCES Candidatura(CandidaturaID)
			ON DELETE CASCADE ON UPDATE CASCADE

);

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



create table Apoiador_Equipe(
	CPF VARCHAR(11),
	ANO SMALLINT NOT NULL,
	EquipeID SERIAL,

	CONSTRAINT PK_Apoiador_Equipe PRIMARY KEY (CPF, ANO),
	CONSTRAINT FK_Apoiador_Equipe_CPF FOREIGN KEY (CPF)
		REFERENCES Individuo(CPF)
			ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT FK_Apoiador_Equipe_EquipeID FOREIGN KEY (EquipeID)
		REFERENCES EquipeDeApoio(EquipeID)
			ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE OR REPLACE FUNCTION update_qntmembros() RETURNS TRIGGER AS $$
BEGIN
    UPDATE EquipeDeApoio
    SET qntMembros = (SELECT COUNT(*) FROM Apoiador_Equipe WHERE EquipeID = NEW.EquipeID)
    WHERE EquipeID = NEW.EquipeID;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_qntmembros_trigger
AFTER INSERT ON Apoiador_Equipe
FOR EACH ROW EXECUTE PROCEDURE update_qntmembros();




