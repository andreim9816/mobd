-- verificam ca utilizatorilor li s-au acordat privilegiile si rolul
SELECT * FROM session_privs;
SELECT * FROM session_roles;

--II.2) Crearea relatiilor si a fragmentelor

-- crearea legaturilor
CREATE DATABASE LINK lowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb';

CREATE DATABASE LINK centralizat
CONNECT TO centralizat_admin
IDENTIFIED BY centralizat_admin
USING 'orclpdb';

CREATE DATABASE LINK global
CONNECT TO global_admin
IDENTIFIED BY global_admin
USING 'orclpdb';

SELECT * FROM tab@lowcost;
SELECT * FROM tab@centralizat;
SELECT * FROM tab@global;

-- legaturile de baze de date la care are acces utilizatorul conectat
SELECT OWNER, USERNAME, DB_LINK, HOST
FROM ALL_DB_LINKS;

drop table operator_zbor_nonlowcost;
drop table zbor_nonlowcost;
drop table rezervare_nonlowcost;
drop table plata_nonlowcost;
drop table client_nongdpr;
drop table aeronava;
drop table stat;
drop table metoda_plata;
drop table clasa_zbor;
drop table destinatie;

-- crearea tabelelor

CREATE TABLE STAT(
    stat_id VARCHAR2(3),
    stat VARCHAR2(30)
);

CREATE TABLE DESTINATIE
    (destinatie_id VARCHAR2(4),
     oras VARCHAR2(60),
     stat_id VARCHAR2(5) 
);

CREATE TABLE OPERATOR_ZBOR_NONLOWCOST
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

CREATE TABLE PLATA_NONLOWCOST
    (plata_id NUMBER(10),
    suma_totala NUMBER(7),
    data_plata TIMESTAMP,
    metoda_plata_id NUMBER(2),
    rezervare_id NUMBER(10)
);   

CREATE TABLE CLIENT_NONGDPR (
    client_id NUMBER(8),
    premium NUMBER,
    data_inregistrare DATE
);

