-- =====================================================================
-- 10_hardening.sql  (fases HACER / ACTUAR)
-- Implementa los controles sobre el laboratorio y corrige los hallazgos
-- de la linea base. Ejecutar como SYS en el PDB.
-- Cada bloque indica el control ISO/IEC 27001:2022 que implementa.
--
-- ATENCION: revoca EXECUTE de PUBLIC sobre paquetes UTL_*. Pruebe antes en
-- laboratorio; algunas aplicaciones (p.ej. APEX) pueden depender de ellos.
-- Los bloques de Redaction y VPD capturan el error si su edicion no los ofrece
-- y lo imprimen: documentelo como limitacion en el informe.
-- =====================================================================
SET ECHO ON SERVEROUTPUT ON LINESIZE 200
WHENEVER SQLERROR CONTINUE

-- ---------------------------------------------------------------------
-- A5.17 / A8.5  Perfil de contrasenas
-- Si ORA12C_VERIFY_FUNCTION no existe, ejecute como SYS el script
-- <ORACLE_HOME>/rdbms/admin/utlpwdmg.sql (ruta completa) y vuelva a correr.
-- ---------------------------------------------------------------------
DECLARE
  v_fn NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_fn
  FROM   dba_objects
  WHERE  owner = 'SYS' AND object_name = 'ORA12C_VERIFY_FUNCTION' AND object_type = 'FUNCTION';
  IF v_fn = 0 THEN
    DBMS_OUTPUT.PUT_LINE('AVISO: no existe ORA12C_VERIFY_FUNCTION. Ejecute utlpwdmg.sql.');
  END IF;
  EXECUTE IMMEDIATE
    'CREATE PROFILE prf_app_seguro LIMIT '
    || 'FAILED_LOGIN_ATTEMPTS 5 PASSWORD_LIFE_TIME 90 PASSWORD_REUSE_TIME 365 '
    || 'PASSWORD_REUSE_MAX 10 PASSWORD_LOCK_TIME 1 PASSWORD_GRACE_TIME 7 '
    || 'PASSWORD_VERIFY_FUNCTION '
    || CASE WHEN v_fn > 0 THEN 'ora12c_verify_function' ELSE 'NULL' END;
END;
/
ALTER USER app_rrhh     PROFILE prf_app_seguro;
ALTER USER dba_lab      PROFILE prf_app_seguro;
ALTER USER usr_analista PROFILE prf_app_seguro;
ALTER USER usr_dev      PROFILE prf_app_seguro;
ALTER USER usr_auditor  PROFILE prf_app_seguro;
ALTER USER sec_admin    PROFILE prf_app_seguro;
-- OPS$ORACLE y PDBADMIN las crea la imagen del contenedor: se dejan como excepcion documentada.

-- ---------------------------------------------------------------------
-- A5.16 / A5.18 / A8.2  Cuenta heredada: retirar privilegios y bloquear
-- ---------------------------------------------------------------------
REVOKE SELECT ANY TABLE, UNLIMITED TABLESPACE, CREATE SESSION FROM usr_legacy;
ALTER USER usr_legacy ACCOUNT LOCK PASSWORD EXPIRE;

-- ---------------------------------------------------------------------
-- A5.15  Acceso por rol, sin GRANT directos a usuarios
-- ---------------------------------------------------------------------
CREATE ROLE rol_dev_lectura;
GRANT SELECT ON app_rrhh.empleados TO rol_dev_lectura;
REVOKE SELECT, UPDATE ON app_rrhh.empleados FROM usr_dev;
GRANT rol_dev_lectura TO usr_dev;

-- ---------------------------------------------------------------------
-- A8.12  Prevencion de fuga: PUBLIC sin EXECUTE sobre paquetes de salida
-- (ORA-01927 en un REVOKE significa que ese privilegio ya no estaba concedido)
-- ---------------------------------------------------------------------
REVOKE EXECUTE ON utl_file     FROM PUBLIC;
REVOKE EXECUTE ON utl_http     FROM PUBLIC;
REVOKE EXECUTE ON utl_tcp      FROM PUBLIC;
REVOKE EXECUTE ON utl_smtp     FROM PUBLIC;
REVOKE EXECUTE ON utl_inaddr   FROM PUBLIC;
REVOKE EXECUTE ON httpuritype  FROM PUBLIC;

