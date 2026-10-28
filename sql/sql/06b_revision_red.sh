#!/bin/bash
# =====================================================================
# 06b_revision_red.sh  (fase VERIFICAR)
# Control: A8.20   |  Riesgo: R-CONF-03   |  Prueba: P-19
# Ejecutar como el usuario propietario del software Oracle (oracle).
# Solo lectura. Equivalente PowerShell para Windows al final del archivo.
# =====================================================================
TNS_ADMIN="${TNS_ADMIN:-$ORACLE_HOME/network/admin}"

echo "== [P-19a] sqlnet.ora: parametros de seguridad =="
echo "Esperado: SQLNET.ENCRYPTION_SERVER=REQUIRED, ENCRYPTION_TYPES_SERVER con AES256,"
echo "          CRYPTO_CHECKSUM_SERVER=REQUIRED, ALLOWED_LOGON_VERSION_SERVER >= 12,"
echo "          TCP.VALIDNODE_CHECKING=YES y TCP.INVITED_NODES con hosts autorizados."
grep -Ei 'ENCRYPTION|CRYPTO_CHECKSUM|ALLOWED_LOGON_VERSION|VALIDNODE|INVITED_NODES|EXCLUDED_NODES' "$TNS_ADMIN/sqlnet.ora" \
  || echo "HALLAZGO: no hay parametros de seguridad definidos en sqlnet.ora"

echo
echo "== [P-19b] listener.ora: direcciones en las que escucha =="
echo "Esperado: escucha solo en la interfaz necesaria; sin HOST=0.0.0.0 si no es indispensable."
grep -Ei 'HOST|PORT|PROTOCOL' "$TNS_ADMIN/listener.ora" || echo "listener.ora sin direcciones explicitas"

echo
echo "== [P-19c] Estado del listener =="
echo "Esperado: 'Security: ON: Local OS Authentication' y servicios solo los previstos."
lsnrctl status

echo
echo "== [P-19d] Permisos de los archivos de configuracion y bitacoras =="
echo "Esperado: escritura solo para el propietario; sin permisos para 'otros'."
ls -l "$TNS_ADMIN/sqlnet.ora" "$TNS_ADMIN/listener.ora" 2>/dev/null

# ---------------------------------------------------------------------
# PowerShell (Windows, Oracle XE):
#   $tns = "$env:ORACLE_HOME\network\admin"
#   Select-String -Path "$tns\sqlnet.ora" -Pattern 'ENCRYPTION|CRYPTO_CHECKSUM|ALLOWED_LOGON_VERSION|VALIDNODE|INVITED_NODES'
#   Select-String -Path "$tns\listener.ora" -Pattern 'HOST|PORT|PROTOCOL'
#   lsnrctl status
#   icacls "$tns\sqlnet.ora"
# ---------------------------------------------------------------------