CREATE TABLE ZBOR_NONLOWCOST(
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

CREATE TABLE REZERVARE_NONLOWCOST(
     rezervare_id  NUMBER(8),
     nr_pasageri NUMBER(2),
     nr_pasageri_femei NUMBER(2),
     nr_pasageri_barbati NUMBER(2),
     data_rezervare TIMESTAMP,
     client_id NUMBER(8),
     zbor_id NUMBER(8),
     clasa_zbor_id NUMBER(2)
);

-- inserare date pe fragmente
-- creare fragment operator_zbor_nonlowcost
INSERT INTO operator_zbor_nonlowcost
SELECT * FROM operator_zbor@centralizat
WHERE tip = 'Non low cost';

SELECT * FROM operator_zbor_nonlowcost;

-- creare fragment zbor_nonlowcost
INSERT INTO zbor_nonlowcost
SELECT *
FROM zbor@centralizat z
WHERE EXISTS
(SELECT 1
FROM operator_zbor_nonlowcost o
WHERE z.operator_id = o.operator_id);

SELECT * FROM zbor_nonlowcost;

-- creare fragment rezervare_nonlowcost
INSERT INTO rezervare_nonlowcost
SELECT *
FROM rezervare@centralizat r
WHERE EXISTS
(SELECT 1
FROM zbor_nonlowcost z
WHERE r.zbor_id = z.zbor_id);

SELECT * FROM rezervare_nonlowcost;

-- creare fragment plati_nonlowcost
INSERT INTO plata_nonlowcost
SELECT p.*
FROM plata@centralizat p
JOIN rezervare_nonlowcost r
ON (r.rezervare_id = p.rezervare_id);

SELECT * FROM plata_nonlowcost;

COMMIT;

-- FRAGMENTARE VERTICALA
INSERT INTO client_nongdpr
SELECT client_id, client_premium, data_inregistrare 
FROM client@centralizat;

SELECT * FROM client_nongdpr;


--constrangeri pentru fragmentul operator_zbor_nonlow_cost
--not null
ALTER TABLE operator_zbor_nonlowcost
    add constraint nn_nume_operator_zbor_nonlowcost check (nume is NOT NULL);

ALTER TABLE operator_zbor_nonlowcost
    add constraint nn_tip_operator_zbor_nonlowcost check (tip is NOT NULL);

--primary key
alter table operator_zbor_nonlowcost
    add constraint pk_op_zbor_nonlowcost primary key (operator_id);

--unique
alter table operator_zbor_nonlowcost
    add constraint u_nume_operator_nonlowcost unique (nume);

create or replace trigger trig_operator_nonlowcost
before insert on operator_zbor_nonlowcost
for each row
declare
nr number(1);
begin
select count(*) into nr
from  operator_zbor_lowcost@lowcost
where nume = :new.nume;

if (nr<>0) then
    raise_application_error (-20001,'Constangere de unicitate pe nume
       incalcata. Fragmentul de pe low cost contine aceeasi valoare');
end if;
end;
/
select * from operator_zbor_nonlowcost;

--local
insert into operator_zbor_nonlowcost
values ('A', 'Hawaiian Airlines Inc.', 'tip1');

--global
insert into operator_zbor_nonlowcost
values ('B', 'United Air Lines Inc.', 'tip1');

insert into operator_zbor_nonlowcost
values ('1', null, 'tip1');

insert into operator_zbor_nonlowcost
values ('2', 'nume1', null);

insert into operator_zbor_nonlowcost
values ('3', 'nume1', 'tip1');

select * from operator_zbor_nonlowcost;

--constrangeri pentru fragmentul zbor_nonlow_cost
--not null
ALTER TABLE zbor_nonlowcost
    add constraint nn_durata_zbor_nonlowcost check (durata is NOT NULL);

ALTER TABLE zbor_nonlowcost
    add constraint nn_distanta_zbor_nonlowcost check (distanta is NOT NULL);

ALTER TABLE zbor_nonlowcost
    add constraint nn_locuri_zbor_nonlowcost check (total_locuri is NOT NULL);

ALTER TABLE zbor_nonlowcost
    add constraint nn_data_plecare_zbor_nonlowcost check (data_plecare is NOT NULL);

ALTER TABLE zbor_nonlowcost
    add constraint nn_data_sosire_zbor_nonlowcost check (data_sosire is NOT NULL);

--check
alter table zbor_nonlowcost
    add constraint ck_anulat_nonlowcost check(anulat in (0,1));

--primary key
alter table zbor_nonlowcost
    add constraint pk_zbor_nonlowcost primary key (zbor_id);

CREATE SEQUENCE sec_zbor_nonlowcost
    INCREMENT BY 2
    START WITH 1048577
    NOCYCLE;

CREATE OR REPLACE SYNONYM seq_zbor
FOR sec_zbor_nonlowcost;

--foreign key
alter table zbor_nonlowcost
    add constraint fk_zbor_operator_nonlowcost FOREIGN key
        (operator_id) REFERENCES operator_zbor_nonlowcost(operator_id)
        ON DELETE CASCADE;

alter table zbor_nonlowcost
    add constraint fk_zbor_aeronava_nonlowcost FOREIGN key
        (aeronava_id) REFERENCES aeronava(aeronava_id)
        ON DELETE CASCADE;

alter table zbor_nonlowcost
    add constraint fk_locatie_plecare_nonlowcost FOREIGN key
        (locatie_plecare_id) REFERENCES destinatie(destinatie_id)
        ON DELETE CASCADE;

alter table zbor_nonlowcost
    add constraint fk_locatie_sosire_nonlowcost FOREIGN key
        (locatie_sosire_id) REFERENCES destinatie(destinatie_id)
        ON DELETE CASCADE;

insert into zbor_nonlowcost
values ( sec_zbor_nonlowcost.nextval, 1, 1, null, 100, 200, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 1);

insert into zbor_nonlowcost
values ( sec_zbor_nonlowcost.nextval, 1, 1, 13, 100, 200, 5, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 1);

insert into zbor_nonlowcost
values ( sec_zbor_nonlowcost.nextval, 1, 1, 13, 100, 200, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, 1, 1);

select count(*) from zbor_nonlowcost;
SELECT * FROM OPERATOR_ZBOR_nonLOWCOST;


--constrangeri pentru fragmentul rezervare_nonlow_cost
--not null
ALTER TABLE rezervare_nonlowcost
    add constraint nn_pasageri_rezervare_nonlowcost check (nr_pasageri is NOT NULL);

ALTER TABLE rezervare_nonlowcost
    add constraint nn_pasageri_femei_rezervare_nonlowcost check (nr_pasageri_femei is NOT NULL);

ALTER TABLE rezervare_nonlowcost
    add constraint nn_pasageri_barbati_rezervare_nonlowcost check (nr_pasageri_barbati is NOT NULL);

ALTER TABLE rezervare_nonlowcost
    add constraint nn_data_rezervare_nonlowcost check (data_rezervare is NOT NULL);

--check
alter table rezervare_nonlowcost
    add constraint ck_pasageri_rezervare_nonlowcost check(nr_pasageri > 0);

alter table rezervare_nonlowcost
    add constraint ck_pasageri_femei_rezervare_nonlowcost check(nr_pasageri_femei >= 0);

alter table rezervare_nonlowcost
    add constraint ck_pasageri_barbati_rezervare_nonlowcost check(nr_pasageri_barbati >= 0);

--primary key
alter table rezervare_nonlowcost
    add constraint pk_rezervare_nonlowcost primary key (rezervare_id);

CREATE SEQUENCE sec_rezervare_nonlowcost
    INCREMENT BY 2
    START WITH 1040002
    NOCYCLE;

CREATE OR REPLACE SYNONYM seq_rezervare
FOR sec_rezervare_nonlowcost;

--foreign key
alter table rezervare_nonlowcost
    add constraint fk_rezervare_client_nonlowcost FOREIGN key
        (client_id) REFERENCES CLIENT_NONGDPR(client_id)
        ON DELETE CASCADE;

alter table rezervare_nonlowcost
    add constraint fk_rezervare_zbor_nonlowcost FOREIGN key
        (zbor_id) REFERENCES zbor_nonlowcost(zbor_id)
        ON DELETE CASCADE;

alter table rezervare_nonlowcost
    add constraint fk_rezervare_clasa_nonlowcost FOREIGN key
        (clasa_zbor_id) REFERENCES clasa_zbor(clasa_zbor_id)
        ON DELETE CASCADE;

insert into rezervare_nonlowcost
values ( sec_rezervare_nonlowcost.nextval, 5, 2, 3, CURRENT_TIMESTAMP, 1,1,1);

insert into rezervare_nonlowcost
values ( sec_rezervare_nonlowcost.nextval, null, 2, 3, CURRENT_TIMESTAMP, 1,1,1);

insert into rezervare_nonlowcost
values ( sec_rezervare_nonlowcost.nextval, 0, 2, 3, CURRENT_TIMESTAMP, 1,1,1);

insert into rezervare_nonlowcost
values ( sec_rezervare_nonlowcost.nextval, 5, 2, 3, null, 1,1,1);


--constrangeri pentru fragmentul plata_nonlow_cost
--not null
ALTER TABLE plata_nonlowcost
    add constraint nn_suma_plata_nonlowcost check (suma_totala is NOT NULL);

ALTER TABLE plata_nonlowcost
    add constraint nn_data_plata_nonlowcost check (data_plata is NOT NULL);

--primary key
alter table plata_nonlowcost
    add constraint pk_plata_nonlowcost primary key (plata_id);

CREATE SEQUENCE sec_plata_nonlowcost
    INCREMENT BY 2
    START WITH 1040002
    NOCYCLE;

CREATE OR REPLACE SYNONYM seq_plata
FOR sec_plata_nonlowcost;

--foreign key
alter table plata_nonlowcost
    add constraint fk_plata_metoda_nonlowcost FOREIGN key
        (metoda_plata_id) REFERENCES METODA_PLATA(metoda_plata_id)
        ON DELETE CASCADE;

alter table plata_nonlowcost
    add constraint fk_rezervare_rezervare_nonlowcost FOREIGN key
        (rezervarea_id) REFERENCES rezervare_nonlowcost(rezervare_id)
        ON DELETE CASCADE;

insert into plata_nonlowcost
values ( sec_plata_nonlowcost.nextval, 10, null, 1, 1);

insert into plata_nonlowcost
values ( sec_plata_nonlowcost.nextval, null, CURRENT_TIMESTAMP, null, 1);

insert into plata_nonlowcost
values ( sec_plata_nonlowcost.nextval, 100, CURRENT_TIMESTAMP, 1, 1);

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

--- REPLICARE
--- metoda plata
ALTER TABLE metoda_plata
    add constraint nn_denumire_plata check (denumire is NOT NULL);

--primary key
alter table metoda_plata
    add constraint pk_metoda_plata primary key (metoda_plata_id);

CREATE OR REPLACE SYNONYM seq_metoda_plata
    FOR bdd_admin.seq_metoda_plata@lowcost;

INSERT INTO metoda_plata
SELECT * FROM metoda_plata@centralizat;

SELECT * FROM metoda_plata;

-- clasa zbor
ALTER TABLE clasa_zbor
    add constraint nn_denumire_clasa_zbor check (denumire is NOT NULL);

--primary key
alter table clasa_zbor
    add constraint pk_clasa_zbor primary key (clasa_zbor_id);

CREATE SYNONYM seq_clasa_zbor
    FOR bdd_admin.seq_clasa_zbor@lowcost;

INSERT INTO clasa_zbor
SELECT * FROM clasa_zbor@centralizat;

SELECT * FROM clasa_zbor;

-- stat
ALTER TABLE stat
    add constraint nn_denumire_stat check (stat is NOT NULL);

--primary key
alter table stat
    add constraint pk_stat primary key (stat_id);

INSERT INTO stat
SELECT * FROM stat@centralizat;

SELECT * FROM stat;

-- client nongdpr
SELECT * FROM client_nongdpr 
ORDER BY 1 DESC;

-- aeronava: cream o vizualizare materializata
ALTER TABLE aeronava
    add constraint nn_producator_aeronava check (producator is NOT NULL);

ALTER TABLE aeronava
    add constraint nn_nume_aeronava check (nume is NOT NULL);

--primary key
alter table aeronava
    add constraint pk_aeronava primary key (aeronava_id);

CREATE MATERIALIZED VIEW aeronava
REFRESH FAST
START WITH SYSDATE
NEXT SYSDATE + 1
WITH PRIMARY KEY
AS SELECT * FROM aeronava@lowcost;

-- verificare insert, update
SELECT * FROM aeronava
ORDER BY 1;

SELECT * 
FROM mlog$_aeronava@lowcost;

EXECUTE DBMS_MVIEW.REFRESH(UPPER('aeronava'), 'F');

--- replicare destinatie
ALTER TABLE destinatie
    add constraint nn_oras_destinatie check (oras is NOT NULL);

--primary key
alter table destinatie
    add constraint pk_destinatie primary key (destinatie_id);

alter table destinatie
    add constraint fk_destinatie_stat FOREIGN key
        (stat_id) REFERENCES stat(stat_id);

INSERT INTO destinatie
SELECT * FROM destinatie@centralizat;

SELECT * FROM destinatie
ORDER BY 1;
-- II.3) Furnizarea formelor de transparenta pentru intreg modelul ales
-- Pentru fiecare tabela (care se afla in aceeasi baza de date sau nu) se creeaza un sinonim corespunzator, respectiv o vizualizare
-- care cuprinde datele agregate din cele 2 fragmentari orizontale

-- Operator Zbor
CREATE OR REPLACE SYNONYM operator_zbor_lowcost
FOR bdd_admin.operator_zbor_lowcost@lowcost;

CREATE OR REPLACE SYNONYM operator_zbor
FOR operator_zbor_nonlowcost;

-- Zbor
CREATE OR REPLACE SYNONYM zbor_lowcost
FOR bdd_admin.zbor_lowcost@lowcost;

CREATE OR REPLACE SYNONYM zbor
FOR zbor_nonlowcost;

-- Rezervare
CREATE OR REPLACE SYNONYM rezervare_lowcost
FOR bdd_admin.rezervare_lowcost@lowcost;

CREATE OR REPLACE SYNONYM rezervare
FOR rezervare_nonlowcost;

-- Plata
CREATE OR REPLACE SYNONYM plata_lowcost
FOR bdd_admin.plata_lowcost@lowcost;

CREATE OR REPLACE SYNONYM plata
FOR plata_nonlowcost;

-- Metoda Plata
CREATE OR REPLACE SYNONYM metoda_plata_lowcost
FOR bdd_admin.metoda_plata_lowcost@lowcost;

-- Clasa Zbor
CREATE OR REPLACE SYNONYM clasa_zbor_lowcost
FOR bdd_admin.clasa_zbor_lowcost@lowcost;

-- Aeronava
CREATE OR REPLACE SYNONYM aeronava_lowcost
FOR bdd_admin.aeronava_lowcost@lowcost;

-- Destinatie
CREATE OR REPLACE SYNONYM destinatie_lowcost
FOR bdd_admin.destinatie_lowcost@lowcost;

-- Stat
CREATE OR REPLACE SYNONYM stat_lowcost
FOR bdd_admin.stat_lowcost@lowcost;

select count(*) from client_nongdpr;
select client0_.CLIENT_ID as client_id1_2_0_, 
client0_.DATA_INREGISTRARE as data_inregistrare2_2_0_,
client0_.email as email3_2_0_, 
client0_.NUMAR_TELEFON as numar_telefon4_2_0_,
client0_.nume as nume5_2_0_, 
client0_.PREMIUM as premium6_2_0_,
client0_.prenume as prenume7_2_0_ 
from CLIENT client0_ where client0_.CLIENT_ID=1;

-- Client
CREATE OR REPLACE SYNONYM client_nongdpr_lowcost
FOR bdd_admin.client_nongdpr@lowcost;

CREATE OR REPLACE SYNONYM client_gdpr
FOR global_admin.client_gdpr@global;

CREATE OR REPLACE VIEW client AS 
SELECT gdpr.client_id, gdpr.nume, gdpr.prenume, gdpr.email, gdpr.numar_telefon, non.data_inregistrare,non.premium
   FROM client_gdpr gdpr
   JOIN client_nongdpr non ON gdpr.client_id = non.client_id;

select * from client;
