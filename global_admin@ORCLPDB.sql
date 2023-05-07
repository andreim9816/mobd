--II.2) Crearea relatiilor si a fragmentelor

CREATE TABLE CLIENT(
    client_id NUMBER(8),
    client_premium NUMBER(1),
    data_inregistrare DATE
);

CREATE DATABASE LINK non_lowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb_2';

select * from tab@non_lowcost;
