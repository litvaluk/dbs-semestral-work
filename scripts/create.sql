-------------------------------------------------------------------------------------------------------------
-----------------------------------------PROCEDURY-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------

create or replace procedure SMAZ_VSECHNY_TABULKY AS
-- pokud v logu bude uvedeno, ze nektery objekt nebyl zrusen, protoze na nej jiny jeste existujici objekt stavi, spust proceduru opakovane, dokud se nezrusi vse
begin
  for iRec in
    (select distinct OBJECT_TYPE, OBJECT_NAME,
      'drop '||OBJECT_TYPE||' "'||OBJECT_NAME||'"'||
      case OBJECT_TYPE when 'TABLE' then ' cascade constraints purge' else ' ' end as PRIKAZ
    from USER_OBJECTS where OBJECT_NAME not in ('SMAZ_VSECHNY_TABULKY', 'VYPNI_CIZI_KLICE', 'ZAPNI_CIZI_KLICE', 'VYMAZ_DATA_VSECH_TABULEK')
    ) loop
        begin
          dbms_output.put_line('Prikaz: '||irec.prikaz);
        execute immediate iRec.prikaz;
        exception
          when others then dbms_output.put_line('NEPOVEDLO SE!');
        end;
      end loop;
end;
/

create or replace procedure VYPNI_CIZI_KLICE as
begin
  for cur in (select CONSTRAINT_NAME, TABLE_NAME from USER_CONSTRAINTS where CONSTRAINT_TYPE = 'R' )
  loop
    execute immediate 'alter table '||cur.TABLE_NAME||' modify constraint "'||cur.CONSTRAINT_NAME||'" DISABLE';
  end loop;
end VYPNI_CIZI_KLICE;
/


create or replace procedure ZAPNI_CIZI_KLICE as
begin
  for cur in (select CONSTRAINT_NAME, TABLE_NAME from USER_CONSTRAINTS where CONSTRAINT_TYPE = 'R' )
  loop
    execute immediate 'alter table '||cur.TABLE_NAME||' modify constraint "'||cur.CONSTRAINT_NAME||'" enable validate';
  end loop;
end ZAPNI_CIZI_KLICE;
/

create or replace procedure VYMAZ_DATA_VSECH_TABULEK is
begin
  -- Vymazat data vsech tabulek
  VYPNI_CIZI_KLICE;
  for v_rec in (select distinct TABLE_NAME from USER_TABLES)
  loop
    execute immediate 'truncate table '||v_rec.TABLE_NAME||' drop storage';
  end loop;
  ZAPNI_CIZI_KLICE;

  -- Nastavit vsechny sekvence od 1
  for v_rec in (select distinct SEQUENCE_NAME  from USER_SEQUENCES)
  loop
    execute immediate 'alter sequence '||v_rec.SEQUENCE_NAME||' restart start with 1';
  end loop;
end VYMAZ_DATA_VSECH_TABULEK;
/

-------------------------------------------------------------------------------------------------------------
-----------------------------------------ZRUSIT-STARE-TABULKY------------------------------------------------
-------------------------------------------------------------------------------------------------------------

exec SMAZ_VSECHNY_TABULKY;

-------------------------------------------------------------------------------------------------------------
-----------------------------------------VYTVORIT-TABULKY----------------------------------------------------
-------------------------------------------------------------------------------------------------------------

CREATE TABLE cestujici (
    cestujici_key    INTEGER NOT NULL,
    jmeno            VARCHAR2(30 CHAR) NOT NULL,
    prijmeni         VARCHAR2(30 CHAR) NOT NULL,
    datum_narozeni   DATE,
    planeta_key      INTEGER NOT NULL
);

ALTER TABLE cestujici ADD CONSTRAINT cestujici_pk PRIMARY KEY ( cestujici_key );

CREATE TABLE let_cestujiciho (
    osobni_key      INTEGER NOT NULL,
    cestujici_key   INTEGER NOT NULL
);

ALTER TABLE let_cestujiciho ADD CONSTRAINT relation_1_pk PRIMARY KEY ( osobni_key,
cestujici_key );

CREATE TABLE lod (
    lod_key     INTEGER NOT NULL,
    model_key   INTEGER NOT NULL,
    nazev       VARCHAR2(30 CHAR) NOT NULL,
    barva       VARCHAR2(20 CHAR)
);

ALTER TABLE lod ADD CONSTRAINT lod_pk PRIMARY KEY ( lod_key );

ALTER TABLE lod ADD CONSTRAINT lod_nazev_un UNIQUE ( nazev );

