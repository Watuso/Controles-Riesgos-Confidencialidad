-- =====================================================================
-- 99_run_all.sql
-- Ciclo PHVA completo con evidencia en archivos .log
-- Ejecutar con SQLcl o SQL*Plus desde la carpeta que contiene los scripts:
--   sql sys@localhost:1521/XEPDB1 as sysdba
--   SQL> @99_run_all.sql
-- Los scripts 11 (TDE), 03b (RMAN) y 06b (red) se ejecutan aparte; ver README.
-- =====================================================================
SET ECHO OFF

PROMPT >>> PLANIFICAR/HACER: preparar laboratorio (solo la primera vez)
@00_setup_lab.sql

PROMPT >>> VERIFICAR: linea base (esperados hallazgos)
SPOOL evidencia_01_linea_base.log
@01_privilegios.sql
@02_autenticacion.sql
@03_cifrado_backup.sql
@04_masking_dlp.sql
@05_auditoria_logs.sql
@06_red_listener.sql
@07_eliminacion_parcheo.sql
@08_clon_dev_test.sql
@09_pruebas_funcionales.sql
SPOOL OFF

PROMPT >>> HACER/ACTUAR: aplicar controles
SPOOL evidencia_02_hardening.log
@10_hardening.sql
SPOOL OFF

PROMPT >>> VERIFICAR: despues del hardening (esperados 0 filas / controles activos)
SPOOL evidencia_03_post_hardening.log
@01_privilegios.sql
@02_autenticacion.sql
@03_cifrado_backup.sql
@04_masking_dlp.sql
@05_auditoria_logs.sql
@06_red_listener.sql
@07_eliminacion_parcheo.sql
@08_clon_dev_test.sql
@09_pruebas_funcionales.sql
SPOOL OFF

PROMPT >>> Comparar evidencia_01 vs evidencia_03 y actualizar la matriz de evaluacion.
