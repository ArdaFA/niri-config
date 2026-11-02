#!/usr/bin/env bash
# Repo'daki config'leri programları çalıştırmadan doğrular.
# Kullanım: ./check.sh      (sorun yoksa çıkış kodu 0)

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FAILED=0

check() {
    local name=$1; shift
    local out
    if out=$("$@" 2>&1); then
        printf '  ok    %s\n' "$name"
    else
        printf '  HATA  %s\n' "$name"
        printf '%s\n' "$out" | sed 's/\x1b\[[0-9;]*m//g; s/^/        /'
        FAILED=1
    fi
}

# Waybar'ın JSONC config'i: yorumları atıp JSON olarak ayrıştırır.
waybar_json() {
    python3 -I - "$1" <<'EOF'
import json, sys
src = open(sys.argv[1], encoding="utf-8").read()
out, i, in_str = [], 0, False
while i < len(src):
    c = src[i]
    if in_str:
        out.append(c)
        if c == "\\":
            out.append(src[i + 1]); i += 1
        elif c == '"':
            in_str = False
    elif c == '"':
        in_str = True; out.append(c)
    elif src.startswith("//", i):
        while i < len(src) and src[i] != "\n":
            i += 1
        continue
    elif src.startswith("/*", i):
        i = src.index("*/", i) + 2
        continue
    else:
        out.append(c)
    i += 1
json.loads("".join(out))
EOF
}

# GTK3 CSS'i Waybar'ın kullandığı ayrıştırıcıyla yükler (@import dahil).
gtk_css() {
    python3 -I - "$1" <<'EOF'
import sys, gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
errors = []
provider = Gtk.CssProvider()
provider.connect("parsing-error", lambda p, s, e: errors.append(
    f"{s.get_file().get_path() if s.get_file() else '?'}:{s.get_start_line() + 1}: {e.message}"))
try:
    provider.load_from_path(sys.argv[1])
except Exception as e:
    errors.append(str(e))
if errors:
    print("\n".join(errors)); sys.exit(1)
EOF
}

units() {
    systemd-analyze --user verify "$DOTFILES"/systemd/.config/systemd/user/*.service
}

echo "Config kontrolü: $DOTFILES"
check "niri"              niri validate -c "$DOTFILES/niri/.config/niri/config.kdl"
check "foot"              foot --check-config -c "$DOTFILES/foot/.config/foot/foot.ini"
check "waybar config"     waybar_json "$HOME/.config/waybar/config.jsonc"
check "waybar style"      gtk_css "$HOME/.config/waybar/style.css"
check "systemd servisleri" units

exit $FAILED