CREATE TABLE mechanik (
    mechanik_key      INTEGER NOT NULL,
    zamestnanec_key   INTEGER NOT NULL,
    zamereni          VARCHAR2(20 CHAR)
);

CREATE UNIQUE INDEX mechanik__idx ON
    mechanik ( zamestnanec_key ASC );

ALTER TABLE mechanik ADD CONSTRAINT mechanik_pk PRIMARY KEY ( zamestnanec_key,
mechanik_key );

CREATE TABLE model (
    model_key   INTEGER NOT NULL,
    nazev       VARCHAR2(30 CHAR) NOT NULL,
    palivo      VARCHAR2(20 CHAR)
);

ALTER TABLE model ADD CONSTRAINT model_pk PRIMARY KEY ( model_key );

ALTER TABLE model ADD CONSTRAINT model_nazev_un UNIQUE ( nazev );

CREATE TABLE nakladni (
    nakladni_key       INTEGER NOT NULL,
    z_stanice_key      INTEGER NOT NULL,
    do_stanice_key     INTEGER NOT NULL,
    zamestnanec_key    INTEGER NOT NULL,
    lod_key            INTEGER NOT NULL,
    kod_letu           VARCHAR2(20 CHAR) NOT NULL,
    pilot_key          INTEGER NOT NULL,
    naklad             VARCHAR2(30) NOT NULL,
    mnozstvi_nakladu   INTEGER NOT NULL
);

ALTER TABLE nakladni ADD CONSTRAINT nakladni_pk PRIMARY KEY ( nakladni_key );

ALTER TABLE nakladni ADD CONSTRAINT nakladni_kod_letu_un UNIQUE ( kod_letu );

CREATE TABLE osobni (
    osobni_key        INTEGER NOT NULL,
    z_stanice_key     INTEGER NOT NULL,
    do_stanice_key    INTEGER NOT NULL,
    zamestnanec_key   INTEGER NOT NULL,
    lod_key           INTEGER NOT NULL,
    kod_letu          VARCHAR2(20 CHAR) NOT NULL,
    pilot_key         INTEGER NOT NULL,
    jidlo             VARCHAR2(30 CHAR)
);

ALTER TABLE osobni ADD CONSTRAINT osobni_pk PRIMARY KEY ( osobni_key );

ALTER TABLE osobni ADD CONSTRAINT osobni_kod_letu_un UNIQUE ( kod_letu );

CREATE TABLE pilot (
    pilot_key         INTEGER NOT NULL,
    zamestnanec_key   INTEGER NOT NULL,
    cislo_prukazu     INTEGER
);

CREATE UNIQUE INDEX pilot__idx ON
    pilot ( zamestnanec_key ASC );

ALTER TABLE pilot ADD CONSTRAINT pilot_pk PRIMARY KEY ( zamestnanec_key,
pilot_key );

ALTER TABLE pilot ADD CONSTRAINT pilot_cislo_prukazu_un UNIQUE ( cislo_prukazu );

CREATE TABLE planeta (
    planeta_key   INTEGER NOT NULL,
    nazev         VARCHAR2(50 CHAR) NOT NULL,
    hmotnost      INTEGER,
    prumer        INTEGER,
    sektor_key    INTEGER NOT NULL
);

ALTER TABLE planeta ADD CONSTRAINT planeta_pk PRIMARY KEY ( planeta_key );

ALTER TABLE planeta ADD CONSTRAINT planeta_nazev_un UNIQUE ( nazev );

CREATE TABLE reditel (
    reditel_key       INTEGER NOT NULL,
    zamestnanec_key   INTEGER NOT NULL
);

CREATE UNIQUE INDEX reditel__idx ON
    reditel ( zamestnanec_key ASC );

ALTER TABLE reditel ADD CONSTRAINT reditel_pk PRIMARY KEY ( zamestnanec_key,
reditel_key );

CREATE TABLE sektor (
    sektor_key   INTEGER NOT NULL,
    nazev        VARCHAR2(50) NOT NULL
);

ALTER TABLE sektor ADD CONSTRAINT sektor_pk PRIMARY KEY ( sektor_key );

ALTER TABLE sektor ADD CONSTRAINT sektor_nazev_un UNIQUE ( nazev );

CREATE TABLE stanice (
    stanice_key   INTEGER NOT NULL,
    planeta_key   INTEGER NOT NULL,
    nazev         VARCHAR2(30) NOT NULL,
    pocet_doku    INTEGER
);

ALTER TABLE stanice ADD CONSTRAINT stanice_pk PRIMARY KEY ( stanice_key );

ALTER TABLE stanice ADD CONSTRAINT stanice_nazev_un UNIQUE ( nazev );

