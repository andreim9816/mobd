-- verificam ca utilizatorilor li s-au acordat privilegiile si rolul
SELECT * FROM session_privs;
SELECT * FROM session_roles;

-- crearea legaturilor
CREATE DATABASE LINK non_lowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb_2';

-- legaturile de baze de date la care are acces utilizatorul conectat
SELECT OWNER, USERNAME, DB_LINK, HOST
FROM ALL_DB_LINKS;

SELECT * FROM tab@non_lowcost;
/* Initial comanda nu va functiona. Trebuie adaugat in $ORACLE_HOME/network/admin/tnsnames.ora
ORCLPDB_2 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = orclpdb_2)
    )
  )
*/

-- II.2) Crearea relatiiloe si a fragmentelor

drop table operator_zbor_lowcost;
drop table zbor_lowcost;
drop table rezervare_lowcost;
drop table plata_lowcost;
drop table client_nongdpr;
drop table aeronava;
drop table stat;
drop table metoda_plata;
drop table clasa_zbor;
drop table destinatie;

-- crearea tabelelor
CREATE TABLE AERONAVA(
    aeronava_id varchar2(40),
    producator VARCHAR2(60),
    nume VARCHAR2(60)
);

CREATE TABLE STAT(
    stat_id VARCHAR2(3),
    stat VARCHAR2(30)
);

CREATE TABLE DESTINATIE
    (destinatie_id VARCHAR2(4),
     oras VARCHAR2(60),
     stat_id VARCHAR2(5) 
);

CREATE TABLE OPERATOR_ZBOR_LOWCOST
    (operator_id VARCHAR2(3),
     nume VARCHAR2(50) ,
     tip VARCHAR2(15)
);
     
CREATE TABLE METODA_PLATA
    (metoda_plata_id NUMBER(2),
     denumire VARCHAR2(30)
);

CREATE TABLE CLASA_ZBOR
    (clasa_zbor_id NUMBER(2),
     denumire VARCHAR2(20)
);

CREATE TABLE PLATA_LOWCOST
    (plata_id NUMBER(10),
    suma_totala NUMBER(7),
    data_plata TIMESTAMP,
    metoda_plata_id NUMBER(2)
);   

CREATE TABLE CLIENT_NONGDPR(
    client_id NUMBER(8),
    premium NUMBER,
    data_inregistrare DATE
);

CREATE TABLE ZBOR_LOWCOST(
     zbor_id NUMBER(8),
     operator_id VARCHAR2(20),
     aeronava_id VARCHAR2(40),
     durata NUMBER(4),
     distanta NUMBER(4),
     total_locuri NUMBER(4), 
     anulat NUMBER(1),
     data_plecare TIMESTAMP,
     data_sosire TIMESTAMP,
     locatie_plecare_id VARCHAR2(4),
     locatie_sosire_id VARCHAR2(4)
);

CREATE TABLE REZERVARE_LOWCOST(
     rezervare_id  NUMBER(8),
     nr_pasageri NUMBER(2),
     nr_pasageri_femei NUMBER(2),
     nr_pasageri_barbati NUMBER(2),
     data_rezervare TIMESTAMP,
     client_id NUMBER(8),
     zbor_id NUMBER(8),
     clasa_zbor_id NUMBER(2),
     plata_id NUMBER(10)
);

-- inserare date pe fragmente
INSERT INTO operator_zbor_lowcost
SELECT * FROM centralizat_admin.operator_zbor
WHERE tip = 'Low cost';

SELECT * FROM operator_zbor_lowcost;

-- verificare
--completitudinea
SELECT * FROM centralizat_admin.operator_zbor
MINUS
(SELECT * FROM operator_zbor_lowcost
UNION ALL
SELECT * FROM operator_zbor_nonlowcost@non_lowcost);

--reconstructia

-- operator_zbor inclus in (operator_zbor_lowcost U operator_zbor_nonlowcost)
SELECT * FROM centralizat_admin.operator_zbor
MINUS
(SELECT * FROM operator_zbor_lowcost
UNION ALL
SELECT * FROM operator_zbor_nonlowcost@non_lowcost);

