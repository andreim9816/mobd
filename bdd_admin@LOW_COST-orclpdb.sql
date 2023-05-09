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


