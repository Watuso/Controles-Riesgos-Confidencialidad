-- =====================================================================
-- 02_autenticacion.sql  (fase VERIFICAR)
-- Controles: A5.16, A5.17, A8.5   |  Riesgo: R-CONF-02
-- Pruebas: P-05, P-06, P-07, P-08
-- Ejecutar como SYS en el PDB. Solo lectura.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN username        FORMAT A22
COLUMN profile         FORMAT A22
COLUMN resource_name   FORMAT A28
COLUMN limit           FORMAT A28
COLUMN name            FORMAT A34
COLUMN value           FORMAT A40
COLUMN account_status  FORMAT A20

PROMPT
PROMPT ===== [P-05] Cuentas ABIERTAS con contrasena por defecto  (A5.17)
PROMPT Esperado: 0 filas. Las cuentas bloqueadas con clave por defecto son aceptables.
SELECT d.username, d.account_status
FROM   dba_users_with_defpwd p
JOIN   dba_users d ON d.username = p.username
WHERE  d.account_status = 'OPEN'
ORDER  BY d.username;

PROMPT
PROMPT ===== [P-06a] Limites de los perfiles de contrasena  (A8.5, A5.17)
PROMPT Esperado en perfiles de negocio: FAILED_LOGIN_ATTEMPTS <= 5, PASSWORD_LIFE_TIME <= 90,
PROMPT PASSWORD_VERIFY_FUNCTION distinto de NULL.
SELECT profile, resource_name, limit
FROM   dba_profiles
WHERE  resource_name IN ('FAILED_LOGIN_ATTEMPTS','PASSWORD_LIFE_TIME','PASSWORD_REUSE_TIME',
                         'PASSWORD_REUSE_MAX','PASSWORD_LOCK_TIME','PASSWORD_GRACE_TIME',
                         'PASSWORD_VERIFY_FUNCTION')
ORDER  BY profile, resource_name;

PROMPT
PROMPT ===== [P-06b] Perfil asignado a cada cuenta no Oracle  (A8.5)
PROMPT Esperado tras hardening: ninguna cuenta de negocio en el perfil DEFAULT.
PROMPT Excepciones a documentar: OPS$ORACLE y PDBADMIN (cuentas creadas por la imagen del contenedor).
SELECT username, profile, account_status, authentication_type
FROM   dba_users
WHERE  oracle_maintained = 'N'
ORDER  BY username;

PROMPT
PROMPT ===== [P-07] Cuentas abiertas inactivas (>90 dias) o nunca usadas  (A5.16)
PROMPT Esperado: 0 filas o cada fila con justificacion y dueno documentados.
PROMPT Nota: LAST_LOGIN queda vacio hasta el primer ingreso, asi que en el laboratorio
PROMPT aparecen varias cuentas. Documente cada una como hallazgo o excepcion.
SELECT username, account_status, created, last_login, expiry_date
FROM   dba_users
WHERE  oracle_maintained = 'N'
AND    account_status = 'OPEN'
AND   (last_login IS NULL OR last_login < SYSTIMESTAMP - INTERVAL '90' DAY)
ORDER  BY username;

PROMPT
PROMPT ===== [P-08a] Parametros de seguridad de autenticacion  (A8.5)
PROMPT Esperado: remote_login_passwordfile=EXCLUSIVE (o7_dictionary_accessibility no aparecio
PROMPT en V$PARAMETER en la prueba con XE 21.3),
PROMPT sec_max_failed_login_attempts <= 5, sec_return_server_release_banner=FALSE.
SELECT name, value
FROM   v$parameter
WHERE  name IN ('remote_login_passwordfile','o7_dictionary_accessibility',
                'sec_max_failed_login_attempts','sec_return_server_release_banner',
                'sec_protocol_error_further_action','sec_case_sensitive_logon')
ORDER  BY name;

PROMPT
PROMPT ===== [P-08b] Cuentas con verificadores de contrasena obsoletos  (A8.5)
PROMPT Esperado: ninguna fila con 10G en PASSWORD_VERSIONS.
SELECT username, password_versions
FROM   dba_users
WHERE  oracle_maintained = 'N'
AND    password_versions LIKE '%10G%';
