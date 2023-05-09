--II.2) Crearea relatiilor si a fragmentelor

CREATE TABLE CLIENT_GDPR
    (client_id NUMBER(8) PRIMARY KEY,
     nume VARCHAR2(20) NOT NULL,
     prenume VARCHAR2(30) NOT NULL,
     email VARCHAR2(40) NOT NULL,
     numar_telefon VARCHAR2(30) NOT NULL
);

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
SELECT * FROM bdd_admin.client_nongdpr_lowcost;

SELECT gdpr.*, nongdpr.premium, nongdpr.data_inregistrare
FROM client_gdpr gdpr
JOIN bdd_admin.client_nongdpr_lowcost nongdpr
ON (gdpr.client_id = nongdpr.client_id);

-- completitudinea
SELECT * FROM centralizat_admin.client;

SELECT *
FROM centralizat_admin.client
MINUS
(SELECT gdpr.*, nongdpr.premium, nongdpr.data_inregistrare
FROM client_gdpr gdpr
JOIN bdd_admin.client_nongdpr_lowcost nongdpr
ON (gdpr.client_id = nongdpr.client_id));

-- disjunctia - coloanele vor fi vide
SELECT column_name
FROM user_tab_columns
WHERE table_name = UPPER('client_gdpr')
AND column_name <> 'CLIENT_ID'
INTERSECT
SELECT column_name
FROM user_tab_columns
WHERE table_name = UPPER('client_nongdpr_lowcost')
AND column_name <> 'CLIENT_ID';

-- II.3) Furnizarea formelor de transparenta pentru intreg modelul ales
-- Pentru fiecare tabela (care se afla in aceeasi baza de date sau nu) se creeaza un sinonim corespunzator, respectiv o vizualizare
-- care cuprinde datele agregate din cele 2 fragmentari orizontale

-- Operator zbor
CREATE OR REPLACE SYNONYM operator_zbor_lowcost
FOR bdd_admin.operator_zbor_lowcost;

CREATE OR REPLACE SYNONYM operator_zbor_nonlowcost
FOR bdd_admin.operator_zbor_nonlowcost@non_lowcost;

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
FOR bdd_admin.zbor_nonlowcost@non_lowcost;

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
FOR bdd_admin.rezervare_nonlowcost@non_lowcost;

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
FOR bdd_admin.plata_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW plata
AS
SELECT * FROM plata_nonlowcost
UNION ALL 
SELECT * FROM plata_lowcost;

SELECT * FROM plata;

-- Metoda Plata
CREATE OR REPLACE SYNONYM metoda_plata_lowcost
FOR bdd_admin.metoda_plata_lowcost;

CREATE OR REPLACE SYNONYM metoda_plata_nonlowcost
FOR bdd_admin.metoda_plata_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW metoda_plata
AS
SELECT * FROM metoda_plata_nonlowcost
UNION ALL 
SELECT * FROM metoda_plata_lowcost;

SELECT * FROM metoda_plata;

-- Clasa zbor
CREATE OR REPLACE SYNONYM clasa_zbor_lowcost
FOR bdd_admin.clasa_zbor_lowcost;

CREATE OR REPLACE SYNONYM clasa_zbor_nonlowcost
FOR bdd_admin.clasa_zbor_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW clasa_zbor
AS
SELECT * FROM clasa_zbor_nonlowcost
UNION ALL 
SELECT * FROM clasa_zbor_lowcost;

SELECT * FROM clasa_zbor;

-- Aeronava
CREATE OR REPLACE SYNONYM aeronava_lowcost
FOR bdd_admin.aeronava_lowcost;

CREATE OR REPLACE SYNONYM aeronava_nonlowcost
FOR bdd_admin.aeronava_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW aeronava
AS
SELECT * FROM aeronava_nonlowcost
UNION ALL 
SELECT * FROM aeronava_lowcost;

SELECT * FROM aeronava;

-- Destinatie
CREATE OR REPLACE SYNONYM destinatie_lowcost
FOR bdd_admin.destinatie_lowcost;

CREATE OR REPLACE SYNONYM destinatie_nonlowcost
FOR bdd_admin.destinatie_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW destinatie
AS
SELECT * FROM destinatie_nonlowcost
UNION ALL 
SELECT * FROM destinatie_lowcost;

SELECT * FROM destinatie;

-- Stat
CREATE OR REPLACE SYNONYM stat_lowcost
FOR bdd_admin.stat_lowcost;

CREATE OR REPLACE SYNONYM stat_nonlowcost
FOR bdd_admin.stat_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW stat
AS
SELECT * FROM stat_nonlowcost
UNION ALL 
SELECT * FROM stat_lowcost;

SELECT * FROM stat;

-- Client
CREATE OR REPLACE SYNONYM client_nongdpr_lowcost
FOR bdd_admin.client_nongdpr_lowcost;

CREATE OR REPLACE SYNONYM client_nongdpr_nonlowcost
FOR bdd_admin.client_nongdpr_nonlowcost@non_lowcost;

CREATE OR REPLACE VIEW client_nongdpr
AS
SELECT * FROM client_nongdpr_lowcost
UNION ALL 
SELECT * FROM client_nongdpr_nonlowcost;

CREATE OR REPLACE VIEW client
AS
SELECT ngdpr.*, gdpr.nume, gdpr.prenume, gdpr.email, gdpr.numar_telefon
FROM client_nongdpr ngdpr 
JOIN client_gdpr gdpr on ngdpr.client_id = gdpr.client_id;

SELECT * FROM client;
