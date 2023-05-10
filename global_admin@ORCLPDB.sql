--II.2) Crearea relatiilor si a fragmentelor

CREATE TABLE CLIENT_GDPR
    (client_id NUMBER(8) PRIMARY KEY,
     nume VARCHAR2(20) NOT NULL,
     prenume VARCHAR2(30) NOT NULL,
     email VARCHAR2(40) NOT NULL,
     numar_telefon VARCHAR2(30) NOT NULL
);

--constrangeri pentru fragmentul client_gdpr
--not null
ALTER TABLE client_gdpr
    add constraint nn_nume_client_gdpr check (nume is NOT NULL);

ALTER TABLE client_gdpr
    add constraint nn_prenume_client_gdpr check (prenume is NOT NULL);

ALTER TABLE client_gdpr
    add constraint nn_email_client_gdpr check (email is NOT NULL);

ALTER TABLE client_gdpr
    add constraint nn_telefon_client_gdpr check (numar_telefon is NOT NULL);

--primary key
alter table client_gdpr
    add constraint pk_client_gdpr primary key (client_id);

INSERT INTO client_gdpr VALUES (10001, 'nume', 'prenume', 'email', '438943843');
INSERT INTO client_gdpr VALUES (10002, null, 'prenume', 'email', '438943843');
INSERT INTO client_gdpr VALUES (10003, 'nume', null, 'email', '438943843');
INSERT INTO client_gdpr VALUES (10004, 'nume', 'prenume', null, '438943843');
INSERT INTO client_gdpr VALUES (10005, 'nume', 'prenume', 'email', null);

CREATE DATABASE LINK non_lowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb_2';

select * from tab@non_lowcost;

-- CREARE FRAGMENT VERTICAL GDPR
INSERT INTO client_gdpr
SELECT client_id, nume, prenume, email, numar_telefon
FROM centralizat_admin.client;

SELECT * FROM client_gdpr;

-- reconstructia
SELECT * FROM bdd_admin.client_nongdpr;

SELECT gdpr.*, nongdpr.premium, nongdpr.data_inregistrare
FROM client_gdpr gdpr
JOIN bdd_admin.client_nongdpr nongdpr
ON (gdpr.client_id = nongdpr.client_id);

-- completitudinea
SELECT * FROM centralizat_admin.client;

SELECT *
FROM centralizat_admin.client
MINUS
(SELECT gdpr.*, nongdpr.premium, nongdpr.data_inregistrare
FROM client_gdpr gdpr
JOIN bdd_admin.client_nongdpr nongdpr
ON (gdpr.client_id = nongdpr.client_id));

-- disjunctia - coloanele vor fi vide
SELECT column_name
FROM user_tab_columns
WHERE table_name = UPPER('client_gdpr')
AND column_name <> 'CLIENT_ID'
INTERSECT
SELECT column_name
FROM user_tab_columns
WHERE table_name = UPPER('client_nongdpr')
AND column_name <> 'CLIENT_ID';

-- II.3) Furnizarea formelor de transparenta pentru intreg modelul ales
-- Pentru fiecare tabela (care se afla in aceeasi baza de date sau nu) se creeaza un sinonim corespunzator, respectiv o vizualizare
-- care cuprinde datele agregate din cele 2 fragmentari orizontale

-- Operator zbor
CREATE OR REPLACE SYNONYM operator_zbor_lowcost
FOR bdd_admin.operator_zbor_lowcost;

CREATE OR REPLACE SYNONYM operator_zbor_nonlowcost
FOR operator_zbor@non_lowcost;

CREATE OR REPLACE VIEW operator_zbor
AS
SELECT * FROM operator_zbor_nonlowcost
UNION ALL 
SELECT * FROM operator_zbor_lowcost;

SELECT * FROM operator_zbor;

-- Zbor
CREATE OR REPLACE SYNONYM zbor_lowcost
FOR bdd_admin.zbor_lowcost;