-- ---------------------------------------------------------------------
-- A5.12  Completar el catalogo de clasificacion (columna TELEFONO)
-- ---------------------------------------------------------------------
INSERT INTO sec_admin.catalogo_clasificacion
VALUES ('APP_RRHH','EMPLEADOS','TELEFONO','CONFIDENCIAL','S','Ley 8968: relacion laboral','Vigencia de la relacion + 5 anios');
COMMIT;

-- ---------------------------------------------------------------------
-- A8.15 / A5.33  Auditoria unificada
-- ---------------------------------------------------------------------
AUDIT POLICY ora_secureconfig;
AUDIT POLICY ora_logon_failures;
AUDIT POLICY ora_account_mgmt;

CREATE AUDIT POLICY pol_privilegios_criticos
  PRIVILEGES SELECT ANY TABLE, CREATE USER, ALTER USER, DROP USER,
             GRANT ANY PRIVILEGE, GRANT ANY ROLE, ALTER SYSTEM
  ACTIONS    GRANT, REVOKE, CREATE ROLE, ALTER ROLE, DROP ROLE,
             CREATE PROFILE, ALTER PROFILE, ALTER DATABASE;
AUDIT POLICY pol_privilegios_criticos;

CREATE AUDIT POLICY pol_acceso_empleados
  ACTIONS SELECT ON app_rrhh.empleados,
          INSERT ON app_rrhh.empleados,
          UPDATE ON app_rrhh.empleados,
          DELETE ON app_rrhh.empleados;
AUDIT POLICY pol_acceso_empleados;
-- Si alguna ACTION es rechazada en su version, consulte:
--   SELECT name FROM auditable_system_actions ORDER BY name;

-- ---------------------------------------------------------------------
-- A8.11  Data Redaction (enmascaramiento dinamico) para todos salvo el duenio
-- ---------------------------------------------------------------------
BEGIN
  DBMS_REDACT.ADD_POLICY(
    object_schema => 'APP_RRHH',
    object_name   => 'EMPLEADOS',
    policy_name   => 'RED_EMPLEADOS_PII',
    column_name   => 'CEDULA',
    function_type => DBMS_REDACT.FULL,
    expression    => 'SYS_CONTEXT(''USERENV'',''SESSION_USER'') <> ''APP_RRHH''');
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'APP_RRHH', object_name => 'EMPLEADOS', policy_name => 'RED_EMPLEADOS_PII',
    action => DBMS_REDACT.ADD_COLUMN, column_name => 'SALARIO', function_type => DBMS_REDACT.FULL);
  DBMS_REDACT.ALTER_POLICY(
    object_schema => 'APP_RRHH', object_name => 'EMPLEADOS', policy_name => 'RED_EMPLEADOS_PII',
    action => DBMS_REDACT.ADD_COLUMN, column_name => 'EMAIL', function_type => DBMS_REDACT.FULL);
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('Redaction no aplicada: '||SQLERRM);
END;
/

-- ---------------------------------------------------------------------
-- A8.3  VPD: cada usuario ve solo las filas del departamento TI
-- (el duenio APP_RRHH no tiene restriccion; SYS siempre queda exento)
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sec_admin.fn_vpd_depto (p_schema IN VARCHAR2, p_object IN VARCHAR2)
RETURN VARCHAR2 AS
BEGIN
  IF SYS_CONTEXT('USERENV','SESSION_USER') = 'APP_RRHH' THEN
    RETURN NULL;
  END IF;
  RETURN 'departamento = ''TI''';
END;
/
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'APP_RRHH',
    object_name     => 'EMPLEADOS',
    policy_name     => 'VPD_EMP_DEPTO',
    function_schema => 'SEC_ADMIN',
    policy_function => 'FN_VPD_DEPTO',
    statement_types => 'SELECT');
EXCEPTION WHEN OTHERS THEN
  DBMS_OUTPUT.PUT_LINE('VPD no aplicada: '||SQLERRM);
END;
/

PROMPT
PROMPT === Hardening aplicado. Revise los mensajes de error y repita 01..09 para la evidencia posterior.
PROMPT === Pendiente (manual): 11_tde_ejemplo.sql, 03b_rman_verificacion.rman y 06b (sqlnet.ora).
