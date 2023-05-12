---- CREAREA UTILIZATORILOR SI ATRIBUIREA ROLURILOR

-- verificam ca ne aflam pe orclpdb
SHOW con_name;

-- cream utilizatorii de pe db1 (orclpdb)
CREATE USER bdd_admin 
IDENTIFIED BY bdd_admin
QUOTA UNLIMITED ON USERS;

CREATE USER global_admin 
IDENTIFIED BY global_admin
QUOTA UNLIMITED ON USERS;

CREATE USER centralizat_admin 
IDENTIFIED BY centralizat_admin 
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

-- afisam rolul creat
SELECT * FROM role_sys_privs
WHERE role = 'ADMINISTRATOR';

-- oferim rolul utilizatorilor
GRANT administrator TO bdd_admin;
GRANT administrator TO global_admin;
GRANT administrator TO centralizat_admin;

-- verificam ca au fost aplicate rolurile
SELECT * FROM DBA_role_privs
WHERE grantee IN ('BDD_ADMIN', 'CENTRALIZAT_ADMIN', 'GLOBAL_ADMIN')
ORDER BY 1;


-- Userii bdd_admin si global_admin trebuie sa primeasca acces la tabelele din schema utilizatorului centralizat_admin
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

-- Userul global_admin trebuie sa primeasca toate tipurile de acces la tabelele din schema utilizatorului bdd_admin
CREATE OR REPLACE PROCEDURE grant_all(
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
        v_cmd := 'GRANT ALL ON '||r.owner||'.'||r.table_name||' TO ' || p_grantee;
        EXECUTE IMMEDIATE v_cmd;
    END LOOP;
    
    FOR r IN (
        SELECT sequence_owner, sequence_name
        FROM all_sequences
        where sequence_owner = UPPER(p_username)
    ) LOOP
        v_cmd := 'GRANT ALL ON '||r.sequence_owner||'.'||r.sequence_name||' TO ' || p_grantee;
        EXECUTE IMMEDIATE v_cmd;
    END LOOP;
END;
/


BEGIN
    grant_select('centralizat_admin','bdd_admin');
    grant_select('centralizat_admin', 'global_admin');
END;
/

BEGIN
    grant_all('bdd_admin','global_admin'); 
    grant_all('global_admin','bdd_admin'); 
END;
/
