-- ALUNOS --

--Ana Júlia Oliveira Lins - 20191370002
--Gabriel Xavier Silva - 20191370025
--Yohanna de Oliveira Cavalcanti - 20191370003


-- REQUISITO 1 --
-- Criando função para gerar numero aleatorio de forma prática
CREATE OR REPLACE FUNCTION random_between(low INT ,high INT) 
   RETURNS INT AS
$$
BEGIN
   RETURN floor(random()* (high-low + 1) + low);
END;
$$ language 'plpgsql' STRICT;

--Função de geração de numeros
CREATE OR REPLACE FUNCTION insere_Num()
RETURNS TRIGGER AS $$
DECLARE 
	numero char(11);
	numdupli char(11);
    num char(11);
    opera char(2);
    subnum char(11);
    random char;
	uf char(4);
	cursorNum refcursor;
	rec RECORD;
	dupli int;
	idrandom int;
BEGIN
num = '00000000000';
subnum =  SUBSTR (num, 7, 4); 
idrandom = random_between(1,7);
uf =  ddd FROM estado WHERE idregiao = idrandom LIMIT 1;
random = FLOOR((random()*2)+1);
dupli = 0;

-- CASE para adicionar o ddd da operadora pelo id dela
CASE NEW.idoperadora
    WHEN  1 THEN opera = '83';
    WHEN  2 THEN opera =  '85';
    WHEN  3 THEN opera =  '91';
    WHEN  4 THEN opera =  '95';
    WHEN  5 THEN opera =  '94';
    WHEN  6 THEN opera =  '89';
    WHEN  7 THEN opera =  '86';
    WHEN  8 THEN opera =  '71';
    WHEN  9 THEN opera = '80';
    WHEN  10 THEN opera =  '93';
    ELSE opera = '82';
END CASE;
LOOP 
	-- LOOP para garantir que o numero não acababe com 0000 e que não seja duplicado
    EXIT WHEN subnum != '0000' AND dupli = 0 ;
        num =  random_between(0,9)|| LPAD(random_between(1,9999)::text, 4, '0');
		dupli = 0;
        subnum =  SUBSTR (num, 7);
		numdupli = uf || '9' || opera || random || num;
		
		-- Cursor para verificar se já existe o número na tabela
		OPEN cursorNum NO SCROLL FOR SELECT idnumero FROM chip;
		LOOP
			FETCH cursorNum INTO rec;
			EXIT WHEN NOT FOUND OR dupli = 1;
			IF rec.idnumero = numdupli THEN
				dupli = 1;
			END IF;
		END LOOP;
		CLOSE cursorNum;
END LOOP;
-- Concatena as partes do numero
numero = uf || '9' || opera || random || num;

NEW.idnumero = numero;
RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cria a trigger para inserir o idnumero na criação antes do insert no chip
CREATE TRIGGER insereNum
BEFORE INSERT  ON chip
FOR EACH ROW
EXECUTE PROCEDURE insere_Num();




-- REQUISITO 2 --

CREATE OR REPLACE FUNCTION verInativNum ()
RETURNS TABLE (idnumeroF char(11), ativoF char(1), disponivelF char(1))
AS $$
DECLARE
BEGIN
-- aqui iremos retornar uma tabela que mostra chip que estão disponiveis para o uso e que não tem problemas técnicos;
-- disponiveis -> disponivel ='S' e sem problemas -> ativo = 'S'
RETURN QUERY SELECT idnumero, ativo,disponivel 
                    FROM chip 
                    WHERE ativo = 'S' AND disponivel ='S'
                    ORDER BY RANDOM()
                    LIMIT 5  ;
END; $$
LANGUAGE 'plpgsql';


-- REQUISITO 3 --

CREATE OR REPLACE PROCEDURE geraFatu(mes int, ano int)
AS $$
DECLARE
cursorFat refcursor;
rec RECORD;

refe date = ano || '-' || mes || '-25';
tot_min_int int = 0;
tot_min_ext int = 0;
tx_min_exced numeric(5,2) := 0;
tx_roaming numeric(5,2) := 0;
total numeric(7,2);
pago char(1);

auxVal numeric;
auxTar int;
auxRoam int;

Roam int := 0;
RecRoam RECORD; 

