CREATE DATABASE ifmobile;

--Alunos:

--Ana Júlia Oliveira Lins - 20191370002
--Gabriel Xavier Silva - 20191370025
--Yohanna de Oliveira Cavalcanti - 20191370003

-- \c ifmobile

DROP TABLE IF EXISTS cobertura CASCADE;
DROP TABLE IF EXISTS estado CASCADE;
DROP TABLE IF EXISTS cidade CASCADE;
DROP TABLE IF EXISTS cliente CASCADE;
DROP TABLE IF EXISTS operadora CASCADE;
DROP TABLE IF EXISTS plano CASCADE;
DROP TABLE IF EXISTS tarifa CASCADE;
DROP TABLE IF EXISTS plano_tarifa CASCADE;
DROP TABLE IF EXISTS chip CASCADE;
DROP TABLE IF EXISTS cliente_chip CASCADE;
DROP TABLE IF EXISTS ligacao CASCADE;
DROP TABLE IF EXISTS fatura CASCADE;
DROP TABLE IF EXISTS auditoria CASCADE;


CREATE TABLE cobertura
(
  idRegiao  SERIAL          NOT NULL,
  descricao     varchar(40) NOT NULL,
  CONSTRAINT PK_cobertura      PRIMARY KEY (idRegiao)
);


CREATE TABLE estado
(
  uf 	   char(2)          NOT NULL,
  nome     varchar(40)      NOT NULL,
  ddd	   int   	        NOT NULL,
  idRegiao int              NOT NULL,
  CONSTRAINT PK_estado      PRIMARY KEY (uf),
  CONSTRAINT UQ_estado_ddd  UNIQUE (ddd),
  CONSTRAINT FK_estado_idregiao FOREIGN KEY (idRegiao) REFERENCES cobertura
);


CREATE TABLE cidade 
(
  idCidade SERIAL  	   NOT NULL,
  nome     varchar(50) NOT NULL,
  uf       char(2)	   NOT NULL,
  CONSTRAINT PK_cidade      	PRIMARY KEY (idCidade),
  CONSTRAINT FK_cidade_estado 	FOREIGN KEY (uf) REFERENCES estado
);


CREATE TABLE cliente
(
  idCliente    SERIAL     NOT NULL,
  nome         varchar(50)NOT NULL,
  endereco     varchar(60),
  bairro       varchar(30),
  idCidade     int        NOT NULL,
  dataCadastro date       ,
  cancelado    char(1)    DEFAULT 'N'	NOT NULL,
  CONSTRAINT PK_cliente           PRIMARY KEY (idCliente),
  CONSTRAINT FK_cliente_cidade    FOREIGN KEY (idCidade) REFERENCES cidade,
  CONSTRAINT CK_cliente_cancelado CHECK (cancelado = 'S' or cancelado = 'N')
);

CREATE TABLE operadora
(
  idOperadora  SERIAL  NOT NULL,
  nome     varchar(40) NOT NULL,
  CONSTRAINT PK_operadora      PRIMARY KEY (idOperadora)
);


CREATE TABLE plano
(
  idPlano	SERIAL		NOT NULL,
  descricao	varchar(50)	NOT NULL,
  fminIn	int		DEFAULT 0	NOT NULL,
  fminOut	int		DEFAULT 0	NOT NULL,
  valor         numeric(7,2) 	NOT NULL,
  CONSTRAINT PK_plano           PRIMARY KEY (idPlano)
);


CREATE TABLE tarifa
(
  idTarifa	SERIAL		NOT NULL,
  descricao	varchar(50)	NOT NULL,
  valor	        numeric(5,2)	DEFAULT 0	NOT NULL,
  CONSTRAINT PK_tarifa      	PRIMARY KEY (idTarifa)
);


