-- =====================================================================
-- 07_eliminacion_parcheo.sql  (fase VERIFICAR)
-- Controles: A8.10, A8.8 (complementario)   |  Riesgos: R-CONF-06, R-CONF-01
-- Pruebas: P-20, P-21
-- Ejecutar como SYS en el PDB.
-- ATENCION: P-20 crea y elimina tablas de prueba y ejecuta PURGE DBA_RECYCLEBIN
-- (vacia la papelera de TODO el PDB). Solo en laboratorio.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
WHENEVER SQLERROR CONTINUE
COLUMN owner          FORMAT A14
COLUMN original_name  FORMAT A28
COLUMN type           FORMAT A12
COLUMN description    FORMAT A60
COLUMN status         FORMAT A12
COLUMN action         FORMAT A10

PROMPT
PROMPT ===== [P-20a] Papelera de reciclaje habilitada  (A8.10)
SELECT name, value FROM v$parameter WHERE name = 'recyclebin';

PROMPT
PROMPT ===== [P-20b] Prueba funcional: DROP sin PURGE deja datos recuperables  (A8.10)
CREATE TABLE app_rrhh.tmp_pii_a AS SELECT * FROM app_rrhh.empleados;
CREATE TABLE app_rrhh.tmp_pii_b AS SELECT * FROM app_rrhh.empleados;
DROP TABLE app_rrhh.tmp_pii_a;
DROP TABLE app_rrhh.tmp_pii_b PURGE;

PROMPT Esperado: aparece TMP_PII_A en la papelera (recuperable) y NO aparece TMP_PII_B.
SELECT owner, original_name, type, droptime
FROM   dba_recyclebin
WHERE  owner = 'APP_RRHH'
ORDER  BY droptime;

PROMPT
PROMPT ===== [P-20c] Purgado definitivo  (A8.10)
PURGE DBA_RECYCLEBIN;

PROMPT Esperado: 0 filas para APP_RRHH.
SELECT owner, original_name, type
FROM   dba_recyclebin
WHERE  owner = 'APP_RRHH';

PROMPT
PROMPT ===== [P-21a] Version y nivel de parche instalado  (A8.8)
PROMPT En XE 21.3 DBA_REGISTRY_SQLPATCH no devolvio filas (sin Release Updates aplicados):
PROMPT registrelo como limitacion y defina el plan de actualizacion (verifique en la
PROMPT documentacion de Oracle como se actualiza XE).
SELECT banner_full FROM v$version;

SELECT patch_id, action, status, description, action_time
FROM   dba_registry_sqlpatch
ORDER  BY action_time DESC
FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT ===== [P-21b] Procedimiento de baja segura de medios (evidencia documental)  (A8.10)
PROMPT Adjunte al informe: acta de baja de discos/respaldos, metodo de borrado (p.ej. destruir
PROMPT la clave TDE de un tablespace cifrado = borrado criptografico) y responsable.