BEGIN
-- Resgata as informações principais dos números para a 
-- geração da fatura.
OPEN cursorFat NO SCROLL FOR SELECT chipe.lamen as idNum, 
									valor.valor as valorPlan,
									valor.fminin,
									valor.fminout,
									chipe.idplano,
									chipe.idregiao,
									chipe.cli as idcliente
									FROM (SELECT *, ch.idnumero as lamen, cl.idcliente as cli FROM chip ch 
								JOIN cliente_chip clch ON ch.idnumero = clch.idnumero 
								JOIN cliente cl ON cl.idcliente = clch.idcliente 
								JOIN cidade ci ON cl.idcidade = ci.idcidade
								JOIN estado es ON ci.uf = es.uf
								WHERE cl.cancelado = 'N' AND ch.disponivel = 'N') as chipe
								JOIN (SELECT pl.valor, pl.fminin, pl.fminout, ch.idnumero as valorid  FROM plano pl 
										JOIN chip ch ON ch.idplano = pl.idplano 
										) as valor ON valor.valorid = chipe.lamen;
    -- Loop para resgatar numero por numero, usando o cursor.
    LOOP 
        FETCH cursorFat  INTO rec;
        EXIT WHEN NOT FOUND;
		
		/* Aqui iremos pegar os minutos de duracao do chip emissor da vez (no cursor) 
		na data de referencia. Será feito tanto para ligações internas quanto para externas,
		e no final, caso não tenha ocorrido minutos de chamadas, entrarão no IF e trocarão
		o valor NULL pelo 0.
		*/
		tot_min_int = TRUNC(EXTRACT(EPOCH FROM SUM(duracao)::INTERVAL)/60) FROM ligacao 
						WHERE chip_emissor = rec.idNum 
						AND SUBSTR(chip_receptor, 4, 2) = SUBSTR(chip_emissor, 4, 2)
						AND EXTRACT(YEAR FROM data) = ano
						AND EXTRACT(MONTH FROM data) = mes;
		IF tot_min_int IS NULL THEN
			tot_min_int = 0;
		END IF;
		
		tot_min_ext =  TRUNC(EXTRACT(EPOCH FROM SUM(duracao)::INTERVAL)/60) FROM ligacao 
						WHERE chip_emissor = rec.idNum 
						AND SUBSTR(chip_receptor, 4, 2) != SUBSTR(chip_emissor, 4, 2)
						AND EXTRACT(YEAR FROM data) = ano
						AND EXTRACT(MONTH FROM data) = mes;
		IF tot_min_ext IS NULL THEN
			tot_min_ext = 0;
		END IF;
						
		-- Se auxTar estiver NULL, significa q o plano não tem tal tarifa, então não entrará no IF !
        --Taxa para minutos de numeros da mesma operadora
		tx_min_exced = 0;
		auxTar = idtarifa FROM plano_tarifa WHERE idplano = rec.idplano AND idtarifa = 2 limit 1;
		IF rec.fminin < tot_min_int AND auxTar = 2 THEN
			auxVal = valor FROM tarifa WHERE idtarifa = 2;
			tx_min_exced = tx_min_exced + ((tot_min_int - rec.fminin) * auxVal);
		END IF;
		
        --Taxa para minutos de numeros de outras operadoras
		auxTar =  idtarifa FROM plano_tarifa WHERE idplano = rec.idplano AND idtarifa = 3 limit 1;
		IF rec.fminout < tot_min_ext AND auxTar = 3 THEN
			auxVal = valor FROM tarifa WHERE idtarifa = 3;
			tx_min_exced = tx_min_exced + ((tot_min_ext - rec.fminout) * auxVal);
		END IF;
		
        -- Resgate da quantidade de vezes que foi feito algum tipo de interação
        -- em roaming para aquele numero usando cursor em for, já que é inviável
        -- usar utilizando no primeiro cursor pela quantidade de linhas.
		Roam = 0;
		FOR RecRoam IN SELECT chip_emissor, chip_receptor FROM ligacao 
			WHERE chip_emissor = rec.idNum 
			AND EXTRACT(YEAR FROM data) = ano
			AND EXTRACT(MONTH FROM data) = mes
			LOOP
			auxRoam = idregiao from estado where ddd = SUBSTR(RecRoam.chip_receptor, 4, 2)::int;
			IF auxRoam = rec.idregiao THEN
				Roam = Roam + 1;
			END IF;
		END LOOP;

		
		/* Se auxTar estiver NULL, significa q o plano não tem tal tarifa roaming, então não entrará no IF !*/
		auxTar = idtarifa FROM plano_tarifa WHERE idplano = rec.idplano AND idtarifa = 1;
		IF auxTar = 1 THEN
			auxVal = valor FROM tarifa WHERE idtarifa = 1;
			tx_roaming = Roam *  auxVal;

		END IF;
		
		total = ((rec.valorPlan + tx_min_exced) + tx_roaming);
		
		pago = 'N';

        --Insere na tabela.
		insert into  fatura (referencia, idNumero, valor_plano, tot_min_int, tot_min_ext, tx_min_exced, tx_roaming, total, pago) 
		values (refe, rec.idNum, rec.valorPlan, tot_min_int, tot_min_ext, tx_min_exced, tx_roaming, total, pago);
	END LOOP;

