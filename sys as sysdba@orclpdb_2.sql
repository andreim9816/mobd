---- CREAREA UTILIZATORILOR SI ATRIBUIREA ROLURILOR

-- verificam ca ne aflam pe orclpdb_2
SHOW con_name;

-- cream utilizatorul de pe db2 (orclpdb_2)
CREATE USER bdd_admin 
IDENTIFIED BY bdd_admin
QUOTA UNLIMITED ON USERS;

-- afisam utilizatorii creati
SELECT * FROM dba_users ORDER BY created desc;

-- cream un rol de tip admin pentru a oferi drepturi utilizatorilor creati
CREATE ROLE administrator;
GRANT CREATE SESSION TO administrator;
GRANT CREATE DATABASE LINK TO administrator;
GRANT CREATE TABLE TO administrator;
GRANT CREATE SEQUENCE TO administrator;
GRANT CREATE SYNONYM TO administrator;
GRANT CREATE VIEW TO administrator;
GRANT CREATE TRIGGER TO administrator;
GRANT CREATE MATERIALIZED VIEW TO administrator;

-- afisam rolul creat
SELECT * FROM role_sys_privs
WHERE role = 'ADMINISTRATOR';

-- oferim rolul utilizatorilor
GRANT administrator TO bdd_admin;

-- verificam ca au fost aplicate rolurile
SELECT * FROM DBA_role_privs
WHERE grantee = 'BDD_ADMIN'
ORDER BY 1;
