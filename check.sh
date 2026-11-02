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

# mako'nun config kontrol seçeneği yok: izole bir D-Bus'ta, Wayland'a bağlanamayacak
# şekilde başlatılır; config'i okuyup "display" hatasıyla durursa config geçerlidir.
mako_conf() {
    local out
    out=$(env -u DISPLAY -u WAYLAND_SOCKET WAYLAND_DISPLAY=config-check-no-display \
          dbus-run-session -- timeout 5 mako -c "$1" 2>&1)
    if grep -q 'Failed to parse' <<<"$out"; then
        printf '%s\n' "$out"; return 1
    fi
}

# swaylock çalıştırılmaz (gerçekten kilitler!): her satırın geçerli bir seçenek olduğuna bakılır.
swaylock_conf() {
    local opts bad=0 key
    opts=$(swaylock --help 2>&1 | grep -oE -- '--[a-z-]+' | sed 's/^--//' | sort -u)
    while IFS= read -r line; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        key=${line%%=*}
        if ! grep -qx -- "$key" <<<"$opts"; then
            echo "bilinmeyen seçenek: $key"; bad=1
        fi
    done < "$1"
    return $bad
}

scripts() {
    local f rc=0
    for f in "$DOTFILES"/bin/.local/bin/*; do
        case "$(head -1 "$f")" in
            *python*) python3 -I -m py_compile "$f" || rc=1 ;;
            *bash*)   bash -n "$f" || rc=1 ;;
            *)        sh -n "$f" || rc=1 ;;
        esac
    done
    return $rc
}

echo "Config kontrolü: $DOTFILES"
check "niri"              niri validate -c "$DOTFILES/niri/.config/niri/config.kdl"
check "foot"              foot --check-config -c "$DOTFILES/foot/.config/foot/foot.ini"
check "waybar config"     waybar_json "$HOME/.config/waybar/config.jsonc"
check "waybar style"      gtk_css "$HOME/.config/waybar/style.css"
check "fuzzel"            fuzzel --check-config --config "$DOTFILES/fuzzel/.config/fuzzel/fuzzel.ini"
check "mako"              mako_conf "$DOTFILES/mako/.config/mako/config"
check "swaylock"          swaylock_conf "$DOTFILES/swaylock/.config/swaylock/config"
check "scriptler"         scripts
check "systemd servisleri" units

exit $FAILED