CREATE OR REPLACE SYNONYM zbor_nonlowcost
FOR zbor_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW zbor
AS
SELECT * FROM zbor_nonlowcost
UNION ALL 
SELECT * FROM zbor_lowcost;

SELECT * FROM zbor;

-- Rezervare
CREATE OR REPLACE SYNONYM rezervare_lowcost
FOR bdd_admin.rezervare_lowcost;

CREATE OR REPLACE SYNONYM rezervare_nonlowcost
FOR rezervare_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW rezervare
AS
SELECT * FROM rezervare_nonlowcost
UNION ALL 
SELECT * FROM rezervare_lowcost;

SELECT * FROM rezervare;

-- Plata
CREATE OR REPLACE SYNONYM plata_lowcost
FOR bdd_admin.plata_lowcost;

CREATE OR REPLACE SYNONYM plata_nonlowcost
FOR plata_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW plata
AS
SELECT * FROM plata_nonlowcost
UNION ALL 
SELECT * FROM plata_lowcost;

SELECT * FROM plata;

-- Metoda Plata
CREATE OR REPLACE SYNONYM metoda_plata_lowcost
FOR bdd_admin.metoda_plata;

CREATE OR REPLACE SYNONYM metoda_plata_nonlowcost
FOR metoda_plata@non_lowcost;

CREATE OR REPLACE VIEW metoda_plata
AS
SELECT * FROM metoda_plata_lowcost;

SELECT * FROM metoda_plata;

-- Clasa zbor
CREATE OR REPLACE SYNONYM clasa_zbor_lowcost
FOR bdd_admin.clasa_zbor;

CREATE OR REPLACE SYNONYM clasa_zbor_nonlowcost
FOR bdd_admin.clasa_zbor@non_lowcost;

CREATE OR REPLACE VIEW clasa_zbor
AS
SELECT * FROM clasa_zbor_lowcost;

SELECT * FROM clasa_zbor;

-- Aeronava
CREATE OR REPLACE SYNONYM aeronava_lowcost
FOR bdd_admin.aeronava;

CREATE OR REPLACE SYNONYM aeronava_nonlowcost
FOR bdd_admin.aeronava@non_lowcost;

CREATE OR REPLACE VIEW aeronava
AS
SELECT * FROM aeronava_lowcost;

SELECT * FROM aeronava;

-- Destinatie
CREATE OR REPLACE SYNONYM destinatie_lowcost
FOR bdd_admin.destinatie;

CREATE OR REPLACE SYNONYM destinatie_nonlowcost
FOR bdd_admin.destinatie@non_lowcost;

CREATE OR REPLACE VIEW destinatie
AS
SELECT * FROM destinatie_lowcost;

SELECT * FROM destinatie;

-- Stat
CREATE OR REPLACE SYNONYM stat_lowcost
FOR bdd_admin.stat;

CREATE OR REPLACE SYNONYM stat_nonlowcost
FOR bdd_admin.stat@non_lowcost;

CREATE OR REPLACE VIEW stat
AS
SELECT * FROM stat_lowcost;

SELECT * FROM stat;

-- Client
CREATE OR REPLACE SYNONYM client_nongdpr_lowcost
FOR bdd_admin.client_nongdpr;

CREATE OR REPLACE SYNONYM client_nongdpr_nonlowcost
FOR bdd_admin.client_nongdpr@non_lowcost;

CREATE OR REPLACE VIEW client_nongdpr
AS
SELECT * FROM client_nongdpr_lowcost;

CREATE OR REPLACE VIEW client
AS
SELECT ngdpr.client_id, ngdpr.premium, ngdpr.data_inregistrare, gdpr.nume, gdpr.prenume, gdpr.email, gdpr.numar_telefon
FROM client_nongdpr ngdpr 
JOIN client_gdpr gdpr on ngdpr.client_id = gdpr.client_id;

SELECT * FROM client;

