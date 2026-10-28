-- =====================================================================
-- 05_auditoria_logs.sql  (fase VERIFICAR)
-- Controles: A8.15, A5.33   |  Riesgo: R-CONF-05
-- Pruebas: P-16, P-17   (P-25 se ejecuta en 09_pruebas_funcionales.sql)
-- Ejecutar como SYS en el PDB. Solo lectura.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN policy_name      FORMAT A32
COLUMN enabled_option   FORMAT A18
COLUMN entity_name      FORMAT A20
COLUMN parameter_name   FORMAT A34
COLUMN parameter_value  FORMAT A20
COLUMN audit_trail      FORMAT A22
COLUMN grantee          FORMAT A22
COLUMN granted_role     FORMAT A20
COLUMN name             FORMAT A24
COLUMN value            FORMAT A80

PROMPT
PROMPT ===== [P-16a] Auditoria unificada habilitada  (A8.15)
PROMPT En XE 21.3 aparece FALSE: la base trabaja en modo MIXTO (la auditoria unificada
PROMPT pura exige relinkear el software). Las politicas de auditoria unificada si funcionan;
PROMPT lo que se verifica es P-16b. Documente el modo mixto como limitacion.
SELECT parameter, value FROM v$option WHERE parameter = 'Unified Auditing';

PROMPT
PROMPT ===== [P-16b] Politicas de auditoria habilitadas  (A8.15)
PROMPT Esperado tras hardening: ORA_SECURECONFIG, ORA_LOGON_FAILURES, ORA_ACCOUNT_MGMT,
PROMPT POL_PRIVILEGIOS_CRITICOS y POL_ACCESO_EMPLEADOS.
PROMPT Linea base: ORA_SECURECONFIG y ORA_LOGON_FAILURES ya vienen habilitadas por defecto;
PROMPT el hallazgo es la falta de politicas sobre privilegios criticos y la tabla de empleados.
SELECT policy_name, enabled_option, entity_name, success, failure
FROM   audit_unified_enabled_policies
ORDER  BY policy_name;

PROMPT
PROMPT ===== [P-17a] Parametros de retencion y purga del audit trail  (A5.33)
PROMPT Esperado: retencion definida y documentada; purga controlada por un rol separado.
SELECT audit_trail, parameter_name, parameter_value
FROM   dba_audit_mgmt_config_params
ORDER  BY audit_trail, parameter_name;

PROMPT
PROMPT ===== [P-17b] Quien administra o lee el audit trail  (A5.33)
PROMPT Esperado: AUDIT_ADMIN solo para el responsable de seguridad; AUDIT_VIEWER para auditores.
SELECT grantee, granted_role
FROM   dba_role_privs
WHERE  granted_role IN ('AUDIT_ADMIN','AUDIT_VIEWER')
ORDER  BY granted_role, grantee;

PROMPT
PROMPT ===== [P-17c] Ubicacion de bitacoras del motor (alert log, trace)  (A5.33)
PROMPT Esperado: directorios con permisos solo para el propietario del software Oracle.
SELECT name, value
FROM   v$diag_info
WHERE  name IN ('Diag Trace','Diag Alert','ADR Home');