-- (operator_zbor_lowcost U operator_zbor_nonlowcost) inclus in operator_zbor
(SELECT * FROM operator_zbor_lowcost
UNION ALL
SELECT * FROM operator_zbor_nonlowcost@non_lowcost)
MINUS
SELECT * FROM centralizat_admin.operator_zbor;

--disjunctia
SELECT * FROM operator_zbor_lowcost
INTERSECT
SELECT * FROM operator_zbor_nonlowcost@non_lowcost;


-- creare fragment zbor_lowcost
INSERT INTO zbor_lowcost
SELECT *
FROM centralizat_admin.zbor z
WHERE EXISTS
(SELECT 1
FROM operator_zbor_lowcost o
WHERE z.operator_id = o.operator_id);

SELECT * FROM zbor_lowcost;

-- verificari
--completitudinea
SELECT * FROM centralizat_admin.zbor
MINUS
(SELECT * FROM zbor_lowcost
UNION ALL
SELECT * FROM zbor_nonlowcost@non_lowcost);

--reconstructia

-- zbor inclus in (zbor_lowcost U zbor_nonlowcost)
SELECT * FROM centralizat_admin.zbor
MINUS
(SELECT * FROM zbor_lowcost
UNION ALL
SELECT * FROM zbor_nonlowcost@non_lowcost);

-- (zbor_lowcost U zbor_nonlowcost) inclus in zbor
(SELECT * FROM zbor_lowcost
UNION ALL
SELECT * FROM zbor_nonlowcost@non_lowcost)
MINUS
SELECT * FROM centralizat_admin.zbor;

--disjunctia
SELECT * FROM zbor_lowcost
INTERSECT
SELECT * FROM zbor_nonlowcost@non_lowcost;


-- creare fragment rezervare_lowcost
INSERT INTO rezervare_lowcost
SELECT *
FROM centralizat_admin.rezervare r
WHERE EXISTS
(SELECT 1
FROM zbor_lowcost z
WHERE r.zbor_id = z.zbor_id);

SELECT * FROM rezervare_lowcost;

-- verificari
--completitudinea
SELECT * FROM centralizat_admin.rezervare
MINUS
(SELECT * FROM rezervare_lowcost
UNION ALL
SELECT * FROM rezervare_nonlowcost@non_lowcost);

--reconstructia

-- rezervare inclus in (rezervare_lowcost U rezervare_nonlowcost)
SELECT * FROM centralizat_admin.rezervare
MINUS
(SELECT * FROM rezervare_lowcost
UNION ALL
SELECT * FROM rezervare_nonlowcost@non_lowcost);

-- (rezervare_lowcost U rezervare_nonlowcost) inclus in rezervare
(SELECT * FROM rezervare_lowcost
UNION ALL
SELECT * FROM rezervare_nonlowcost@non_lowcost)
MINUS
SELECT * FROM centralizat_admin.rezervare;

--disjunctia
SELECT * FROM rezervare_lowcost
INTERSECT
SELECT * FROM rezervare_nonlowcost@non_lowcost;


-- creare fragment plati_lowcost
INSERT INTO plata_lowcost
SELECT p.*
FROM centralizat_admin.plata p
JOIN rezervare_lowcost r
ON (r.plata_id = p.plata_id);

SELECT * FROM plata_lowcost;

-- verificari
--completitudinea
SELECT * FROM centralizat_admin.plata
MINUS
(SELECT * FROM plata_lowcost
UNION ALL
SELECT * FROM plata_nonlowcost@non_lowcost);

--reconstructia

-- plata inclus in (plata_lowcost U plata_nonlowcost)
SELECT * FROM centralizat_admin.plata
MINUS
(SELECT * FROM plata_lowcost
UNION ALL
SELECT * FROM plata_nonlowcost@non_lowcost);

-- (plata_lowcost U plata_nonlowcost) inclus in plata
(SELECT * FROM plata_lowcost
UNION ALL
SELECT * FROM plata_nonlowcost@non_lowcost)
MINUS
SELECT * FROM centralizat_admin.plata;

--disjunctia
SELECT * FROM plata_lowcost
INTERSECT
SELECT * FROM plata_nonlowcost@non_lowcost;


---- FRAGMENTARE VERTICALA
INSERT INTO client_nongdpr
SELECT client_id, client_premium, data_inregistrare 
FROM centralizat_admin.client;

SELECT * FROM client_nongdpr;