CLOSE cursorFat;
END; $$
LANGUAGE 'plpgsql';




-- REQUISITO 4 --

CREATE OR REPLACE FUNCTION verif_chistatus()
RETURNS TRIGGER AS $$
DECLARE 
    isAtivoE char(1);
    isDispE  char(1);
    isAtivoR char(1);
    isDispR  char(1);
BEGIN
isAtivoE = ativo from chip where idnumero = new.chip_emissor;
isDispE = disponivel from chip where idnumero = new.chip_emissor;
isAtivoR = ativo from chip where idnumero = new.chip_receptor;
isDispR = disponivel from chip where idnumero = new.chip_receptor;

IF NOT ((isDispR = 'N' AND isAtivoR = 'S') AND (isDispE = 'N' AND isAtivoE = 'S' )) THEN
    RAISE EXCEPTION '%', 'Não possivel concluir ligacao !' ;
END IF;

RETURN NEW ;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER chipstatus
BEFORE INSERT  ON ligacao
FOR EACH ROW
EXECUTE PROCEDURE verif_chistatus();


-- REQUISITO 5 --

CREATE OR REPLACE FUNCTION verif_clientestatus()
RETURNS TRIGGER AS $$
DECLARE 
    isCancelado char(1); 
BEGIN
isCancelado = cancelado from cliente where idcliente = new.idcliente;

-- Condição para que se o cliente estiver cancelado, NÃO poderá ser adicionado na tabela
IF isCancelado = 'S'  THEN 
    RAISE EXCEPTION '%', 'Cliente cancelado !' ; -- se o cliente estiver cancelado ocorrerá uma execeção 
END IF;
UPDATE chip SET disponivel = 'N' WHERE idnumero = new.idnumero;

RETURN NEW ;
END;
$$ LANGUAGE plpgsql;

-- Criação do Trigger que executará a verificação do cliente antes da inserção no cliente_chip, em cada linha
CREATE TRIGGER clientetatus 
BEFORE INSERT  ON cliente_chip
FOR EACH ROW
EXECUTE PROCEDURE verif_clientestatus();



-- REQUISITO 6 --

CREATE OR REPLACE FUNCTION verif_clienteLiberaNum()
RETURNS TRIGGER AS $$
DECLARE 
    isCancelado char(1); 
    Num char(11);
    cursorVer refcursor;
    rec RECORD;
BEGIN
isCancelado = new.cancelado;

IF isCancelado = 'S'  THEN -- Verifica se o cliente está como cancelado
OPEN cursorVer NO SCROLL FOR select chi.idnumero from chip chi -- Abre um cursor com os numeros que pertencia ao cliente
               join cliente_chip clichi on chi.idnumero = clichi.idnumero 
               join cliente cli on clichi.idcliente = cli.idcliente and cli.idcliente = old.idcliente;
    LOOP
        FETCH cursorVer INTO rec;
        EXIT WHEN NOT FOUND;
        /* Deixará o número disponível e desativado na tabela chip, 
        e deletará o vínculo do antigo cliente na tabela cliente_chip*/
        UPDATE chip SET disponivel = 'S' WHERE chip.idnumero = rec.idnumero;
        DELETE FROM cliente_chip WHERE cliente_chip.idnumero = rec.idnumero;
    END LOOP;
CLOSE cursorVer;
END IF;

RETURN NEW ;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER clienteCancel
BEFORE UPDATE  ON cliente --Logo após o cliente ser cancelado, ele disparará
FOR EACH ROW
EXECUTE PROCEDURE verif_clienteLiberaNum();



-- REQUISITO 7 -- 

CREATE OR REPLACE PROCEDURE geraLig(mes int, ano int)
AS $$
DECLARE
varNum  int ;
quantIn int ;
quantEx int ;
n int ;

cursorChip refcursor;
rec RECORD;

cursorData date := ano || '-' || mes || '-01';
horaLiga timestamp;

