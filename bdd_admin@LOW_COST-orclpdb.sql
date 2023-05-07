-- II.2) Crearea relatiiloe si a fragmentelor

CREATE TABLE AERONAVA(
    aeronava_ID varchar2(40),
    manufacturer VARCHAR2(60),
    aircraft_name VARCHAR2(60)
);

CREATE TABLE STAT(
    stat_id VARCHAR2(3),
    state VARCHAR2(30)
);

CREATE TABLE OPERATOR_ZBOR
    (operator_id VARCHAR2(3),
     nume VARCHAR2(50) ,
     low_cost NUMBER(1)
);
     
CREATE TABLE METODA_PLATA
    (metoda_plata_id NUMBER(2),
     denumire VARCHAR2(30)
);

CREATE TABLE CLASA_ZBOR
    (clasa_zbor_id NUMBER(2),
     denumire VARCHAR2(20)
);

CREATE TABLE PLATA
    (plata_id NUMBER(10),
    suma_totala NUMBER(7),
    data_plata DATE,
    metoda_plata_id NUMBER(2)
);   

CREATE TABLE CLIENT
    (client_id NUMBER(8),
     nume VARCHAR2(20) ,
     prenume VARCHAR2(30) ,
     email VARCHAR2(40) ,
     numar_telefon VARCHAR2(30)
);

CREATE TABLE DESTINATIE
    (destinatie_id VARCHAR2(4) ,
     oras VARCHAR2(60) ,
     stat_ID VARCHAR2(5) 
);

CREATE TABLE ZBOR(
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

CREATE TABLE REZERVARE(
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