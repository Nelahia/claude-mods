#!/usr/bin/env bash
# Installe (ou met à jour) les mods Claude Code décrits dans README.md.
# macOS, Linux et Windows (Git Bash). Idempotent : relançable autant de fois que voulu.
set -euo pipefail

MIN_VERSION=2.1.287
DEFAULT_SKIN=tokyo-night
# Fichier de préférences du mod skins : le suffixe est sha256("skins@hellosverre-mods"), même sur chaque machine.
SKINS_STORE="$HOME/.claude/plugins/store/skins_hellosverre-mods-8037c34839ba.json"

# Claude natif en priorité : une ancienne copie npm peut passer avant lui dans le PATH.
CLAUDE=claude
for c in "$HOME/.local/bin/claude" "$HOME/.local/bin/claude.exe"; do
  if [ -x "$c" ]; then CLAUDE="$c"; break; fi
done

# "nom|source" (bash 3.2 de macOS : pas de tableaux associatifs)
MARKETPLACES=(
  "claude-kit|johnnyvizz/claude-kit"
  "hellosverre-mods|hellosverre/claude-skins"
  "claude-code-filetree|data-goblin/claude-code-filetree"
  "claude-code-mods|karanb192/claude-code-mods"
)
# "plugin|clé=valeur;clé=valeur" : options userConfig (défauts des auteurs, fixés explicitement)
PLUGINS=(
  "savvy-progress@claude-kit|language=auto"
  "skins@hellosverre-mods|"
  "filetree@claude-code-filetree|activity=reads and writes;glyphs=auto;follow=on;column=date"
  "cache-tax@claude-code-mods|"
)

step() { printf '\n\033[36m== %s\033[0m\n' "$1"; }

# vrai si $1 >= $2 (versions x.y.z)
version_ge() {
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | head -n1)" = "$2" ]
}

step "1/4 Mise à jour de Claude Code"
"$CLAUDE" update
version=$("$CLAUDE" --version | awk '{print $1}')
if ! version_ge "$version" "$MIN_VERSION"; then
  echo "Claude Code $version < $MIN_VERSION : les mods ne chargeront pas." >&2
  exit 1
fi
echo "Claude Code $version OK"

step "2/4 Marketplaces"
known=$("$CLAUDE" plugin marketplace list)
for entry in "${MARKETPLACES[@]}"; do
  name=${entry%%|*}
  source=${entry#*|}
  if printf '%s\n' "$known" | awk -v n="$name" '$NF == n { found = 1 } END { exit !found }'; then
    "$CLAUDE" plugin marketplace update "$name"
  else
    "$CLAUDE" plugin marketplace add "$source"
  fi
done

step "3/4 Plugins"
for entry in "${PLUGINS[@]}"; do
  plugin=${entry%%|*}
  opts=${entry#*|}
  args=()
  if [ -n "$opts" ]; then
    IFS=';' read -r -a kvs <<< "$opts"
    for kv in "${kvs[@]}"; do args+=(--config "$kv"); done
  fi
  "$CLAUDE" plugin install "$plugin" --scope user ${args[@]+"${args[@]}"}
done

step "4/4 Skin par défaut"
# Seulement si aucun skin n'a encore été choisi : un choix fait ensuite avec /skin est respecté.
if [ ! -f "$SKINS_STORE" ] || [ "$(tr -d ' \t\r\n' < "$SKINS_STORE")" = "{}" ]; then
  mkdir -p "$(dirname "$SKINS_STORE")"
  printf '{"prefs":{"skin":"%s"}}\n' "$DEFAULT_SKIN" > "$SKINS_STORE"
  echo "Skin $DEFAULT_SKIN appliqué"
elif ! grep -q '"skin"' "$SKINS_STORE"; then
  tmp="$SKINS_STORE.tmp"
  sed "1s/^{/{\"prefs\":{\"skin\":\"$DEFAULT_SKIN\"},/" "$SKINS_STORE" > "$tmp" && mv "$tmp" "$SKINS_STORE"
  echo "Skin $DEFAULT_SKIN appliqué"
else
  echo "Skin déjà choisi, inchangé"
fi

printf '\n\033[32mTerminé. Redémarre Claude Code (ou /reload-plugins dans une session ouverte).\033[0m\n'