CREATE TABLE starost_o_lod (
    zamestnanec_key   INTEGER NOT NULL,
    mechanik_key      INTEGER NOT NULL,
    lod_key           INTEGER NOT NULL
);

ALTER TABLE starost_o_lod
    ADD CONSTRAINT relation_17_pk PRIMARY KEY ( zamestnanec_key,
    mechanik_key,
    lod_key );

CREATE TABLE zamestnanec (
    zamestnanec_key   INTEGER NOT NULL,
    jmeno             VARCHAR2(30) NOT NULL,
    prijmeni          VARCHAR2(30) NOT NULL,
    datum_narozeni    DATE
);

ALTER TABLE zamestnanec ADD CONSTRAINT zamestnanec_pk PRIMARY KEY ( zamestnanec_key );

ALTER TABLE cestujici
    ADD CONSTRAINT cestujici_planeta_fk FOREIGN KEY ( planeta_key )
        REFERENCES planeta ( planeta_key );

ALTER TABLE lod
    ADD CONSTRAINT lod_model_fk FOREIGN KEY ( model_key )
        REFERENCES model ( model_key );

ALTER TABLE mechanik
    ADD CONSTRAINT mechanik_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE nakladni
    ADD CONSTRAINT nakladni_lod_fk FOREIGN KEY ( lod_key )
        REFERENCES lod ( lod_key );

ALTER TABLE nakladni
    ADD CONSTRAINT nakladni_pilot_fk FOREIGN KEY ( zamestnanec_key,
    pilot_key )
        REFERENCES pilot ( zamestnanec_key,
        pilot_key );

ALTER TABLE nakladni
    ADD CONSTRAINT nakladni_stanice_fk FOREIGN KEY ( z_stanice_key )
        REFERENCES stanice ( stanice_key );

ALTER TABLE nakladni
    ADD CONSTRAINT nakladni_stanice_fkv2 FOREIGN KEY ( do_stanice_key )
        REFERENCES stanice ( stanice_key );

ALTER TABLE osobni
    ADD CONSTRAINT osobni_lod_fk FOREIGN KEY ( lod_key )
        REFERENCES lod ( lod_key );

ALTER TABLE osobni
    ADD CONSTRAINT osobni_pilot_fk FOREIGN KEY ( zamestnanec_key,
    pilot_key )
        REFERENCES pilot ( zamestnanec_key,
        pilot_key );

ALTER TABLE osobni
    ADD CONSTRAINT osobni_stanice_fk FOREIGN KEY ( z_stanice_key )
        REFERENCES stanice ( stanice_key );

ALTER TABLE osobni
    ADD CONSTRAINT osobni_stanice_fkv2 FOREIGN KEY ( do_stanice_key )
        REFERENCES stanice ( stanice_key );

ALTER TABLE pilot
    ADD CONSTRAINT pilot_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE planeta
    ADD CONSTRAINT planeta_sektor_fk FOREIGN KEY ( sektor_key )
        REFERENCES sektor ( sektor_key );

ALTER TABLE reditel
    ADD CONSTRAINT reditel_zamestnanec_fk FOREIGN KEY ( zamestnanec_key )
        REFERENCES zamestnanec ( zamestnanec_key );

ALTER TABLE let_cestujiciho
    ADD CONSTRAINT relation_1_cestujici_fk FOREIGN KEY ( cestujici_key )
        REFERENCES cestujici ( cestujici_key );

ALTER TABLE let_cestujiciho
    ADD CONSTRAINT relation_1_osobni_fk FOREIGN KEY ( osobni_key )
        REFERENCES osobni ( osobni_key );

ALTER TABLE starost_o_lod
    ADD CONSTRAINT relation_17_lod_fk FOREIGN KEY ( lod_key )
        REFERENCES lod ( lod_key );

ALTER TABLE starost_o_lod
    ADD CONSTRAINT relation_17_mechanik_fk FOREIGN KEY ( zamestnanec_key,
    mechanik_key )
        REFERENCES mechanik ( zamestnanec_key,
        mechanik_key );

ALTER TABLE stanice
    ADD CONSTRAINT stanice_planeta_fk FOREIGN KEY ( planeta_key )
        REFERENCES planeta ( planeta_key );

CREATE SEQUENCE cestujici_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE lod_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE mechanik_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE model_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE nakladni_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE osobni_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE pilot_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE planeta_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE reditel_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE sektor_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE stanice_seq START WITH 1 NOCACHE ORDER;
CREATE SEQUENCE zamestnanec_seq START WITH 1 NOCACHE ORDER;