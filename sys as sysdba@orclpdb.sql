-- II.1) Crearea bazelor de date si a utilizatorilor

CREATE USER global_admin IDENTIFIED BY global_admin;
GRANT CREATE SESSION TO global_admin;
GRANT CREATE TABLE TO global_admin;
GRANT CREATE SEQUENCE TO global_admin;
GRANT CREATE DATABASE LINK TO global_admin;
ALTER USER global_admin QUOTA UNLIMITED ON USERS;

CREATE USER centralizat_admin IDENTIFIED BY centralizat_admin;
GRANT CREATE SESSION TO centralizat_admin;
GRANT CREATE TABLE TO centralizat_admin;
GRANT CREATE SEQUENCE TO centralizat_admin;
GRANT CREATE DATABASE LINK TO centralizat_admin;
ALTER USER centralizat_admin QUOTA UNLIMITED ON USERS;

CREATE USER bdd_admin IDENTIFIED BY bdd_admin;
GRANT CREATE SESSION TO bdd_admin;
GRANT CREATE TABLE TO bdd_admin;
GRANT CREATE SEQUENCE TO bdd_admin;
GRANT CREATE DATABASE LINK TO bdd_admin;
ALTER USER bdd_admin QUOTA UNLIMITED ON USERS;

-- Userul bdd_admin trebuie sa primeasca acces la tabelele din schema utilizatorului centralizat_admin
CREATE OR REPLACE PROCEDURE grant_select(
    p_username VARCHAR2, 
    p_grantee VARCHAR2)
AS   
    v_cmd VARCHAR2(100);
BEGIN
    FOR r IN (
        SELECT owner, table_name 
        FROM all_tables 
        WHERE owner = UPPER(p_username)
    )
    LOOP
    v_cmd := 'GRANT SELECT ON '||r.owner||'.'||r.table_name||' TO ' || p_grantee;
    EXECUTE IMMEDIATE v_cmd;
    END LOOP;
END;
/

BEGIN
    grant_select('centralizat_admin','bdd_admin'); 
END;
/