-- =====================================================================
-- 11_tde_ejemplo.sql  (fase HACER)
-- Control: A8.24 (complementario: uso de criptografia), apoya A8.13
-- Riesgo: R-CONF-03   |   Prueba: P-09
-- Transparent Data Encryption (TDE): wallet + clave maestra + tablespace cifrado.
--
-- GUIA, NO SCRIPT DE UN SOLO PASO: ejecute cada bloque por separado y adapte
-- rutas y contrasenas. Requiere reiniciar la instancia una vez (WALLET_ROOT).
-- En XE, TDE por tablespace figura como disponible; el cifrado ONLINE de un
-- tablespace existente no. Por eso se crea uno nuevo y se mueve la tabla.
-- Verifique los pasos exactos en el "Advanced Security Guide" de su version.
-- =====================================================================

-- ---------------------------------------------------------------------
-- BLOQUE 1: como SYS en CDB$ROOT (conexion al CDB, no al PDB)
-- ---------------------------------------------------------------------
-- Linux/contenedor: '/opt/oracle/admin/XE/wallet'   Windows: 'C:\app\oracle\admin\XE\wallet'
ALTER SYSTEM SET WALLET_ROOT = '/opt/oracle/admin/XE/wallet' SCOPE = SPFILE;
-- Reinicie la instancia (SHUTDOWN IMMEDIATE / STARTUP) y vuelva a conectarse al CDB.
ALTER SYSTEM SET TDE_CONFIGURATION = 'KEYSTORE_CONFIGURATION=FILE' SCOPE = BOTH;

ADMINISTER KEY MANAGEMENT CREATE KEYSTORE IDENTIFIED BY "ClaveWallet#2026";
ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "ClaveWallet#2026" CONTAINER = ALL;
ADMINISTER KEY MANAGEMENT SET KEY IDENTIFIED BY "ClaveWallet#2026" WITH BACKUP CONTAINER = ALL;

-- Opcional: apertura automatica del wallet al iniciar (reduce control; documente la decision)
-- ADMINISTER KEY MANAGEMENT CREATE AUTO_LOGIN KEYSTORE FROM KEYSTORE '<ruta_wallet>/tde'
--   IDENTIFIED BY "ClaveWallet#2026";

-- Evidencia (P-09a). Esperado: STATUS = OPEN
SELECT wrl_type, wrl_parameter, status, wallet_type, keystore_mode FROM v$encryption_wallet;

-- ---------------------------------------------------------------------
-- BLOQUE 2: como SYS en el PDB (XEPDB1 / ORCLPDB1)
-- Si el PDB no muestra STATUS = OPEN, abra el keystore tambien aqui:
-- ADMINISTER KEY MANAGEMENT SET KEYSTORE OPEN IDENTIFIED BY "ClaveWallet#2026";
-- ---------------------------------------------------------------------
-- Con OMF (db_create_file_dest definido) no hace falta indicar archivo.
-- Sin OMF agregue:  DATAFILE 'C:\...\ts_datos_personales01.dbf'
CREATE TABLESPACE ts_datos_personales
  DATAFILE SIZE 50M AUTOEXTEND ON NEXT 10M MAXSIZE 500M
  ENCRYPTION USING 'AES256'
  DEFAULT STORAGE (ENCRYPT);

ALTER USER app_rrhh QUOTA 50M ON ts_datos_personales;
ALTER TABLE app_rrhh.empleados MOVE TABLESPACE ts_datos_personales;
ALTER INDEX app_rrhh.pk_empleados REBUILD TABLESPACE ts_datos_personales;

-- Evidencia (P-09b, P-09c). Esperado: ENCRYPTED = YES y la tabla en TS_DATOS_PERSONALES
SELECT tablespace_name, encrypted FROM dba_tablespaces WHERE tablespace_name = 'TS_DATOS_PERSONALES';
SELECT owner, table_name, tablespace_name FROM dba_tables WHERE owner = 'APP_RRHH';

-- ---------------------------------------------------------------------
-- CUSTODIA DE LA CLAVE (A8.24 / A8.13)
-- 1. Copie el archivo ewallet.p12 a un medio distinto del de los respaldos de datos.
-- 2. Guarde la contrasena del wallet en un gestor de secretos, no en scripts.
-- 3. Documente la rotacion de la clave maestra (ADMINISTER KEY MANAGEMENT SET KEY ...).
-- Sin el wallet, los datafiles y los respaldos cifrados no se pueden leer: ese es el control.
--
-- LIMITE DE TDE: protege datos en reposo. Un usuario autorizado que ejecuta SELECT
-- ve los datos descifrados. Por eso se combina con A8.2, A8.3, A8.11 y A8.15.
-- ---------------------------------------------------------------------
