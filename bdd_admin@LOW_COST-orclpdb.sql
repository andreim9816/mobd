-- II.2) Crearea relatiiloe si a fragmentelor

drop table rezervare_lowcost;
drop table plata_lowcost;
drop table aeronava_lowcost;
drop table stat_lowcost;
drop table zbor_lowcost;
drop table operator_zbor_lowcost;
drop table metoda_plata_lowcost;
drop table clasa_zbor_lowcost;
drop table client_nongdpr_lowcost;
drop table destinatie_lowcost;

CREATE TABLE AERONAVA_LOWCOST(
    aeronava_ID varchar2(40),
    producator VARCHAR2(60),
    nume VARCHAR2(60)
);

CREATE TABLE STAT_LOWCOST(
    stat_id VARCHAR2(3),
    state VARCHAR2(30)
);

CREATE TABLE OPERATOR_ZBOR_LOWCOST
    (operator_id VARCHAR2(3),
     nume VARCHAR2(50) ,
     tip VARCHAR2(15)
);
     
CREATE TABLE METODA_PLATA_LOWCOST
    (metoda_plata_id NUMBER(2),
     denumire VARCHAR2(30)
);

CREATE TABLE CLASA_ZBOR_LOWCOST
    (clasa_zbor_id NUMBER(2),
     denumire VARCHAR2(20)
);

CREATE TABLE PLATA_LOWCOST
    (plata_id NUMBER(10),
    suma_totala NUMBER(7),
    data_plata DATE,
    metoda_plata_id NUMBER(2)
);   

CREATE TABLE CLIENT_NONGDPR_LOWCOST (client_id NUMBER(8),
     premium NUMBER,
     data_inregistrare DATE
);

CREATE TABLE DESTINATIE_LOWCOST
    (destinatie_id VARCHAR2(4) ,
     oras VARCHAR2(60) ,
     stat_ID VARCHAR2(5) 
);

CREATE TABLE ZBOR_LOWCOST(
     zbor_id NUMBER(8) ,
     operator_id VARCHAR2(20),
     aeronava_id VARCHAR2(20),
     durata NUMBER(4) ,
     distanta NUMBER(4) ,
     total_locuri NUMBER(4) , 
     anulat NUMBER(1),
     data_plecare TIMESTAMP ,
     data_sosire TIMESTAMP ,
     locatie_plecare_id VARCHAR2(4),
     locatie_sosire_id VARCHAR2(4)
);

CREATE TABLE REZERVARE_LOWCOST(
     rezervare_id  NUMBER(8) ,
     nr_pasageri NUMBER(2),
     nr_pasageri_femei NUMBER(2),
     nr_pasageri_barbati NUMBER(2),
     data_rezervare TIMESTAMP,
     client_id NUMBER(8),
     zbor_id NUMBER(8),
     clasa_zbor_id NUMBER(2),
     plata_id NUMBER(10)
);

CREATE DATABASE LINK non_lowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb_2';

select * from tab@non_lowcost;

-- II.3) Popularea cu date a bazelor de date

SELECT * FROM centralizat_admin.stat;