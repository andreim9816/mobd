-- II.1) Crearea bazelor de date si a utilizatorilor

CREATE USER bdd_admin IDENTIFIED BY bdd_admin;
GRANT CREATE SESSION TO bdd_admin;
GRANT CREATE TABLE TO bdd_admin;
GRANT CREATE SEQUENCE TO bdd_admin;
GRANT CREATE DATABASE LINK TO bdd_admin;
ALTER USER bdd_admin QUOTA UNLIMITED ON USERS;