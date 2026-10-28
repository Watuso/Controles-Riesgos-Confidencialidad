-- =====================================================================
-- 99_limpieza_lab.sql
-- Elimina el laboratorio y deja la base como estaba. Ejecutar como SYS en el PDB.
-- Cierre las sesiones de los usuarios del laboratorio antes de correrlo.
-- =====================================================================
SET ECHO ON SERVEROUTPUT ON
WHENEVER SQLERROR CONTINUE

-- Politicas de auditoria
NOAUDIT POLICY pol_privilegios_criticos;
DROP AUDIT POLICY pol_privilegios_criticos;
NOAUDIT POLICY pol_acceso_empleados;
DROP AUDIT POLICY pol_acceso_empleados;

-- Redaction y VPD
BEGIN DBMS_REDACT.DROP_POLICY('APP_RRHH','EMPLEADOS','RED_EMPLEADOS_PII'); END;
/
BEGIN DBMS_RLS.DROP_POLICY('APP_RRHH','EMPLEADOS','VPD_EMP_DEPTO'); END;
/

-- Usuarios, roles y perfil
DROP USER usr_legacy    CASCADE;
DROP USER usr_dev       CASCADE;
DROP USER usr_analista  CASCADE;
DROP USER usr_auditor   CASCADE;
DROP USER dba_lab       CASCADE;
DROP USER app_rrhh_test CASCADE;
DROP USER app_rrhh      CASCADE;
DROP USER sec_admin     CASCADE;
DROP ROLE rol_rrhh_lectura;
DROP ROLE rol_dev_lectura;
DROP PROFILE prf_app_seguro CASCADE;

-- Tablespace cifrado del ejemplo TDE (si se creo)
DROP TABLESPACE ts_datos_personales INCLUDING CONTENTS AND DATAFILES;

-- Restaurar los valores por defecto de Oracle (vuelve a exponer PUBLIC; solo para el lab)
GRANT EXECUTE ON utl_file    TO PUBLIC;
GRANT EXECUTE ON utl_http    TO PUBLIC;
GRANT EXECUTE ON utl_tcp     TO PUBLIC;
GRANT EXECUTE ON utl_smtp    TO PUBLIC;
GRANT EXECUTE ON utl_inaddr  TO PUBLIC;
GRANT EXECUTE ON httpuritype TO PUBLIC;

PROMPT === Laboratorio eliminado.