--constrangeri pentru fragmentul operator_zbor_low_cost
--not null
ALTER TABLE operator_zbor_lowcost
    add constraint nn_nume_operator_zbor_lowcost check (nume is NOT NULL);

ALTER TABLE operator_zbor_lowcost
    add constraint nn_tip_operator_zbor_lowcost check (tip is NOT NULL);

--primary key
alter table operator_zbor_lowcost
    add constraint pk_op_zbor_lowcost primary key (operator_id);

--unique
alter table operator_zbor_lowcost
    add constraint u_nume_operator_lowcost unique (nume);

create or replace trigger trig_operator_lowcost
before insert on operator_zbor_lowcost
for each row
declare
nr number(1);
begin
select count(*) into nr
from  operator_zbor_nonlowcost@non_lowcost
where nume = :new.nume;

if (nr<>0) then
    raise_application_error (-20001,'Constangere de unicitate pe nume
       incalcata. Fragmentul de pe non-low cost contine aceeasi valoare');
end if;
end;
/

--local
insert into operator_zbor_lowcost
values ( sec_op_zbor_lowcost.nextval, 'Spirit Air Lines', 'tip1');

--global
insert into operator_zbor_lowcost
values ( sec_op_zbor_lowcost.nextval, 'United Air Lines Inc.', 'tip1');


CREATE SEQUENCE sec_op_zbor_lowcost
    INCREMENT BY 2
    START WITH 15
    NOCYCLE;

insert into operator_zbor_lowcost
values ( sec_op_zbor_lowcost.nextval, null, 'tip1');

insert into operator_zbor_lowcost
values ( sec_op_zbor_lowcost.nextval, 'nume1', null);

insert into operator_zbor_lowcost
values ( sec_op_zbor_lowcost.nextval, 'nume1', 'tip1');

select * from operator_zbor_lowcost;

--constrangeri pentru fragmentul zbor_low_cost
--not null
ALTER TABLE zbor_lowcost
    add constraint nn_durata_zbor_lowcost check (durata is NOT NULL);

ALTER TABLE zbor_lowcost
    add constraint nn_distanta_zbor_lowcost check (distanta is NOT NULL);

ALTER TABLE zbor_lowcost
    add constraint nn_locuri_zbor_lowcost check (total_locuri is NOT NULL);

ALTER TABLE zbor_lowcost
    add constraint nn_data_plecare_zbor_lowcost check (data_plecare is NOT NULL);

ALTER TABLE zbor_lowcost
    add constraint nn_data_sosire_zbor_lowcost check (data_sosire is NOT NULL);

--check
alter table zbor_lowcost
    add constraint ck_anulat_lowcost check(anulat in (0,1));

--primary key
alter table zbor_lowcost
    add constraint pk_zbor_lowcost primary key (zbor_id);

CREATE SEQUENCE sec_zbor_lowcost
    INCREMENT BY 2
    START WITH 1048576
    NOCYCLE;

--foreign key
alter table zbor_lowcost
    add constraint fk_zbor_operator_lowcost FOREIGN key
        (operator_id) REFERENCES operator_zbor_lowcost(operator_id)
        ON DELETE CASCADE;

alter table zbor_lowcost
    add constraint fk_zbor_aeronava_lowcost FOREIGN key
        (aeronava_id) REFERENCES aeronava(aeronava_id)
        ON DELETE CASCADE;

alter table zbor_lowcost
    add constraint fk_locatie_plecare_lowcost FOREIGN key
        (locatie_plecare_id) REFERENCES destinatie(destinatie_id)
        ON DELETE CASCADE;

alter table zbor_lowcost
    add constraint fk_locatie_sosire_lowcost FOREIGN key
        (locatie_sosire_id) REFERENCES destinatie(destinatie_id)
        ON DELETE CASCADE;

insert into zbor_lowcost
values ( sec_zbor_lowcost.nextval, 1, 1, null, 100, 200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 1);

insert into zbor_lowcost
values ( sec_zbor_lowcost.nextval, 1, 1, 13, 100, 200, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 1);

insert into zbor_lowcost
values ( sec_zbor_lowcost.nextval, 1, 1, 13, 100, 200, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 1);

select count(*) from zbor_lowcost;

select * from zbor_lowcost;

--constrangeri pentru fragmentul rezervare_low_cost
--not null
ALTER TABLE rezervare_lowcost
    add constraint nn_pasageri_rezervare_lowcost check (nr_pasageri is NOT NULL);

ALTER TABLE rezervare_lowcost
    add constraint nn_pasageri_femei_rezervare_lowcost check (nr_pasageri_femei is NOT NULL);

ALTER TABLE rezervare_lowcost
    add constraint nn_pasageri_barbati_rezervare_lowcost check (nr_pasageri_barbati is NOT NULL);

ALTER TABLE rezervare_lowcost
    add constraint nn_data_rezervare_lowcost check (data_rezervare is NOT NULL);

--check
alter table rezervare_lowcost
    add constraint ck_pasageri_rezervare_lowcost check(nr_pasageri > 0);

alter table rezervare_lowcost
    add constraint ck_pasageri_femei_rezervare_lowcost check(nr_pasageri_femei >= 0);

alter table rezervare_lowcost
    add constraint ck_pasageri_barbati_rezervare_lowcost check(nr_pasageri_barbati >= 0);

--primary key
alter table rezervare_lowcost
    add constraint pk_rezervare_lowcost primary key (rezervare_id);

CREATE SEQUENCE sec_rezervare_lowcost
    INCREMENT BY 2
    START WITH 1040001
    NOCYCLE;

--foreign key
alter table rezervare_lowcost
    add constraint fk_rezervare_client_lowcost FOREIGN key
        (client_id) REFERENCES CLIENT_NONGDPR(client_id)
        ON DELETE CASCADE;

alter table rezervare_lowcost
    add constraint fk_rezervare_zbor_lowcost FOREIGN key
        (zbor_id) REFERENCES zbor_lowcost(zbor_id)
        ON DELETE CASCADE;

alter table rezervare_lowcost
    add constraint fk_rezervare_clasa_lowcost FOREIGN key
        (clasa_zbor_id) REFERENCES clasa_zbor(clasa_zbor_id)
        ON DELETE CASCADE;

alter table rezervare_lowcost
    add constraint fk_rezervare_plata_lowcost FOREIGN key
        (plata_id) REFERENCES plata_lowcost(plata_id)
        ON DELETE CASCADE;

insert into rezervare_lowcost
values ( sec_rezervare_lowcost.nextval, 5, 2, 3, CURRENT_TIMESTAMP, 1,1,1,1);

insert into rezervare_lowcost
values ( sec_rezervare_lowcost.nextval, null, 2, 3, CURRENT_TIMESTAMP, 1,1,1,1);

insert into rezervare_lowcost
values ( sec_rezervare_lowcost.nextval, 0, 2, 3, CURRENT_TIMESTAMP, 1,1,1,1);

insert into rezervare_lowcost
values ( sec_rezervare_lowcost.nextval, 5, 2, 3, null, 1,1,1,1);

select count(*) from rezervare_lowcost;

select * from zbor_lowcost;

--constrangeri pentru fragmentul plata_low_cost
--not null
ALTER TABLE plata_lowcost
    add constraint nn_suma_plata_lowcost check (suma_totala is NOT NULL);

ALTER TABLE plata_lowcost
    add constraint nn_data_plata_lowcost check (data_plata is NOT NULL);

--primary key
alter table plata_lowcost
    add constraint pk_plata_lowcost primary key (plata_id);

CREATE SEQUENCE sec_plata_lowcost
    INCREMENT BY 2
    START WITH 1040001
    NOCYCLE;

--foreign key
alter table plata_lowcost
    add constraint fk_plata_metoda_lowcost FOREIGN key
        (metoda_plata_id) REFERENCES METODA_PLATA(metoda_plata_id)
        ON DELETE CASCADE;

insert into plata_lowcost
values ( sec_plata_lowcost.nextval, 10, null, 1);

insert into plata_lowcost
values ( sec_plata_lowcost.nextval, null, CURRENT_TIMESTAMP, null);

insert into plata_lowcost
values ( sec_plata_lowcost.nextval, 100, CURRENT_TIMESTAMP, 1);

--constrangeri pentru fragmentul client_nongdpr
--not null
ALTER TABLE client_nongdpr
    add constraint nn_premium_client_nongdpr check (premium is NOT NULL);

ALTER TABLE client_nongdpr
    add constraint nn_data_client_nongdpr check (data_inregistrare is NOT NULL);

--check
alter table client_nongdpr
    add constraint ck_premium_client_nongdpr check(premium in (0,1));

--primary key
alter table client_nongdpr
    add constraint pk_client_nongdpr primary key (client_id);

CREATE SEQUENCE sec_client_nongdpr
    INCREMENT BY 1
    START WITH 10003
    NOCYCLE;


INSERT INTO client_nongdpr VALUES (sec_client_nongdpr.nextval, 1, CURRENT_DATE);
INSERT INTO client_nongdpr VALUES (sec_client_nongdpr.nextval, 5, CURRENT_DATE);
INSERT INTO client_nongdpr VALUES (sec_client_nongdpr.nextval, 1, null);


----- REPLICAREA
----- trigger unidirectional: client nongdpr, stat, metoda plata, clasa zbor
----- trigger bidirectional: destinatie
----- vizualizare materializata pentru tabela din non-low-cost: aeronava

--- inserare date metoda plata si creare trigger
ALTER TABLE metoda_plata
    add constraint nn_denumire_plata check (denumire is NOT NULL);

--primary key
alter table metoda_plata
    add constraint pk_metoda_plata primary key (metoda_plata_id);

CREATE SEQUENCE sec_metoda_plata
    INCREMENT BY 1
    START WITH 24
    NOCYCLE;

INSERT INTO metoda_plata
SELECT * FROM centralizat_admin.metoda_plata;

SELECT * FROM metoda_plata;

CREATE OR REPLACE TRIGGER t_rep_metoda_plata
AFTER INSERT OR UPDATE OR DELETE ON metoda_plata
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO metoda_plata@non_lowcost
        VALUES (:NEW.metoda_plata_id, :NEW.denumire);
    ELSIF DELETING THEN 
        DELETE FROM metoda_plata@non_lowcost
        WHERE metoda_plata_id = :OLD.metoda_plata_id;
    ELSE
        UPDATE metoda_plata@non_lowcost
        SET denumire = :NEW.denumire
        WHERE metoda_plata_id = :OLD.METODA_PLATA_ID;
    END IF;
END;
/

-- verificare inserare
INSERT INTO metoda_plata
VALUES (sec_metoda_plata.nextval, 'numerar');

SELECT * FROM metoda_plata;
COMMIT;

-- verificare update
UPDATE metoda_plata
SET denumire = 'NUMERAR'
WHERE metoda_plata_id = 4;

SELECT * FROM metoda_plata;
COMMIT;

-- verificare stergere
DELETE FROM metoda_plata
WHERE metoda_plata_id = 4;

SELECT * FROM metoda_plata;
COMMIT;

--- inserare date clasa zbor si creare trigger
ALTER TABLE clasa_zbor
    add constraint nn_denumire_clasa_zbor check (denumire is NOT NULL);

--primary key
alter table clasa_zbor
    add constraint pk_clasa_zbor primary key (clasa_zbor_id);

CREATE SEQUENCE sec_clasa_zbor
    INCREMENT BY 1
    START WITH 24
    NOCYCLE;

INSERT INTO clasa_zbor
SELECT * FROM centralizat_admin.clasa_zbor;

SELECT * FROM clasa_zbor;

CREATE OR REPLACE TRIGGER t_rep_clasa_zbor
AFTER INSERT OR UPDATE OR DELETE ON clasa_zbor
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO clasa_zbor@non_lowcost
        VALUES (:NEW.clasa_zbor_id, :NEW.denumire);
    ELSIF DELETING THEN 
        DELETE FROM clasa_zbor@non_lowcost
        WHERE clasa_zbor_id = :OLD.clasa_zbor_id;
    ELSE
        UPDATE clasa_zbor@non_lowcost
        SET denumire = :NEW.denumire
        WHERE clasa_zbor_id = :OLD.clasa_zbor_id;
    END IF;
END;
/

-- verificare inserare
INSERT INTO clasa_zbor
VALUES (sec_clasa_zbor, 'Clasa II');

SELECT * FROM clasa_zbor;
COMMIT;

-- verificare update
UPDATE clasa_zbor
SET denumire = 'CLASA II'
WHERE clasa_zbor_id = 4;

SELECT * FROM clasa_zbor;
COMMIT;

-- verificare stergere
DELETE FROM clasa_zbor
WHERE clasa_zbor_id = 4;

SELECT * FROM clasa_zbor;
COMMIT;


--- inserare date stat si creare trigger
ALTER TABLE stat
    add constraint nn_denumire_stat check (stat is NOT NULL);

--primary key
alter table stat
    add constraint pk_stat primary key (stat_id);

CREATE SEQUENCE sec_stat
    INCREMENT BY 1
    START WITH 55
    NOCYCLE;

INSERT INTO stat
SELECT * FROM centralizat_admin.stat;

SELECT * FROM stat;

CREATE OR REPLACE TRIGGER t_rep_stat
AFTER INSERT OR UPDATE OR DELETE ON stat
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO stat@non_lowcost
        VALUES (:NEW.stat_id, :NEW.stat);
    ELSIF DELETING THEN 
        DELETE FROM stat@non_lowcost
        WHERE stat_id = :OLD.stat_id;
    ELSE
        UPDATE stat@non_lowcost
        SET stat = :NEW.stat
        WHERE stat_id = :OLD.stat_id;
    END IF;
END;
/

-- verificare inserare
INSERT INTO stat
VALUES (sec_stat.nextval, 'New state');

SELECT * FROM stat;
COMMIT;

-- verificare update
UPDATE stat
SET stat = 'NEW STATE'
WHERE stat_id = 'NST';

SELECT * FROM stat;
COMMIT;

-- verificare stergere
DELETE FROM stat
WHERE stat_id = 'NST';

SELECT * FROM stat;
COMMIT;

--- inserare date client_nongdpr si creare trigger
SELECT * FROM client_nongdpr;

CREATE OR REPLACE TRIGGER t_rep_client_nongdpr
AFTER INSERT OR UPDATE OR DELETE ON client_nongdpr
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO client_nongdpr@non_lowcost
        VALUES (:NEW.client_id, :NEW.premium, :NEW.data_inregistrare);
    ELSIF DELETING THEN 
        DELETE FROM client_nongdpr@non_lowcost
        WHERE client_id = :OLD.client_id;
    ELSE
        UPDATE client_nongdpr@non_lowcost
        SET premium = :NEW.premium, data_inregistrare = :NEW.data_inregistrare
        WHERE client_id = :OLD.client_id;
    END IF;
END;
/

-- verificare inserare
INSERT INTO client_nongdpr
VALUES (sec_client_nongdpr.nextval, 0, sysdate);

SELECT * FROM client_nongdpr ORDER BY 1 DESC;
COMMIT;

-- verificare update
UPDATE client_nongdpr
SET premium = 1
WHERE client_id = 10001;

SELECT * FROM client_nongdpr ORDER BY 1 DESC;
COMMIT;

-- verificare stergere
DELETE FROM client_nongdpr
WHERE  client_id = 10001;

SELECT * FROM client_nongdpr ORDER BY 1 DESC;
COMMIT;

-- inserare date aeronava
ALTER TABLE aeronava
    add constraint nn_producator_aeronava check (producator is NOT NULL);

ALTER TABLE aeronava
    add constraint nn_nume_aeronava check (nume is NOT NULL);

--primary key
alter table aeronava
    add constraint pk_aeronava primary key (aeronava_id);

CREATE SEQUENCE sec_aeronava
    INCREMENT BY 1
    START WITH 147
    NOCYCLE;

INSERT INTO aeronava
SELECT * FROM centralizat_admin.aeronava;

SELECT * FROM aeronava;

alter table aeronava
add constraint pk_aeronava primary key (aeronava_id);

CREATE MATERIALIZED VIEW
LOG ON aeronava
WITH PRIMARY KEY;

-- verificare insert
INSERT INTO aeronava
VALUES (sec_aeronava.nextval, 'BOEING Bros', 'Boeing 181-294-142');

SELECT * FROM aeronava
ORDER BY 1;

COMMIT;

-- verificare update
UPDATE aeronava
SET producator = 'BOEING BROS'
WHERE aeronava_id = '0000';

SELECT * FROM aeronava
ORDER BY 1;

COMMIT;

-- verificare delete
DELETE FROM aeronava
WHERE aeronava_id = '0000';

COMMIT;

--- replicare destinatie
ALTER TABLE destinatie
    add constraint nn_oras_destinatie check (oras is NOT NULL);

--primary key
alter table destinatie
    add constraint pk_destinatie primary key (destinatie_id);

CREATE SEQUENCE sec_destinatie
    INCREMENT BY 1
    START WITH 323
    NOCYCLE;

alter table destinatie
    add constraint fk_destinatie_stat FOREIGN key
        (stat_id) REFERENCES stat(stat_id);

INSERT INTO destinatie
SELECT * FROM centralizat_admin.destinatie;

SELECT * FROM destinatie;

CREATE OR REPLACE TRIGGER t_rep_destinatie
AFTER INSERT OR UPDATE OR DELETE ON destinatie
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO destinatie@non_lowcost
        VALUES (:NEW.destinatie_id, :NEW.oras, :NEW.stat_id);
    ELSIF DELETING THEN 
        DELETE FROM destinatie@non_lowcost
        WHERE destinatie_id = :OLD.destinatie_id;
    ELSE
        UPDATE destinatie@non_lowcost
        SET oras = :NEW.oras, stat_id = :NEW.stat_id
        WHERE destinatie_id = :OLD.destinatie_id;
    END IF;
END;
/

-- verificare insert
INSERT INTO destinatie
VALUES (sec_destinatie.nextval, 'Allinghton', 'SD');

SELECT * FROM destinatie
ORDER BY 1;

COMMIT;

-- verificare update
UPDATE destinatie
SET oras = 'Allinghton Town'
WHERE destinatie_id = 'ABC';

SELECT * FROM destinatie
ORDER BY 1;

COMMIT;

-- verificare delete
DELETE FROM destinatie
WHERE destinatie_id = 'ABC';

COMMIT;

-- II.4) Furnizarea formelor de transparenta pentru intreg modelul ales
-- Pentru fiecare tabela (care se afla in aceeasi baza de date sau nu) se creeaza un sinonim corespunzator, respectiv o vizualizare
-- care cuprinde datele agregate din cele 2 fragmentari orizontale