-- Triggeri pentru actualizarea datelor

CREATE OR REPLACE TRIGGER t_operator_zbor
INSTEAD OF INSERT OR DELETE ON operator_zbor
FOR EACH ROW
BEGIN
 IF INSERTING THEN
     IF :new.tip = 'Non low cost' THEN
        INSERT INTO operator_zbor_nonlowcost (OPERATOR_ID, NUME, TIP) 
        VALUES (:new.operator_id, :new.nume, :new.tip);
     ELSE
        INSERT INTO operator_zbor_lowcost (OPERATOR_ID, NUME, TIP) 
        VALUES (:new.operator_id, :new.nume, :new.tip);
    END IF;
 END IF;    
 
 IF DELETING THEN
     IF :new.tip = 'Non low cost' THEN
        DELETE FROM operator_zbor_nonlowcost 
        WHERE operator_id = :old.operator_id;
     ELSE     
        DELETE FROM operator_zbor_lowcost 
        WHERE operator_id = :old.operator_id;
     END IF;
 END IF;     
END;
/

CREATE OR REPLACE TRIGGER t_zbor
INSTEAD OF INSERT OR DELETE ON zbor
FOR EACH ROW
DECLARE
    tip VARCHAR2(15);
BEGIN
    SELECT oz.tip INTO tip
    FROM operator_zbor oz
    WHERE oz.operator_id = :new.operator_id;
    
    IF INSERTING THEN
        IF tip = 'Non low cost' THEN
            INSERT INTO zbor_nonlowcost (OPERATOR_ID, AERONAVA_ID, LOCATIE_PLECARE_ID, LOCATIE_SOSIRE_ID, DATA_PLECARE, DURATA, DISTANTA, DATA_SOSIRE, ANULAT, ZBOR_ID, TOTAL_LOCURI) 
            VALUES (:new.OPERATOR_ID, :new.AERONAVA_ID, :new.LOCATIE_PLECARE_ID, :new.LOCATIE_SOSIRE_ID, :new.DATA_PLECARE,:new.DURATA,:new.DISTANTA,:new.DATA_SOSIRE,:new.ANULAT,:new.ZBOR_ID,:new.TOTAL_LOCURI);
        ELSE
            INSERT INTO zbor_lowcost (OPERATOR_ID, AERONAVA_ID, LOCATIE_PLECARE_ID, LOCATIE_SOSIRE_ID, DATA_PLECARE, DURATA, DISTANTA, DATA_SOSIRE, ANULAT, ZBOR_ID, TOTAL_LOCURI) 
            VALUES (:new.OPERATOR_ID, :new.AERONAVA_ID, :new.LOCATIE_PLECARE_ID, :new.LOCATIE_SOSIRE_ID, :new.DATA_PLECARE,:new.DURATA,:new.DISTANTA,:new.DATA_SOSIRE,:new.ANULAT,:new.ZBOR_ID,:new.TOTAL_LOCURI);
        END IF;
    END IF;
    
    IF DELETING THEN
        IF tip = 'Non low cost' THEN
            DELETE FROM zbor_nonlowcost WHERE zbor_id = :old.zbor_id;
        ELSE
            DELETE FROM zbor_lowcost WHERE zbor_id = :old.zbor_id;
        END IF;            
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_rezervare
INSTEAD OF INSERT OR DELETE ON rezervare
FOR EACH ROW
DECLARE
    tip VARCHAR2(15);
