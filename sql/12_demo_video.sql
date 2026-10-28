-- =====================================================================
-- 12_demo_video.sql  (solo para grabar la demo del video)
-- Muestra en vivo, sin tipear: minimo privilegio, enmascaramiento, VPD,
-- TDE y auditoria. Debe correrse DESPUES de 10_hardening.sql y 11_tde.
-- Uso (desde PowerShell, un solo comando):
--   docker exec -it -w /tmp/sql oracle-xe sqlplus /nolog @12_demo_video.sql
-- ECHO esta apagado: las claves de CONNECT no se ven en pantalla.
-- =====================================================================
SET ECHO OFF FEEDBACK OFF VERIFY OFF LINESIZE 160 PAGESIZE 30 TRIMSPOOL ON
COLUMN nombre          FORMAT A14
COLUMN cedula          FORMAT A12
COLUMN cedula_mask     FORMAT A12
COLUMN email           FORMAT A22
COLUMN departamento    FORMAT A12
COLUMN grantee         FORMAT A16
COLUMN privilege       FORMAT A12
COLUMN tablespace_name FORMAT A24
COLUMN table_name      FORMAT A14
COLUMN status          FORMAT A10
COLUMN wallet_type     FORMAT A12
COLUMN policy_name     FORMAT A28
COLUMN enabled_option  FORMAT A14

CLEAR SCREEN
PROMPT
PROMPT ===== 1. Desarrollador (USR_DEV): solo filas de TI y datos redactados  [A8.3, A8.11]
CONNECT usr_dev/"Lab#Dev2026x"@//localhost:1521/XEPDB1
PROMPT SQL> SELECT id_empleado, cedula, email, salario, departamento FROM app_rrhh.empleados;
SELECT id_empleado, cedula, email, salario, departamento FROM app_rrhh.empleados;
PAUSE >>> Enter para continuar

PROMPT
PROMPT ===== 2. Analista (USR_ANALISTA): no ve la tabla base, solo la vista  [A5.15]
CONNECT usr_analista/"Lab#Ana2026x"@//localhost:1521/XEPDB1
PROMPT SQL> SELECT salario FROM app_rrhh.empleados;
SELECT salario FROM app_rrhh.empleados;
PROMPT SQL> SELECT id_empleado, nombre, departamento, cedula_mask FROM app_rrhh.v_empleados_pub;
SELECT id_empleado, nombre, departamento, cedula_mask FROM app_rrhh.v_empleados_pub ORDER BY id_empleado;
PAUSE >>> Enter para continuar

PROMPT
PROMPT ===== 3. Quien tiene acceso directo a la tabla (solo por rol)  [A5.15, A5.18]
CONNECT / AS SYSDBA
ALTER SESSION SET CONTAINER = XEPDB1;
PROMPT SQL> SELECT grantee, privilege FROM dba_tab_privs WHERE owner='APP_RRHH' AND table_name='EMPLEADOS';
SELECT grantee, privilege FROM dba_tab_privs WHERE owner='APP_RRHH' AND table_name='EMPLEADOS' ORDER BY 1;
PAUSE >>> Enter para continuar

PROMPT
PROMPT ===== 4. Cifrado en reposo (TDE): wallet abierto y tablespace cifrado  [A8.24]
PROMPT SQL> SELECT status, wallet_type FROM v$encryption_wallet;
SELECT status, wallet_type FROM v$encryption_wallet;
PROMPT SQL> SELECT tablespace_name, encrypted FROM dba_tablespaces WHERE tablespace_name = 'TS_DATOS_PERSONALES';
SELECT tablespace_name, encrypted FROM dba_tablespaces WHERE tablespace_name = 'TS_DATOS_PERSONALES';
PROMPT SQL> SELECT table_name, tablespace_name FROM dba_tables WHERE owner = 'APP_RRHH';
SELECT table_name, tablespace_name FROM dba_tables WHERE owner = 'APP_RRHH';
PAUSE >>> Enter para continuar

PROMPT
PROMPT ===== 5. Politicas de auditoria habilitadas  [A8.15]
PROMPT SQL> SELECT policy_name, enabled_option FROM audit_unified_enabled_policies;
SELECT policy_name, enabled_option FROM audit_unified_enabled_policies ORDER BY policy_name;

PROMPT
PROMPT ===== Fin de la demo
EXIT
