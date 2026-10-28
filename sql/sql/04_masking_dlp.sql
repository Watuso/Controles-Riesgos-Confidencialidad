-- =====================================================================
-- 04_masking_dlp.sql  (fase VERIFICAR)
-- Controles: A5.12, A8.11, A8.12   |  Riesgos: R-CONF-04, R-CONF-06
-- Pruebas: P-12, P-13, P-14, P-15
-- Ejecutar como SYS en el PDB. Solo lectura.
-- Ley 8968: los datos sensibles (p.ej. condicion socioeconomica) exigen
-- medidas reforzadas; verifique articulos en el texto oficial vigente.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN owner            FORMAT A14
COLUMN table_name       FORMAT A24
COLUMN column_name      FORMAT A22
COLUMN grantee          FORMAT A22
COLUMN privilege        FORMAT A14
COLUMN object_name      FORMAT A22
COLUMN policy_name      FORMAT A24
COLUMN directory_name   FORMAT A24
COLUMN directory_path   FORMAT A60
COLUMN host             FORMAT A30
COLUMN principal        FORMAT A22

PROMPT
PROMPT ===== [P-12] Columnas con datos personales NO incluidas en el catalogo de clasificacion  (A5.12)
PROMPT Esperado tras hardening: 0 filas. Linea base: TELEFONO.
SELECT c.owner, c.table_name, c.column_name
FROM   dba_tab_columns c
WHERE  c.owner = 'APP_RRHH'
AND    REGEXP_LIKE(c.column_name, 'CEDULA|EMAIL|TELEFONO|SALARIO|DIRECCION|NACIMIENTO|TARJETA')
AND    EXISTS (SELECT 1 FROM dba_tables t          -- solo tablas, no vistas
               WHERE  t.owner = c.owner AND t.table_name = c.table_name)
AND    NOT EXISTS (SELECT 1
                   FROM   sec_admin.catalogo_clasificacion k
                   WHERE  k.owner   = c.owner
                   AND    k.tabla   = c.table_name
                   AND    k.columna = c.column_name)
ORDER  BY c.table_name, c.column_name;

PROMPT
PROMPT ===== [P-13a] Politicas de Data Redaction activas  (A8.11)
PROMPT Esperado tras hardening: politica sobre APP_RRHH.EMPLEADOS habilitada.
SELECT object_owner, object_name, policy_name, enable
FROM   redaction_policies;

PROMPT
PROMPT ===== [P-13b] Columnas redactadas  (A8.11)
SELECT object_owner, object_name, column_name, function_type
FROM   redaction_columns;

PROMPT
PROMPT ===== [P-14] PUBLIC con EXECUTE sobre paquetes de salida de datos  (A8.12)
PROMPT Esperado tras hardening: 0 filas. Linea base: UTL_FILE, UTL_HTTP, UTL_TCP, UTL_SMTP, UTL_INADDR, HTTPURITYPE.
SELECT grantee, owner, table_name, privilege
FROM   dba_tab_privs
WHERE  grantee = 'PUBLIC'
AND    table_name IN ('UTL_FILE','UTL_HTTP','UTL_TCP','UTL_SMTP','UTL_INADDR','HTTPURITYPE')
ORDER  BY table_name;

PROMPT
PROMPT ===== [P-15a] Directorios Oracle y quien puede leer/escribir  (A8.12)
PROMPT Esperado: solo directorios necesarios, sin acceso para cuentas de negocio.
SELECT directory_name, directory_path FROM dba_directories ORDER BY directory_name;

SELECT grantee, table_name AS directory_name, privilege
FROM   dba_tab_privs
WHERE  table_name IN (SELECT directory_name FROM dba_directories)
ORDER  BY table_name, grantee;

PROMPT
PROMPT ===== [P-15b] ACL de red (UTL_HTTP/UTL_TCP/UTL_SMTP)  (A8.12)
PROMPT Esperado: sin hosts comodin (*) concedidos a cuentas de negocio.
PROMPT GGSYS y GSMADMIN_INTERNAL son cuentas internas de Oracle: documentelas como justificadas.
SELECT host, lower_port, upper_port, principal, privilege
FROM   dba_host_aces
WHERE  principal NOT IN (SELECT username FROM dba_users WHERE oracle_maintained = 'Y')
ORDER  BY host, principal;

PROMPT
PROMPT ===== [P-15c] Roles de exportacion Data Pump asignados  (A8.12)
PROMPT Esperado: solo DBAs nominales con justificacion.
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  granted_role IN ('DATAPUMP_EXP_FULL_DATABASE','DATAPUMP_IMP_FULL_DATABASE',
                        'EXP_FULL_DATABASE','IMP_FULL_DATABASE')
ORDER  BY granted_role, grantee;