BEGIN
    SELECT oz.tip INTO tip
    FROM operator_zbor oz
    JOIN zbor z on oz.operator_id = z.operator_id
    WHERE :new.zbor_id = z.zbor_id;

    IF INSERTING THEN
     IF tip = 'Non low cost' THEN
        INSERT INTO rezervare_nonlowcost (REZERVARE_ID, NR_PASAGERI, NR_PASAGERI_FEMEI, NR_PASAGERI_BARBATI, DATA_REZERVARE, CLIENT_ID, ZBOR_ID, CLASA_ZBOR_ID, PLATA_ID) 
        VALUES (:new.REZERVARE_ID, :new.NR_PASAGERI, :new.NR_PASAGERI_FEMEI, :new.NR_PASAGERI_BARBATI, :new.DATA_REZERVARE,:new.CLIENT_ID,:new.ZBOR_ID,:new.CLASA_ZBOR_ID,:new.PLATA_ID);
     ELSE
        INSERT INTO rezervare_lowcost (REZERVARE_ID, NR_PASAGERI, NR_PASAGERI_FEMEI, NR_PASAGERI_BARBATI, DATA_REZERVARE, CLIENT_ID, ZBOR_ID, CLASA_ZBOR_ID, PLATA_ID) 
        VALUES (:new.REZERVARE_ID, :new.NR_PASAGERI, :new.NR_PASAGERI_FEMEI, :new.NR_PASAGERI_BARBATI, :new.DATA_REZERVARE,:new.CLIENT_ID,:new.ZBOR_ID,:new.CLASA_ZBOR_ID,:new.PLATA_ID);
     END IF;    
    END IF;
    
    IF DELETING THEN
     IF tip = 'Non low cost' THEN
        DELETE FROM rezervare_nonlowcost WHERE rezervare_id = :old.rezervare_id;
     ELSE 
        DELETE FROM rezervare_lowcost WHERE rezervare_id = :old.rezervare_id;
     END IF;        
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_plata
INSTEAD OF INSERT OR DELETE ON plata
FOR EACH ROW
DECLARE
    tip VARCHAR2(15);
BEGIN
    SELECT oz.tip INTO tip
    FROM operator_zbor oz
    JOIN zbor z on oz.operator_id = z.operator_id
    JOIN rezervare r on r.zbor_id = z.zbor_id
    WHERE :new.plata_id = r.plata_id;

    IF INSERTING THEN
        IF tip = 'Non low cost' THEN
            INSERT INTO plata_nonlowcost (PLATA_ID, METODA_PLATA_ID, SUMA_TOTALA, DATA_PLATA) 
            VALUES (:new.PLATA_ID, :new.METODA_PLATA_ID, :new.SUMA_TOTALA, :new.DATA_PLATA);
        ELSE
            INSERT INTO plata_lowcost (PLATA_ID, METODA_PLATA_ID, SUMA_TOTALA, DATA_PLATA) 
            VALUES (:new.PLATA_ID, :new.METODA_PLATA_ID, :new.SUMA_TOTALA, :new.DATA_PLATA);
        END IF;
    END IF;
    
    IF DELETING THEN
        IF tip = 'Non low cost' THEN
            DELETE FROM plata_nonlowcost WHERE plata_id = :old.plata_id;
        ELSE 
            DELETE FROM plata_lowcost WHERE plata_id = :old.plata_id;
        END IF;    
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_client_nongdpr
INSTEAD OF INSERT OR DELETE ON client_nongdpr
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN
        INSERT INTO client_nongdpr_lowcost (CLIENT_ID, PREMIUM, DATA_INREGISTRARE)
        VALUES(:new.CLIENT_ID, :new.PREMIUM, :new.DATA_INREGISTRARE);
    END IF;
    
    IF DELETING THEN
        DELETE FROM client_nongdpr_lowcost WHERE client_id = :old.client_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_client
