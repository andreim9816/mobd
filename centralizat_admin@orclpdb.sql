CREATE DATABASE LINK non_lowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb_2';

select * from tab@non_lowcost;

drop table rezervare;
drop table plata;
drop table aeronava;
drop table stat;
drop table zbor;
drop table operator_zbor;
drop table metoda_plata;
drop table clasa_zbor;
drop table client;
drop table destinatie;
drop sequence clasa_zbor_seq;
drop sequence metoda_plata_seq;

CREATE TABLE AERONAVA(
    aeronava_ID varchar2(40),
    manufacturer VARCHAR2(60),
    aircraft_Name VARCHAR2(60)
);

CREATE TABLE STAT(
    stat_id VARCHAR2(3),
    state VARCHAR2(30)
);

CREATE TABLE OPERATOR_ZBOR
    (operator_id VARCHAR2(3) PRIMARY KEY,
     nume VARCHAR2(50) NOT NULL,
     low_cost NUMBER(1)
);
     
CREATE TABLE METODA_PLATA
    (metoda_plata_id NUMBER(2) PRIMARY KEY,
     denumire VARCHAR2(30) NOT NULL
);
     
CREATE SEQUENCE metoda_plata_seq 
START WITH 1
INCREMENT BY 1;

INSERT INTO METODA_PLATA VALUES(metoda_plata_seq.NEXTVAL, 'CASH');
INSERT INTO METODA_PLATA VALUES(metoda_plata_seq.NEXTVAL, 'CARD');
INSERT INTO METODA_PLATA VALUES(metoda_plata_seq.NEXTVAL, 'TRANSFER BANCAR');
     
CREATE TABLE CLASA_ZBOR
    (clasa_zbor_id NUMBER(2) PRIMARY KEY,
     denumire VARCHAR2(20) NOT NULL
);
    
CREATE SEQUENCE clasa_zbor_seq 
START WITH 1
INCREMENT BY 1;

INSERT INTO CLASA_ZBOR VALUES(clasa_zbor_seq.NEXTVAL, 'FIRST');
INSERT INTO CLASA_ZBOR VALUES(clasa_zbor_seq.NEXTVAL, 'BUSINESS');
INSERT INTO CLASA_ZBOR VALUES(clasa_zbor_seq.NEXTVAL, 'ECONOMY');

CREATE TABLE PLATA
    (plata_id NUMBER(10) PRIMARY KEY,
    suma_totala NUMBER(7),
    data_plata DATE,
    metoda_plata_id NUMBER(2)
);   

CREATE TABLE CLIENT
    (client_id NUMBER(8) PRIMARY KEY,
     nume VARCHAR2(20) NOT NULL,
     prenume VARCHAR2(30) NOT NULL,
     email VARCHAR2(40) NOT NULL,
     numar_telefon VARCHAR2(30) NOT NULL,
     client_premium NUMBER(1),
     data_inregistrare DATE
);


CREATE TABLE DESTINATIE
    (destinatie_id VARCHAR2(4) PRIMARY KEY,
     oras VARCHAR2(60) NOT NULL,
     stat_ID VARCHAR2(5) NOT NULL
);

CREATE TABLE ZBOR(
     zbor_id NUMBER(8) PRIMARY KEY,
     operator_id VARCHAR2(20) REFERENCES OPERATOR_ZBOR(operator_id) ON DELETE CASCADE,
     aeronava_id VARCHAR2(20),
     durata NUMBER(4) NOT NULL,
     distanta NUMBER(4) NOT NULL,
     total_locuri NUMBER(4) NOT NULL, 
     anulat NUMBER(1) CHECK (anulat IN (0, 1)),
     data_plecare TIMESTAMP NOT NULL,
     data_sosire TIMESTAMP NOT NULL,
     locatie_plecare_id VARCHAR2(4) REFERENCES DESTINATIE(destinatie_id) ON DELETE CASCADE,
     locatie_sosire_id VARCHAR2(4) REFERENCES DESTINATIE(destinatie_id) ON DELETE CASCADE
);


CREATE TABLE REZERVARE(
     rezervare_id  NUMBER(8) PRIMARY KEY,
     nr_pasageri NUMBER(2) NOT NULL CHECK(nr_pasageri > 0),
     nr_pasageri_femei NUMBER(2) NOT NULL CHECK(nr_pasageri_femei >= 0),
     nr_pasageri_barbati NUMBER(2) NOT NULL CHECK(nr_pasageri_barbati >= 0),
     data_rezervare TIMESTAMP NOT NULL,
     client_id NUMBER(8) REFERENCES CLIENT(client_id) ON DELETE CASCADE,
     zbor_id NUMBER(8) REFERENCES ZBOR(zbor_id) ON DELETE CASCADE,
     clasa_zbor_id NUMBER(2) REFERENCES CLASA_ZBOR(clasa_zbor_id) ON DELETE CASCADE,
     plata_id NUMBER(10) REFERENCES plata(plata_id) ON DELETE CASCADE
);

