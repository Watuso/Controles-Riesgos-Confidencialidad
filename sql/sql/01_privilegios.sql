-- =====================================================================
-- 01_privilegios.sql  (fase VERIFICAR)
-- Controles: A5.15, A5.18, A8.2   |  Riesgo: R-CONF-01
-- Pruebas: P-01, P-02, P-03, P-04
-- Ejecutar como SYS en el PDB. Solo lectura.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN grantee       FORMAT A22
COLUMN granted_role  FORMAT A28
COLUMN privilege     FORMAT A34
COLUMN owner         FORMAT A14
COLUMN table_name    FORMAT A24
COLUMN username      FORMAT A22

PROMPT
PROMPT ===== [P-01] Cuentas con el rol DBA  (A8.2)
PROMPT Esperado: solo SYS, SYSTEM y DBAs nominales aprobados (p.ej. DBA_LAB).
SELECT grantee, granted_role, admin_option, default_role
FROM   dba_role_privs
WHERE  granted_role = 'DBA'
ORDER  BY grantee;

PROMPT
PROMPT ===== [P-02] Cuentas SYSDBA / SYSOPER / SYSBACKUP  (A8.2)
PROMPT Esperado: solo SYS y cuentas nominales aprobadas; ninguna cuenta de aplicacion.
SELECT username, sysdba, sysoper, sysbackup, sysdg, syskm
FROM   v$pwfile_users
ORDER  BY username;

PROMPT
PROMPT ===== [P-03a] Privilegios de sistema ANY / ADMIN OPTION en cuentas no Oracle  (A5.18)
PROMPT Esperado tras hardening: solo DBA_LAB con UNLIMITED TABLESPACE (Oracle lo concede
PROMPT de forma implicita con el rol DBA). Linea base: ademas USR_LEGACY con SELECT ANY TABLE.
SELECT p.grantee, p.privilege, p.admin_option
FROM   dba_sys_privs p
JOIN   dba_users u ON u.username = p.grantee
WHERE  u.oracle_maintained = 'N'
AND   (p.privilege LIKE '%ANY%'
       OR p.admin_option = 'YES'
       OR p.privilege IN ('UNLIMITED TABLESPACE','ALTER SYSTEM','ALTER USER',
                          'CREATE USER','DROP USER','BECOME USER'))
ORDER  BY p.grantee, p.privilege;

PROMPT
PROMPT ===== [P-03b] Roles criticos asignados a cuentas no Oracle  (A5.18)
PROMPT Esperado: solo DBAs nominales justificados. DBA incluye SELECT ANY TABLE:
PROMPT mitiguelo con auditoria (pol_privilegios_criticos) y revision periodica.
SELECT r.grantee, r.granted_role, r.admin_option
FROM   dba_role_privs r
JOIN   dba_users u ON u.username = r.grantee
WHERE  u.oracle_maintained = 'N'
AND    r.granted_role IN ('DBA','SELECT_CATALOG_ROLE','EXECUTE_CATALOG_ROLE',
                          'EXP_FULL_DATABASE','IMP_FULL_DATABASE',
                          'DATAPUMP_EXP_FULL_DATABASE','DATAPUMP_IMP_FULL_DATABASE')
ORDER  BY r.grantee, r.granted_role;

PROMPT
PROMPT ===== [P-04] GRANT directos a usuarios sobre tablas de negocio  (A5.15)
PROMPT Esperado tras hardening: 0 filas (el acceso se concede por rol). Linea base: USR_DEV.
SELECT p.grantee, p.owner, p.table_name, p.privilege, p.grantable
FROM   dba_tab_privs p
JOIN   dba_users u ON u.username = p.grantee
WHERE  p.owner = 'APP_RRHH'
ORDER  BY p.grantee, p.table_name, p.privilege;
