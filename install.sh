#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MC_VERSION="v2.1.0"
NODE_VERSION="22.23.1"
PNPM_VERSION="10.29.3"

case "$(uname -s)" in
  Darwin) NODE_OS="darwin" ;;
  *) echo "Este instalador suporta atualmente apenas macOS." >&2; exit 1 ;;
esac
case "$(uname -m)" in
  arm64) NODE_ARCH="arm64" ;;
  x86_64) NODE_ARCH="x64" ;;
  *) echo "Arquitetura de CPU não suportada." >&2; exit 1 ;;
esac

echo "ContinuityPanel — a instalar em $ROOT"
mkdir -p "$ROOT/runtime" "$ROOT/bin" "$ROOT/config" "$ROOT/home/.codex/skills" \
  "$ROOT/home/.codex/agents" "$ROOT/home/.hermes" "$ROOT/projects" "$ROOT/tools"

if [[ ! -x "$ROOT/runtime/node/bin/node" ]]; then
  ARCHIVE="node-v$NODE_VERSION-$NODE_OS-$NODE_ARCH.tar.gz"
  curl -fsSL "https://nodejs.org/dist/v$NODE_VERSION/$ARCHIVE" -o "$ROOT/runtime/$ARCHIVE"
  tar -xzf "$ROOT/runtime/$ARCHIVE" -C "$ROOT/runtime"
  mv "$ROOT/runtime/${ARCHIVE%.tar.gz}" "$ROOT/runtime/node"
  rm "$ROOT/runtime/$ARCHIVE"
fi

export PATH="$ROOT/runtime/node/bin:$PATH"
export HOME="$ROOT/home"

npm install --global --prefix "$ROOT/runtime/node" "pnpm@$PNPM_VERSION"

if [[ ! -d "$ROOT/mission-control/.git" ]]; then
  git clone https://github.com/builderz-labs/mission-control.git "$ROOT/mission-control"
fi
git -C "$ROOT/mission-control" fetch --tags
git -C "$ROOT/mission-control" checkout "$MC_VERSION"

MC_PATCHES=(
  "$ROOT/patches/mission-control-local-runtimes.patch"
  "$ROOT/patches/mission-control-local-runtime-status.patch"
  "$ROOT/patches/mission-control-onboarding-once.patch"
)
for MC_PATCH in "${MC_PATCHES[@]}"; do
  if git -C "$ROOT/mission-control" apply --reverse --check "$MC_PATCH" >/dev/null 2>&1; then
    echo "ContinuityPanel integration $(basename "$MC_PATCH") already applied."
  elif git -C "$ROOT/mission-control" apply --check "$MC_PATCH"; then
    git -C "$ROOT/mission-control" apply "$MC_PATCH"
  else
    echo "The ContinuityPanel integration $(basename "$MC_PATCH") is incompatible with $MC_VERSION." >&2
    exit 1
  fi
done

MC_ENV="$ROOT/mission-control/.env"
if [[ ! -f "$MC_ENV" ]]; then
  cp "$ROOT/mission-control/.env.example" "$MC_ENV"
  chmod 600 "$MC_ENV"
fi

set_env() {
  local key="$1" value="$2"
  local escaped_value
  escaped_value="$(printf '%s' "$value" | sed 's/[&|\\]/\\&/g; s/"/\\"/g')"
  if grep -q "^${key}=" "$MC_ENV"; then
    sed -i '' "s|^${key}=.*|${key}=\"${escaped_value}\"|" "$MC_ENV"
  else
    printf '%s="%s"\n' "$key" "$value" >> "$MC_ENV"
  fi
}
set_env NEXT_PUBLIC_GATEWAY_OPTIONAL true
set_env MC_WORKSPACE_ROOT "$ROOT/projects"
set_env MISSION_CONTROL_DATA_DIR "$ROOT/mission-control/.data"
set_env MC_SKILLS_USER_CODEX_DIR "$ROOT/home/.codex/skills"

cd "$ROOT/mission-control"
pnpm install --frozen-lockfile
pnpm rebuild better-sqlite3 node-pty
pnpm build

chmod +x "$ROOT/install.sh" "$ROOT/Install ContinuityPanel.command" "$ROOT/bin/"*
"$ROOT/bin/install-service"

echo "Instalação base do ContinuityPanel concluída."
echo "Adicione agentes através da app ou com: $ROOT/bin/add-agent <agent>"
echo "Mission Control: http://127.0.0.1:3000"