CREATE TABLE plano_tarifa
(
  idPlano  int NOT NULL,
  idTarifa int NOT NULL,
  CONSTRAINT PK_plano_tarifa      	  PRIMARY KEY (idPlano,idTarifa),
  CONSTRAINT FK_plano_tarifa_idPlano  FOREIGN KEY (idPlano) REFERENCES plano,
  CONSTRAINT FK_plano_tarifa_idTarifa FOREIGN KEY (idTarifa) REFERENCES tarifa
 
);


CREATE TABLE chip
(
  idNumero	char(11)		NOT NULL,
  idOperadora int NOT NULL,
  idPlano	int		        NOT NULL,
  ativo		char(1)	   		DEFAULT 'S'     NOT NULL,
  disponivel	char(1)	    DEFAULT 'S'	NOT NULL,
  CONSTRAINT PK_chip      		 PRIMARY KEY (idNumero),
  CONSTRAINT FK_chip_idOperadora FOREIGN KEY (idOperadora) REFERENCES operadora,
  CONSTRAINT FK_chip_idPlano     FOREIGN KEY (idPlano) REFERENCES plano,
  CONSTRAINT CK_chip_ativo   		CHECK (ativo = 'S' or ativo = 'N'),
  CONSTRAINT CK_chip_disponivel   	CHECK (disponivel = 'S' or disponivel = 'N')
);


CREATE TABLE cliente_chip
(
  idNumero	char(11)		NOT NULL,
  idCliente	int	        	NOT NULL,
  CONSTRAINT PK_cliente_chip      	PRIMARY KEY (idNumero,idCliente),
  CONSTRAINT FK_cliente_chip_idNumero 	FOREIGN KEY (idNumero) REFERENCES chip,
  CONSTRAINT FK_cliente_chip_cliente 	FOREIGN KEY (idCliente) REFERENCES cliente
);


CREATE TABLE ligacao
(
  data		    timestamp		NOT NULL,
  chip_emissor	char(11)	NOT NULL,
  ufOrigem	    char(2)			NOT NULL,
  chip_receptor	char(11)			NOT NULL,
  ufDestino     char(2)			NOT NULL,
  duracao	   time			NOT NULL,
  CONSTRAINT PK_ligacao             PRIMARY KEY (data, chip_emissor),
  CONSTRAINT FK_ligacao_chip_emissor FOREIGN KEY (chip_emissor) REFERENCES chip,
  CONSTRAINT FK_ligacao_ufOrigem      FOREIGN KEY (ufOrigem) REFERENCES estado,
  CONSTRAINT FK_ligacao_chip_receptor FOREIGN KEY (chip_receptor) REFERENCES chip,
  CONSTRAINT FK_ligacao_ufDestino      FOREIGN KEY (ufDestino) REFERENCES estado
);


CREATE TABLE fatura
(
  referencia    date		 NOT NULL,
  idNumero	    char(11)	 NOT NULL,
  valor_plano	numeric(7,2) NOT NULL,
  tot_min_int	int			NOT NULL,
  tot_min_ext	int			NOT NULL,
  tx_min_exced  numeric(5,2)	NOT NULL,
  tx_roaming	numeric(5,2)	NOT NULL,
  total		    numeric(7,2)	NOT NULL,
  pago          char(1)  		DEFAULT 'N' 	NOT NULL,
  CONSTRAINT PK_fatura      		PRIMARY KEY (referencia,idNumero),
  CONSTRAINT FK_fatura_idNumero      	FOREIGN KEY (idNumero) REFERENCES chip,
  CONSTRAINT CK_fatura_pago   		CHECK (pago = 'S' or pago = 'N')
);


CREATE TABLE auditoria
(
  idNumero	char(11)		NOT NULL,
  idCliente	int			    NOT NULL,
  dataInicio	date		NOT NULL,
  dataTermino	date		NOT NULL,
  CONSTRAINT PK_auditoria      		PRIMARY KEY (idNumero,idCliente,dataInicio),
  CONSTRAINT FK_auditoria_idNumero      	FOREIGN KEY (idNumero) REFERENCES chip,
  CONSTRAINT FK_auditoria_idCliente      	FOREIGN KEY (idCliente) REFERENCES cliente	
);




