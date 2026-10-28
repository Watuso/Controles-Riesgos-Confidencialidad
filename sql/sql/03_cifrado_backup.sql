-- =====================================================================
-- 03_cifrado_backup.sql  (fase VERIFICAR)
-- Controles: A8.24 (complementario, TDE), A8.13   |  Riesgo: R-CONF-03
-- Pruebas: P-09, P-10 (parte SQL)
-- Ejecutar como SYS en el PDB. Solo lectura.
-- Nota: TDE por tablespace/columna figura como disponible en Oracle XE
-- (Licensing Information). Confirme en la guia de su version exacta.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN wrl_type        FORMAT A10
COLUMN wrl_parameter   FORMAT A50
COLUMN status          FORMAT A22
COLUMN wallet_type     FORMAT A14
COLUMN keystore_mode   FORMAT A14
COLUMN tablespace_name FORMAT A26
COLUMN name            FORMAT A34
COLUMN value           FORMAT A50

PROMPT
PROMPT ===== [P-09a] Estado del wallet (keystore) TDE  (A8.24)
PROMPT Esperado: STATUS = OPEN y WALLET_TYPE = PASSWORD o AUTOLOGIN.
SELECT wrl_type, wrl_parameter, status, wallet_type, keystore_mode
FROM   v$encryption_wallet;

PROMPT
PROMPT ===== [P-09b] Tablespaces cifrados  (A8.24)
PROMPT Esperado: el tablespace que contiene datos personales con ENCRYPTED = YES.
SELECT tablespace_name, encrypted
FROM   dba_tablespaces
ORDER  BY tablespace_name;

PROMPT
PROMPT ===== [P-09c] Tablespace de la tabla de datos personales  (A8.24)
PROMPT Esperado tras 11_tde_ejemplo.sql: TS_DATOS_PERSONALES.
SELECT owner, table_name, tablespace_name
FROM   dba_tables
WHERE  owner = 'APP_RRHH';

PROMPT
PROMPT ===== [P-09d] Columnas cifradas (si aplica)  (A8.24)
SELECT owner, table_name, column_name, encryption_alg
FROM   dba_encrypted_columns;

PROMPT
PROMPT ===== [P-09e] Claves maestras registradas  (A8.24)
SELECT * FROM v$encryption_keys;

PROMPT
PROMPT ===== [P-10a] Configuracion RMAN registrada en la base  (A8.13)
PROMPT Esperado: ENCRYPTION FOR DATABASE ... ON  (ver 03b_rman_verificacion.rman).
SELECT name, value
FROM   v$rman_configuration
ORDER  BY name;

PROMPT
PROMPT ===== [P-10b] Respaldos recientes (revise si su version expone la columna ENCRYPTED)  (A8.13)
SELECT * FROM v$backup_set_details
ORDER  BY completion_time DESC
FETCH FIRST 10 ROWS ONLY;