-- Operator Zbor
CREATE OR REPLACE SYNONYM operator_zbor_nonlowcost
FOR bdd_admin.operator_zbor_nonlowcost@non_lowcost;

CREATE OR REPLACE SYNONYM operator_zbor
FOR operator_zbor_lowcost;

-- Zbor
CREATE OR REPLACE SYNONYM zbor_nonlowcost
FOR bdd_admin.zbor_nonlowcost@non_lowcost;

CREATE OR REPLACE SYNONYM zbor
FOR zbor_lowcost;

-- Rezervare
CREATE OR REPLACE SYNONYM rezervare_nonlowcost
FOR bdd_admin.rezervare_nonlowcost@non_lowcost;

CREATE OR REPLACE SYNONYM rezervare
FOR rezervare_lowcost;

-- Plata
CREATE OR REPLACE SYNONYM plata_nonlowcost
FOR bdd_admin.plata_nonlowcost@non_lowcost;

CREATE OR REPLACE SYNONYM plata
FOR plata_lowcost;

-- Metoda Plata
CREATE OR REPLACE SYNONYM metoda_plata_nonlowcost
FOR bdd_admin.metoda_plata_nonlowcost@non_lowcost;

-- Clasa Zbor
CREATE OR REPLACE SYNONYM clasa_zbor_nonlowcost
FOR bdd_admin.clasa_zbor_nonlowcost@non_lowcost;

-- Aeronava
CREATE OR REPLACE SYNONYM aeronava_nonlowcost
FOR bdd_admin.aeronava_nonlowcost@non_lowcost;

-- Destinatie
CREATE OR REPLACE SYNONYM destinatie_nonlowcost
FOR bdd_admin.destinatie_nonlowcost@non_lowcost;

-- Stat
CREATE OR REPLACE SYNONYM stat_nonlowcost
FOR bdd_admin.stat_nonlowcost@non_lowcost;

-- Client
CREATE OR REPLACE SYNONYM client_nongdpr_nonlowcost
FOR bdd_admin.client_nongdpr_nonlowcost@non_lowcost;
