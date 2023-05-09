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

SELECT * FROM tab@lowcost;
SELECT * FROM tab@centralizat;

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
    metoda_plata_id NUMBER(2)
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
     clasa_zbor_id NUMBER(2),
     plata_id NUMBER(10)
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
ON (r.plata_id = p.plata_id);

SELECT * FROM plata_nonlowcost;

COMMIT;