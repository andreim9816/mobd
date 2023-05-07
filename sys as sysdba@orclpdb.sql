-- II.1) Crearea bazelor de date si a utilizatorilor

CREATE USER bdd_admin IDENTIFIED BY bdd_admin;
GRANT CREATE SESSION TO bdd_admin;
GRANT CREATE TABLE TO bdd_admin;
GRANT CREATE SEQUENCE TO bdd_admin;
GRANT CREATE DATABASE LINK TO bdd_admin;
ALTER USER bdd_admin QUOTA UNLIMITED ON USERS;

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