INSTEAD OF INSERT OR DELETE ON client
FOR EACH ROW
DECLARE
nr number(1);
BEGIN
    IF INSERTING THEN
        select count(*) into nr
        from  client_nongdpr non, client_gdpr gdpr
        where non.client_id = gdpr.client_id
        and non.premium = :new.premium
        and gdpr.email = :new.email;

        if (nr<>0) then
             raise_application_error (-20001,'Constangere de unicitate pe email si premium
             incalcata. Fragmentele contin deja aceste valori');
        end if;

        if (:new.numar_telefon LIKE '001-%' OR :new.numar_telefon LIKE '+1%') then
            if (:new.premium = 0) then
                raise_application_error (-20001,'validare incalcata. Toti clientii din America din Nord
                (cu prefixul 001 sau +1 la nr de telefon) trebuie sa fie clienti premium');
            end if;
        end if;

        INSERT INTO client_nongdpr (CLIENT_ID, PREMIUM, DATA_INREGISTRARE)
        VALUES(:new.CLIENT_ID, :new.PREMIUM, :new.DATA_INREGISTRARE);
        
        INSERT INTO client_gdpr (CLIENT_ID, NUME, PRENUME, EMAIL, NUMAR_TELEFON)
        VALUES(:new.CLIENT_ID, :new.NUME, :new.PRENUME, :new.EMAIL, :new.NUMAR_TELEFON);
    END IF;
    
    IF DELETING THEN
        DELETE FROM client_nongdpr WHERE client_id = :old.client_id;
        DELETE FROM client_gdpr WHERE client_id = :old.client_id;
    END IF;
END;
/

select * from client;
insert into client VALUES (1000000, 0, current_date, 'ceva', 'ceva', 'sherylmurray@example.com', '54546464');
insert into client VALUES (1000003, 1, current_date, 'ceva', 'ceva', 'sherylmgggurray@example.com', '001-44');
insert into client VALUES (1000003, 0, current_date, 'ceva', 'ceva', 'sherylmgggurray@example.com', '001-44');


CREATE OR REPLACE TRIGGER t_metoda_plata
INSTEAD OF INSERT OR DELETE ON metoda_plata
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN
        INSERT INTO metoda_plata_lowcost (METODA_PLATA_ID, DENUMIRE)
        VALUES(:new.METODA_PLATA_ID, :new.DENUMIRE);
    END IF;
    
    IF DELETING THEN
        DELETE FROM metoda_plata_lowcost WHERE metoda_plata_id = :old.metoda_plata_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_clasa_zbor
INSTEAD OF INSERT OR DELETE ON clasa_zbor
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN
        INSERT INTO clasa_zbor_lowcost(CLASA_ZBOR_ID, DENUMIRE)
        VALUES(:new.CLASA_ZBOR_ID, :new.DENUMIRE);
    END IF;
    
    IF DELETING THEN
        DELETE FROM clasa_zbor_lowcost WHERE clasa_zbor_id = :new.clasa_zbor_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_aeronava
INSTEAD OF INSERT OR UPDATE ON aeronava
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN     
        INSERT INTO aeronava_lowcost (PRODUCATOR, NUME, AERONAVA_ID) 
        VALUES(:new.PRODUCATOR, :new.NUME, :new.AERONAVA_ID);
    END IF;
    
    IF DELETING THEN
        DELETE FROM aeronava_lowcost 
        WHERE aeronava_id = :old.aeronava_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_destinatie
INSTEAD OF INSERT OR DELETE ON destinatie
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN
        INSERT INTO destinatie_lowcost (DESTINATIE_ID, ORAS, STAT_ID) 
        VALUES(:new.DESTINATIE_ID, :new.ORAS, :new.STAT_ID);
    END IF;
    
    IF DELETING THEN
        DELETE FROM destinatie_lowcost WHERE destinatie_id = :old.destinatie_id;
    END IF;
END;
/

CREATE OR REPLACE TRIGGER t_stat
INSTEAD OF INSERT OR DELETE ON stat
FOR EACH ROW
DECLARE
BEGIN
    IF INSERTING THEN
        INSERT INTO stat_lowcost (STAT_ID, STAT) 
        VALUES(:new.STAT_ID, :new.STAT);
    END IF;
    
    IF DELETING THEN
        DELETE FROM stat_lowcost WHERE stat_id = :old.stat_id;
    END IF;
END;
/