chipRecVar char(11);
ufDest char(2);
ufOrig char(2);
BEGIN
OPEN cursorChip  NO SCROLL FOR SELECT cc.idNumero from cliente_chip cc 
													join chip chi on chi.idnumero = cc.idnumero 
													where chi.ativo = 'S' group by cc.idNumero;
    LOOP -- Loop para cada numero
        FETCH cursorChip  INTO rec;
        EXIT WHEN NOT FOUND;
        LOOP -- Loop para os dias do mes
            horaLiga = cursorData + interval '10 second';
            EXIT WHEN (EXTRACT(MONTH FROM cursorData)::int) != mes;
			varNum  = round(random() * (9) +1); -- quantidade de ligações
			quantIn = round(random() * varNum); -- quantidade de ligações internas ( mesma op)
			quantEx = varNum - quantIn; -- quantidade de ligações exeternas ( op diferentes)
			n = 0;
			--raise notice 'varNum = % / quantIn = % / quantEx = %',varNum,quantIn,quantEx;
			
            LOOP  
				EXIT WHEN n = varNum ;
			    IF  quantIn > 0 THEN
					chipRecVar = cc.idNumero from cliente_chip cc -- vai receber o número 
					join chip chi on chi.idnumero = cc.idnumero   -- que recebeu a ligação
								where cc.idNumero != rec.idnumero and chi.ativo = 'S' 
								and SUBSTR(rec.idnumero, 4, 2) = SUBSTR(cc.idNumero, 4, 2)
								LIMIT 1 OFFSET FLOOR(random() * ((SELECT COUNT(*) FROM cliente_chip )-1));	
					IF chipRecVar IS NULL THEN 
						n = n + quantIn;
						quantIn = 0 ;  
					ELSE
						ufDest = uf from estado where ddd = SUBSTR(chipRecVar, 0, 3)::INTEGER; 
						ufOrig = uf from estado where ddd = SUBSTR(rec.idnumero, 0, 3)::INTEGER;	 
						insert into ligacao (data, chip_emissor, ufOrigem, chip_receptor, ufDestino, duracao) 
						 values (horaLiga, rec.idnumero, ufOrig, chipRecVar, ufDest, ('0:' || LPAD(round(random() * (19)+1)::text, 2, '0') || ':00')::time);
						n = n + 1;
						quantIn = quantIn - 1;
						horaLiga = horaLiga + interval '1 hour';	
					END IF;
				END IF;
				IF quantEx > 0 THEN
					chipRecVar = cc.idNumero from cliente_chip cc  --vai pegar o número que recebeu a ligação
								join chip chi on chi.idnumero = cc.idnumero 
								where cc.idNumero != rec.idnumero and chi.ativo = 'S' 
								and SUBSTR(rec.idnumero, 4, 2) != SUBSTR(cc.idNumero, 4, 2)
								LIMIT 1 OFFSET FLOOR(random() * ((SELECT COUNT(*) FROM cliente_chip )-1));
					IF chipRecVar IS NULL THEN 
						n = n + quantEx; 
						quantEx = 0 ; 
					ELSE
						ufDest = uf from estado where ddd = SUBSTR(chipRecVar, 0, 3)::INTEGER;
						ufOrig = uf from estado where ddd = SUBSTR(rec.idnumero, 0, 3)::INTEGER;	
						insert into ligacao (data, chip_emissor, ufOrigem, chip_receptor, ufDestino, duracao) 
						values (horaLiga, rec.idnumero, ufOrig, chipRecVar, ufDest, ('0:' || LPAD(round(random() * (19)+1)::text, 2, '0') || ':00')::time);
						quantEx = quantEx - 1;
						n = n + 1;
						horaLiga = horaLiga + interval '1 hour';
    				END IF;
    		    END IF;
            END LOOP;
            cursorData = cursorData + interval '1 day';
            n = 0;
        END LOOP;
        n = 0;
        cursorData = ano || '-' || mes || '-01';
        horaLiga = cursorData + interval '1 second';
    END LOOP;
CLOSE cursorChip;
END; $$
LANGUAGE 'plpgsql';


/*VISÃO 1*/
CREATE VIEW rankPlan AS
    (SELECT p.idplano,
            p.descricao,
            COUNT(c.*) AS quant, 
            SUM(p.valor) AS total 
    FROM plano p 
    JOIN chip c 
    ON p.idplano = c.idplano AND ativo = 'S'
    GROUP BY p.idplano
    ORDER BY quant DESC);



/*VISÃO 2*/

CREATE VIEW faturamento AS
    (SELECT EXTRACT(YEAR FROM f.referencia) AS ano, 
    EXTRACT(MONTH FROM f.referencia) AS mes,
    COUNT(f.idnumero) AS numClientes, 
    SUM(f.total) AS faturamento
    FROM fatura f 
    GROUP BY (ano, mes)
    ORDER BY (faturamento) DESC );


/*VISÃO 3*/
CREATE VIEW fidelidade AS
    (SELECT     cli.idcliente, 
            cli.nome, 
            ci.uf, 
            clichi.idnumero, 
            chip.idplano, 
    extract('year' from age(CURRENT_DATE,cli.datacadastro)) || ' ano(s) ' || extract('month' from age(CURRENT_DATE,cli.datacadastro)) || ' mes(es) '  AS tempoFiel
    FROM cliente cli 
    JOIN cidade ci 
    ON cli.idcidade = ci.idcidade 
    JOIN cliente_chip clichi 
    ON cli.idcliente = clichi.idcliente 
    JOIN chip 
    ON clichi.idnumero = chip.idnumero AND chip.ativo = 'S');
