-- =====================================================================
-- 09_pruebas_funcionales.sql  (fase VERIFICAR)
-- Controles: A5.15, A8.3, A8.11, A8.15
-- Pruebas: P-23, P-24, P-25
-- Se conecta como usuarios del laboratorio para observar lo que cada uno
-- puede ver. Ejecutar con SQLcl o SQL*Plus (usa CONNECT y ACCEPT).
-- Ejecutar DESPUES de 00_setup_lab.sql; correr antes y despues de 10_hardening.sql.
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
WHENEVER SQLERROR CONTINUE
COLUMN nombre  FORMAT A22
COLUMN cedula  FORMAT A14
COLUMN email   FORMAT A30

ACCEPT cs CHAR DEFAULT 'localhost:1521/XEPDB1' PROMPT 'Cadena de conexion al PDB [localhost:1521/XEPDB1]: '
ACCEPT sys_pwd CHAR HIDE PROMPT 'Contrasena de SYS: '

PROMPT
PROMPT ===== [P-23] Acceso minimo: USR_ANALISTA solo ve la vista publica  (A5.15, A8.3)
CONNECT usr_analista/"Lab#Ana2026x"@&cs
SHOW USER
PROMPT Intento 1 (esperado ORA-00942: la tabla base no es visible):
SELECT salario FROM app_rrhh.empleados;
PROMPT Intento 2 (esperado: filas con cedula enmascarada; tras VPD solo departamento TI):
SELECT id_empleado, nombre, departamento, cedula_mask FROM app_rrhh.v_empleados_pub ORDER BY id_empleado;

PROMPT
PROMPT ===== [P-24] Enmascaramiento y restriccion de filas para USR_DEV  (A8.11, A8.3)
PROMPT Linea base: 6 filas con cedula, email y salario reales.
PROMPT Tras hardening: solo filas de TI (VPD) con CEDULA, EMAIL y SALARIO redactados.
CONNECT usr_dev/"Lab#Dev2026x"@&cs
SHOW USER
SELECT id_empleado, cedula, email, salario, departamento
FROM   app_rrhh.empleados
ORDER  BY id_empleado;

PROMPT
PROMPT ===== [P-25] El acceso anterior queda registrado en el audit trail  (A8.15)
CONNECT sys/"&sys_pwd"@&cs AS SYSDBA
EXEC DBMS_AUDIT_MGMT.FLUSH_UNIFIED_AUDIT_TRAIL;
PROMPT Esperado tras hardening: al menos una fila SELECT de USR_DEV sobre EMPLEADOS.
PROMPT Linea base: 0 filas (hallazgo: sin politica de auditoria sobre datos sensibles).
COLUMN dbusername FORMAT A12
COLUMN action_name FORMAT A12
COLUMN object_name FORMAT A14
COLUMN unified_audit_policies FORMAT A28
SELECT event_timestamp, dbusername, action_name, object_schema, object_name, unified_audit_policies
FROM   unified_audit_trail
WHERE  dbusername = 'USR_DEV'
AND    object_name = 'EMPLEADOS'
ORDER  BY event_timestamp DESC
FETCH FIRST 5 ROWS ONLY;
