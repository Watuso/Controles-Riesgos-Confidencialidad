-- =====================================================================
-- 08_clon_dev_test.sql  (fase HACER + VERIFICAR)
-- Controles: A8.11, A8.33 (complementario)   |  Riesgo: R-CONF-04
-- Prueba: P-22
-- Crea un clon DEV/TEST de APP_RRHH, mide la exposicion ANTES de enmascarar,
-- aplica enmascaramiento determinista y mide DESPUES.
-- (Oracle Data Masking and Subsetting Pack no esta en XE: se usa SQL manual.)
-- Ejecutar como SYS en el PDB.
-- =====================================================================
SET LINESIZE 200 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
WHENEVER SQLERROR CONTINUE

CREATE USER app_rrhh_test IDENTIFIED BY "Lab#Test2026x"
  DEFAULT TABLESPACE users QUOTA 20M ON users;
GRANT CREATE SESSION, CREATE TABLE TO app_rrhh_test;

DROP TABLE app_rrhh_test.empleados PURGE;
CREATE TABLE app_rrhh_test.empleados AS SELECT * FROM app_rrhh.empleados;

PROMPT
PROMPT ===== [P-22a] ANTES de enmascarar: filas del clon que coinciden con datos reales  (A8.11)
PROMPT Esperado en linea base: > 0 (hallazgo).
SELECT COUNT(*) AS filas_con_datos_reales
FROM   app_rrhh_test.empleados t
WHERE  EXISTS (SELECT 1 FROM app_rrhh.empleados p
               WHERE  p.cedula = t.cedula OR p.email = t.email OR p.nombre = t.nombre);

-- Enmascaramiento determinista: mismo valor de entrada, mismo valor enmascarado,
-- lo que conserva la integridad referencial entre tablas del clon.
UPDATE app_rrhh_test.empleados
SET    nombre   = 'Empleado '||id_empleado,
       cedula   = '9-'||LPAD(ORA_HASH(cedula, 9999),4,'0')||'-'||LPAD(ORA_HASH(cedula||'x', 9999),4,'0'),
       email    = 'empleado'||id_empleado||'@example.invalid',
       telefono = '0000-'||LPAD(MOD(id_empleado, 10000),4,'0'),
       salario  = ROUND(salario * 0.9, -3);
COMMIT;

PROMPT
PROMPT ===== [P-22b] DESPUES de enmascarar: filas que coinciden con datos reales  (A8.11)
PROMPT Esperado: 0.
SELECT COUNT(*) AS filas_con_datos_reales
FROM   app_rrhh_test.empleados t
WHERE  EXISTS (SELECT 1 FROM app_rrhh.empleados p
               WHERE  p.cedula = t.cedula OR p.email = t.email OR p.nombre = t.nombre);

PROMPT
PROMPT ===== [P-22c] Muestra del clon enmascarado
SELECT id_empleado, nombre, cedula, email, telefono, salario
FROM   app_rrhh_test.empleados
ORDER  BY id_empleado;
