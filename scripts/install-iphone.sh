#!/usr/bin/env bash
# compila senda en release, la firma con tu equipo de apple y la instala en un iphone conectado.
# con una cuenta gratuita el perfil dura 7 dias: vuelve a correr este script para renovarlo.
#
#   TEAM_ID=XXXXXXXXXX ./scripts/install-iphone.sh              instala en el primer iphone disponible
#   TEAM_ID=XXXXXXXXXX ./scripts/install-iphone.sh "15 pro"    busca por nombre o modelo
#   ./scripts/install-iphone.sh --dry-run                       solo muestra que iphone encontro
#   BUNDLE_ID=com.ejemplo.app TEAM_ID=... ./scripts/install-iphone.sh   usa otro identificador ya registrado
#                                                               (util si la cuenta gratuita llego al limite de 10 app ids por 7 dias)
#
# tu team id: xcode > settings > accounts > tu equipo, o `security find-identity -v -p codesigning`.
# una cuenta gratuita solo admite 3 apps instaladas por iphone: si ios lo rechaza, desinstala una con
#   xcrun devicectl device uninstall app --device <id> <bundle id>
# el iphone debe estar desbloqueado, conectado (cable o wifi), con "confiar" aceptado y modo desarrollador activo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/ios"

DRY=0; NAME=""
for a in "$@"; do [ "$a" = "--dry-run" ] && DRY=1 || NAME="$a"; done

tmp=$(mktemp); trap 'rm -f "$tmp"' EXIT
xcrun devicectl list devices --json-output "$tmp" >/dev/null 2>&1
read -r ID UDID DNAME < <(python3 - "$tmp" "$NAME" <<'PY'
import json, sys
data = json.load(open(sys.argv[1]))["result"]["devices"]
want = sys.argv[2].lower()
for d in data:
    hw, dp = d.get("hardwareProperties", {}), d.get("deviceProperties", {})
    cp = d.get("connectionProperties", {})
    if hw.get("deviceType") != "iPhone" or hw.get("reality") == "simulated": continue
    if cp.get("tunnelState") == "unavailable" and cp.get("pairingState") != "paired": continue
    hay = (dp.get("name", "") + " " + hw.get("marketingName", "")).lower()
    if want and want not in hay: continue
    if d.get("connectionProperties", {}).get("tunnelState") == "unavailable": continue
    print(d["identifier"], hw.get("udid", ""), dp.get("name", "").replace(" ", "_"))
    break
PY
) || true
[ -n "${ID:-}" ] || { echo "no encontre un iphone disponible: desbloquealo, conectalo y acepta 'confiar'" >&2; exit 1; }
echo "iphone: ${DNAME//_/ } ($UDID)"
[ "$DRY" = 1 ] && exit 0

: "${TEAM_ID:?define TEAM_ID con tu team id de apple}"
command -v xcodegen >/dev/null || { echo "falta xcodegen: brew install xcodegen" >&2; exit 1; }
xcodegen generate >/dev/null
XB=(xcodebuild -project Senda.xcodeproj -scheme Senda -configuration Release -destination "platform=iOS,id=$UDID")
"${XB[@]}" -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM_ID" ${BUNDLE_ID:+PRODUCT_BUNDLE_IDENTIFIER="$BUNDLE_ID"} \
  -derivedDataPath "$ROOT/build" build | grep -E 'error:|BUILD' || true

# la carpeta de salida la decide el proyecto: se lee de los ajustes de compilacion
OUT=$("${XB[@]}" -derivedDataPath "$ROOT/build" -showBuildSettings 2>/dev/null | awk -F' = ' '/^ +CONFIGURATION_BUILD_DIR = /{print $2; exit}')
APP="$OUT/Senda.app"
[ -d "$APP" ] || { echo "no se genero Senda.app en $OUT: revisa el firmado" >&2; exit 1; }
xcrun devicectl device install app --device "$ID" "$APP"
echo "listo. si ios dice 'desarrollador no confiable': Ajustes > General > VPN y gestion de dispositivos > confiar."
