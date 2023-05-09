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



