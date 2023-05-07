--II.2) Crearea relatiilor si a fragmentelor

drop table rezervare_nonlowcost;
drop table plata_nonlowcost;
drop table aeronava_nonlowcost;
drop table stat_nonlowcost;
drop table zbor_nonlowcost;
drop table operator_zbor_nonlowcost;
drop table metoda_plata_nonlowcost;
drop table clasa_zbor_nonlowcost;
drop table client_nongdpr_nonlowcost;
drop table destinatie_nonlowcost;

CREATE TABLE AERONAVA_NONLOWCOST(
    aeronava_ID varchar2(40),
    producator VARCHAR2(60),
    nume VARCHAR2(60)
);

CREATE TABLE STAT_NONLOWCOST(
    stat_id VARCHAR2(3),
    state VARCHAR2(30)
);

CREATE TABLE OPERATOR_ZBOR_NONLOWCOST
    (operator_id VARCHAR2(3),
     nume VARCHAR2(50) ,
     tip VARCHAR2(15)
);
     
CREATE TABLE METODA_PLATA_NONLOWCOST
    (metoda_plata_id NUMBER(2),
     denumire VARCHAR2(30)
);

CREATE TABLE CLASA_ZBOR_NONLOWCOST
    (clasa_zbor_id NUMBER(2),
     denumire VARCHAR2(20)
);

CREATE TABLE PLATA_NONLOWCOST
    (plata_id NUMBER(10),
    suma_totala NUMBER(7),
    data_plata DATE,
    metoda_plata_id NUMBER(2)
);   

CREATE TABLE CLIENT_NONGDPR_NONLOWCOST (client_id NUMBER(8),
     premium NUMBER,
     data_inregistrare DATE
);

CREATE TABLE DESTINATIE_NONLOWCOST
    (destinatie_id VARCHAR2(4) ,
     oras VARCHAR2(60) ,
     stat_ID VARCHAR2(5) 
);

CREATE TABLE ZBOR_NONLOWCOST(
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

CREATE TABLE REZERVARE_NONLOWCOST(
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

CREATE DATABASE LINK nonlowcost
CONNECT TO bdd_admin
IDENTIFIED BY bdd_admin 
USING 'orclpdb';

CREATE DATABASE LINK centralizat
CONNECT TO centralizat_admin
IDENTIFIED BY centralizat_admin
USING 'orclpdb';

-- II.3) Popularea cu date a bazelor de date

select * from tab@nonlowcost;
select * from aeronava@centralizat;
--SELECT * FROM centralizat_admin.aeronava@nonlowcost;
