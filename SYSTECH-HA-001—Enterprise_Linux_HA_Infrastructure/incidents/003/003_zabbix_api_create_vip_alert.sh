#!/bin/bash
set -euo pipefail

# ==========================================================================
# Crea un Web Scenario + Trigger en Zabbix para monitorear la VIP de la
# capa de Load Balancing (HAProxy/Keepalived).
# Requiere: curl, jq
# ==========================================================================

ZABBIX_URL="http://10.10.10.90/api_jsonrpc.php"
ZABBIX_USER="Admin"
ZABBIX_PASS="zabbix"

TARGET_HOST="client01"                          # Host contenedor del scenario
VIP_URL="http://10.10.10.30/index.php"           # Endpoint a chequear
SCENARIO_NAME="App_VIP_HTTP_Check"
STEP_NAME="GET index"
TRIGGER_NAME="VIP HTTP check failing - respuesta no-200"
TRIGGER_PRIORITY=3                               # 3 = Average (coherente con P2)

api_call() {
  local body="$1"
  curl -s -X POST "$ZABBIX_URL" \
    -H 'Content-Type: application/json-rpc' \
    -H "Authorization: Bearer ${TOKEN:-}" \
    -d "$body"
}

echo "=========================================================================="
echo "🔐 [1/4] Autenticando..."
TOKEN=$(curl -s -X POST "$ZABBIX_URL" \
  -H 'Content-Type: application/json-rpc' \
  -d "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"user.login\",
    \"params\":{\"username\":\"${ZABBIX_USER}\",\"password\":\"${ZABBIX_PASS}\"},
    \"id\":1
  }" | jq -r '.result')

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "❌ No se pudo autenticar contra $ZABBIX_URL"
  exit 1
fi
echo "✅ Token: ${TOKEN:0:10}..."

echo "🔍 [2/4] Buscando host '$TARGET_HOST'..."
HOST_ID=$(api_call "{
  \"jsonrpc\":\"2.0\",
  \"method\":\"host.get\",
  \"params\":{\"filter\":{\"host\":[\"${TARGET_HOST}\"]}},
  \"id\":2
}" | jq -r '.result[0].hostid')

if [ -z "$HOST_ID" ] || [ "$HOST_ID" == "null" ]; then
  echo "❌ Host '$TARGET_HOST' no encontrado en Zabbix."
  exit 1
fi
echo "✅ Host ID: $HOST_ID"

echo "🚀 [3/4] Creando/verificando Web Scenario '$SCENARIO_NAME'..."
EXISTING_SCENARIO_ID=$(api_call "{
  \"jsonrpc\":\"2.0\",
  \"method\":\"httptest.get\",
  \"params\":{\"hostids\":[\"${HOST_ID}\"],\"filter\":{\"name\":[\"${SCENARIO_NAME}\"]}},
  \"id\":3
}" | jq -r '.result[0].httptestid')

if [ -n "$EXISTING_SCENARIO_ID" ] && [ "$EXISTING_SCENARIO_ID" != "null" ]; then
  echo "   🔄 Web Scenario ya existe (ID: $EXISTING_SCENARIO_ID). Sin cambios."
else
  RESP=$(api_call "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"httptest.create\",
    \"params\":{
      \"name\":\"${SCENARIO_NAME}\",
      \"hostid\":\"${HOST_ID}\",
      \"delay\":\"30s\",
      \"steps\":[
        {
          \"name\":\"${STEP_NAME}\",
          \"url\":\"${VIP_URL}\",
          \"status_codes\":\"200\",
          \"no\":1
        }
      ]
    },
    \"id\":4
  }")
  if echo "$RESP" | jq -e '.result' >/dev/null 2>&1; then
    echo "   ✅ Web Scenario creado."
  else
    echo "   ❌ Error creando Web Scenario:"
    echo "$RESP" | jq .
    exit 1
  fi
fi

echo "🔍 [4/4] Creando/verificando Trigger '$TRIGGER_NAME'..."
EXISTING_TRIGGER_ID=$(api_call "{
  \"jsonrpc\":\"2.0\",
  \"method\":\"trigger.get\",
  \"params\":{\"hostids\":[\"${HOST_ID}\"],\"filter\":{\"description\":[\"${TRIGGER_NAME}\"]}},
  \"id\":5
}" | jq -r '.result[0].triggerid')

if [ -n "$EXISTING_TRIGGER_ID" ] && [ "$EXISTING_TRIGGER_ID" != "null" ]; then
  echo "   🔄 Trigger ya existe (ID: $EXISTING_TRIGGER_ID). Sin cambios."
else
  RESP=$(api_call "{
    \"jsonrpc\":\"2.0\",
    \"method\":\"trigger.create\",
    \"params\":{
      \"description\":\"${TRIGGER_NAME}\",
      \"expression\":\"last(/${TARGET_HOST}/web.test.rspcode[${SCENARIO_NAME},${STEP_NAME}])<>200\",
      \"priority\":${TRIGGER_PRIORITY}
    },
    \"id\":6
  }")
  if echo "$RESP" | jq -e '.result' >/dev/null 2>&1; then
    echo "   ✅ Trigger creado."
  else
    echo "   ❌ Error creando Trigger:"
    echo "$RESP" | jq .
    exit 1
  fi
fi

echo "=========================================================================="
echo "🎉 ¡Alerta configurada!"
echo "   Revisa: http://10.10.10.90/zabbix/ → Monitoring > Latest data (host: ${TARGET_HOST})"
echo "   y Monitoring > Problems para ver el trigger cuando dispare."
echo "=========================================================================="
