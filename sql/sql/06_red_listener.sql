-- =====================================================================
-- 06_red_listener.sql  (fase VERIFICAR)
-- Control: A8.20   |  Riesgo: R-CONF-03   |  Prueba: P-18
-- (la revision de sqlnet.ora / listener.ora esta en 06b_revision_red.sh, P-19)
-- Ejecutar como SYS en el PDB. Solo lectura.
-- Cifrado nativo de SQL*Net: se configura en sqlnet.ora (ver 06b).
-- =====================================================================
SET LINESIZE 220 PAGESIZE 100 FEEDBACK ON VERIFY OFF TRIMSPOOL ON
COLUMN username FORMAT A20
COLUMN machine  FORMAT A30
COLUMN program  FORMAT A32
COLUMN red      FORMAT A12

PROMPT
PROMPT ===== [P-18] Sesiones de usuario con y sin cifrado de red  (A8.20)
PROMPT Esperado tras activar SQLNET.ENCRYPTION_SERVER=REQUIRED: todas las sesiones remotas = CIFRADO.
SELECT s.sid, s.username, s.machine, s.program,
       CASE WHEN EXISTS (SELECT 1
                         FROM   v$session_connect_info c
                         WHERE  c.sid     = s.sid
                         AND    c.serial# = s.serial#
                         AND    c.network_service_banner LIKE '%Encryption service adapter%')
            THEN 'CIFRADO' ELSE 'SIN CIFRAR' END AS red
FROM   v$session s
WHERE  s.type = 'USER'
AND    s.username IS NOT NULL
ORDER  BY s.username, s.sid;

PROMPT
PROMPT ===== [P-18b] Adaptadores de cifrado y checksum activos por sesion  (A8.20)
PROMPT Linea base: 0 filas. Los banners "Encryption service for Linux" solo indican que el
PROMPT servicio esta disponible. Con cifrado activo aparecen lineas "... service adapter ...".
SELECT sid, network_service_banner
FROM   v$session_connect_info
WHERE  network_service_banner LIKE '%adapter%'
FETCH FIRST 10 ROWS ONLY;
