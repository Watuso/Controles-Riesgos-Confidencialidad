-- =====================================================================
-- 00_setup_lab.sql
-- Preparacion del laboratorio (fase HACER: linea base)
-- Curso: Administracion de Bases de Datos - UNA - II Ciclo 2026
-- Motor: Oracle 19c/21c (probado en diseno para XE). Ejecutar como SYS.
--
-- CONEXION: conectese DIRECTAMENTE al PDB (servicio XEPDB1 en XE,
-- ORCLPDB1 en 19c) como SYS AS SYSDBA. No ejecute en CDB$ROOT.
--
-- ADVERTENCIA: crea cuentas con malas practicas A PROPOSITO (USR_LEGACY,
-- grants directos a USR_DEV, columna sin clasificar) para que las pruebas
-- de la linea base encuentren hallazgos reales. Solo para laboratorio.
-- Las contrasenas de este script son ficticias y de uso unico en el lab.
-- =====================================================================
SET ECHO ON
SET SERVEROUTPUT ON
SET LINESIZE 200
WHENEVER SQLERROR CONTINUE

SELECT SYS_CONTEXT('USERENV','CON_NAME') AS contenedor_actual FROM dual;

-- ---------------------------------------------------------------------
-- 1. Esquema duenio de los datos y tabla con datos personales (ficticios)
-- ---------------------------------------------------------------------
CREATE USER app_rrhh IDENTIFIED BY "Lab#App2026x"
  DEFAULT TABLESPACE users QUOTA 50M ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO app_rrhh;

CREATE TABLE app_rrhh.empleados (
  id_empleado  NUMBER        CONSTRAINT pk_empleados PRIMARY KEY,
  nombre       VARCHAR2(80)  NOT NULL,
  cedula       VARCHAR2(12)  NOT NULL,
  email        VARCHAR2(120),
  telefono     VARCHAR2(20),
  salario      NUMBER(12,2),
  departamento VARCHAR2(40)
);

INSERT INTO app_rrhh.empleados VALUES (1,'Ana Prueba Rojas',   '1-0001-0001','ana.prueba@example.invalid',   '8888-0001', 850000,'TI');
INSERT INTO app_rrhh.empleados VALUES (2,'Luis Ejemplo Mora',  '1-0002-0002','luis.ejemplo@example.invalid', '8888-0002',1200000,'FINANZAS');
INSERT INTO app_rrhh.empleados VALUES (3,'Sofia Demo Vargas',  '1-0003-0003','sofia.demo@example.invalid',   '8888-0003', 950000,'RRHH');
INSERT INTO app_rrhh.empleados VALUES (4,'Carlos Test Solis',  '1-0004-0004','carlos.test@example.invalid',  '8888-0004', 780000,'TI');
INSERT INTO app_rrhh.empleados VALUES (5,'Maria Lab Quesada',  '1-0005-0005','maria.lab@example.invalid',    '8888-0005',1500000,'FINANZAS');
INSERT INTO app_rrhh.empleados VALUES (6,'Jorge Piloto Araya', '1-0006-0006','jorge.piloto@example.invalid', '8888-0006', 900000,'TI');
COMMIT;

-- Vista publica: sin salario ni contacto, cedula enmascarada (A8.11, A8.3)
CREATE OR REPLACE VIEW app_rrhh.v_empleados_pub AS
  SELECT id_empleado, nombre, departamento,
         SUBSTR(cedula,1,1)||'-****-****' AS cedula_mask
  FROM   app_rrhh.empleados;

-- ---------------------------------------------------------------------
-- 2. Roles y usuarios del laboratorio
-- ---------------------------------------------------------------------
CREATE ROLE rol_rrhh_lectura;
GRANT SELECT ON app_rrhh.v_empleados_pub TO rol_rrhh_lectura;

-- DBA nominal (buena practica: cuenta personal, no compartida)
CREATE USER dba_lab IDENTIFIED BY "Lab#Dba2026x";
GRANT CREATE SESSION, DBA TO dba_lab;

-- Analista: acceso minimo mediante rol y vista (buena practica)
CREATE USER usr_analista IDENTIFIED BY "Lab#Ana2026x";
GRANT CREATE SESSION, rol_rrhh_lectura TO usr_analista;

-- Desarrollador: GRANT DIRECTO sobre la tabla base (mala practica a proposito)
CREATE USER usr_dev IDENTIFIED BY "Lab#Dev2026x";
GRANT CREATE SESSION TO usr_dev;
GRANT SELECT, UPDATE ON app_rrhh.empleados TO usr_dev;

-- Cuenta heredada: privilegios ANY y ADMIN OPTION (mala practica a proposito)
CREATE USER usr_legacy IDENTIFIED BY "legacy123";
GRANT CREATE SESSION, SELECT ANY TABLE, UNLIMITED TABLESPACE TO usr_legacy WITH ADMIN OPTION;

-- Auditor interno: solo lectura del audit trail
CREATE USER usr_auditor IDENTIFIED BY "Lab#Aud2026x";
GRANT CREATE SESSION, AUDIT_VIEWER TO usr_auditor;

-- ---------------------------------------------------------------------
-- 3. Catalogo de clasificacion (A5.12) - incompleto a proposito (falta TELEFONO)
-- ---------------------------------------------------------------------
CREATE USER sec_admin NO AUTHENTICATION DEFAULT TABLESPACE users QUOTA 10M ON users;

CREATE TABLE sec_admin.catalogo_clasificacion (
  owner         VARCHAR2(128),
  tabla         VARCHAR2(128),
  columna       VARCHAR2(128),
  nivel         VARCHAR2(20)  CHECK (nivel IN ('PUBLICO','INTERNO','CONFIDENCIAL','SENSIBLE')),
  dato_personal CHAR(1)       CHECK (dato_personal IN ('S','N')),
  base_legal    VARCHAR2(200),
  retencion     VARCHAR2(60),
  CONSTRAINT pk_catalogo PRIMARY KEY (owner, tabla, columna)
);

INSERT INTO sec_admin.catalogo_clasificacion VALUES ('APP_RRHH','EMPLEADOS','CEDULA','CONFIDENCIAL','S','Ley 8968: relacion laboral','Vigencia de la relacion + 5 anios');
INSERT INTO sec_admin.catalogo_clasificacion VALUES ('APP_RRHH','EMPLEADOS','EMAIL','CONFIDENCIAL','S','Ley 8968: relacion laboral','Vigencia de la relacion + 5 anios');
INSERT INTO sec_admin.catalogo_clasificacion VALUES ('APP_RRHH','EMPLEADOS','SALARIO','SENSIBLE','S','Ley 8968: condicion socioeconomica (dato sensible)','Vigencia de la relacion + 5 anios');
COMMIT;

PROMPT
PROMPT === Laboratorio listo. Linea base con hallazgos intencionales:
PROMPT   - USR_LEGACY: SELECT ANY TABLE, UNLIMITED TABLESPACE, ADMIN OPTION
PROMPT   - USR_DEV: GRANT directo sobre APP_RRHH.EMPLEADOS
PROMPT   - APP_RRHH.EMPLEADOS.TELEFONO sin clasificar
PROMPT   - PUBLIC con EXECUTE sobre UTL_* (default de Oracle)
PROMPT Siguiente paso: ejecutar 01..09 (linea base), luego 10_hardening.sql y repetir.
