#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"
command -v cloudflared >/dev/null || { echo 'instala cloudflared con brew install cloudflared'; exit 1; }
curl --fail --silent http://127.0.0.1:8731/up >/dev/null || {
    echo 'inicia primero: cd server && php artisan serve --host=127.0.0.1 --port=8731'
    exit 1
}
echo 'copia la dirección https que aparece debajo en los ajustes de senda.'
echo 'el token está en .local-token. el túnel dura mientras este proceso siga abierto.'
exec cloudflared tunnel --url http://127.0.0.1:8731 --no-autoupdate
