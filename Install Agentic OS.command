#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
clear
echo "Developer Agent OS — instalador para macOS"
echo
"$ROOT/install.sh"
echo
echo "Instalação concluída. Prime Enter para fechar."
read -r

