#!/usr/bin/env bash
# Dotfile'ları ~ altına symlink olarak bağlar ve niri oturumuna özel servisleri ayarlar.
# sudo gerektirmez; tekrar tekrar çalıştırmak güvenlidir.
#
#   ./install.sh            bağla / güncelle
#   ./install.sh --backup   aynı adda dosyalar varsa önce onları yedeğe taşı, sonra bağla
#   ./install.sh uninstall  bağlantıları ve servis kayıtlarını kaldır (repo silinmez)

set -euo pipefail

# Gerçek yol (pwd -P): bağlantıların hedefi readlink -m ile bununla karşılaştırılır.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

# ~ altına bağlanacak stow paketleri (repo'daki klasör adları).
PACKAGES=(niri foot waybar fuzzel swaync mako bin autostart systemd swappy)

# Sadece niri oturumunda başlayacak kullanıcı servisleri.
NIRI_SERVICES=(
    niri-polkit.service
    theme-apply.service
    waybar.service
    swaync.service
    mako.service
    swayidle.service
    swaybg.service
    layout-mode.service
    launcher.service
    clipboard-history.service
    device-notify.service
    theme-auto.timer
    night-light-auto.service
    night-light-auto.timer
)

WANTS_DIR="$HOME/.config/systemd/user/niri.service.wants"
THEME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
DISPLAYS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/displays"
SETTINGS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/settings"
LAUNCHER_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/launcher"
BACKUP_ROOT="${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles-backup"

# Bu bilgisayara özel niri ayarları (ekran ölçeği, klavye düzeni, imleç teması).
# Repoda değil: ilk kurulumda şablondan oluşturulur, sonra hiç dokunulmaz.
NIRI_LOCAL="$HOME/.config/niri/local.kdl"
NIRI_LOCAL_TEMPLATE="$DOTFILES/examples/niri-local.kdl"

# Brave (Flatpak) şifre/çerez anahtarını niri'de de KDE'deki gibi KWallet'te arasın.
# Flatpak sandbox'ı ~/dotfiles'ı göremez; bu yüzden symlink değil kopya.
BRAVE_FLAGS_SRC="$DOTFILES/flatpak/brave-flags.conf"
BRAVE_FLAGS_DST="$HOME/.var/app/com.brave.Browser/config/brave-flags.conf"
KWALLET_FILE="$HOME/.local/share/kwalletd/kdewallet.kwl"

install_brave_flags() {
    [[ -d "$HOME/.var/app/com.brave.Browser" ]] || return 0
    # Yalnızca KWallet gerçekten kullanılıyorsa (KDE Plasma). GNOME'da Brave zaten
    # gnome-keyring'i kullanır; bayrak orada kayıtlı şifrelere erişimi bozardı.
    [[ -f "$KWALLET_FILE" ]] || return 0
    if [[ -e "$BRAVE_FLAGS_DST" ]] && ! cmp -s "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST"; then
        echo "WARNING: $BRAVE_FLAGS_DST already exists and differs; left untouched." >&2
        return 0
    fi
    command install -D -m 644 "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST"
}

stow_cmd() {
    # --no-folding: klasörleri değil tek tek dosyaları bağla; programların
    # ~/.config altına yazdığı dosyalar repo'ya karışmasın.
    stow --dir "$DOTFILES" --target "$HOME" --no-folding --ignore='__pycache__' "$@"
}

# Paketlerdeki her dosyanın ~ altındaki karşılığı (repo'ya göre yol, NUL ile ayrılmış).
package_files() {
    local pkg
    for pkg in "${PACKAGES[@]}"; do
        (cd "$DOTFILES/$pkg" && find . -name __pycache__ -prune -o \( -type f -o -type l \) -printf '%P\0')
    done
}

# ~ altında zaten var olan ve bu repoya bağlı olmayan dosyalar (stow bunların üstüne yazmaz).
find_conflicts() {
    local rel dst
    while IFS= read -r -d '' rel; do
        dst="$HOME/$rel"
        [[ -e "$dst" || -L "$dst" ]] || continue
        # Zaten bu repoya çıkıyor (dosya ya da üst klasörü bağlantı): çakışma değil.
        [[ "$(readlink -m -- "$dst")" == "$DOTFILES/"* ]] && continue
        printf '%s\n' "$rel"
    done < <(package_files)
}

backup_conflicts() {
    local dir rel
    dir="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
    for rel in "$@"; do
        mkdir -p "$dir/$(dirname -- "$rel")"
        mv -- "$HOME/$rel" "$dir/$rel"
    done
    echo "Moved $# existing file(s) to $dir"
}

# Repo'dan silinmiş dosyalara giden, eski kurulumlardan kalma kırık bağlantılar.
prune_stale_links() {
    local pkg dir link
    for pkg in "${PACKAGES[@]}"; do
        while IFS= read -r -d '' dir; do
            [[ -d "$HOME/$dir" ]] || continue
            while IFS= read -r -d '' link; do
                [[ "$(readlink -m -- "$link")" == "$DOTFILES/"* ]] && rm -f -- "$link"
            done < <(find "$HOME/$dir" -maxdepth 1 -xtype l -print0)
        done < <(cd "$DOTFILES/$pkg" && find . -mindepth 1 -name __pycache__ -prune -o -type d -printf '%P\0')
    done
}

# Laptop ekranının adı (eDP-1 gibi); bulunamazsa eDP-1 (masaüstünde blok etkisiz kalır).
laptop_panel() {
    local f name
    for f in /sys/class/drm/card*-eDP-*/status /sys/class/drm/card*-LVDS-*/status \
             /sys/class/drm/card*-DSI-*/status; do
        [[ -r "$f" && "$(<"$f")" == connected ]] || continue
        name="${f%/status}"; name="${name##*/}"
        echo "${name#card*-}"
        return 0
    done
    echo "eDP-1"
}

make_niri_local() {
    [[ -e "$NIRI_LOCAL" ]] && return 0
    sed "s/@LAPTOP@/$(laptop_panel)/" "$NIRI_LOCAL_TEMPLATE" > "$NIRI_LOCAL"
    echo "Created $NIRI_LOCAL (this computer's screen scale, keyboard layout, cursor theme)"
}

do_install() {
    local backup=$1 conflicts
    mapfile -t conflicts < <(find_conflicts)
    if (( ${#conflicts[@]} )); then
        if (( backup )); then
            backup_conflicts "${conflicts[@]}"
        else
            echo "These files already exist and are not from this repo:" >&2
            printf '  ~/%s\n' "${conflicts[@]}" >&2
            echo "Nothing was changed. Run '$0 --backup' to move them to $BACKUP_ROOT and install." >&2
            exit 1
        fi
    fi
    prune_stale_links
    stow_cmd --restow "${PACKAGES[@]}"
    make_niri_local
    systemctl --user daemon-reload
    for svc in "${NIRI_SERVICES[@]}"; do
        systemctl --user add-wants niri.service "$svc"
    done
    install_brave_flags
    # Tema dosyalarını üret (kayıtlı seçim yoksa varsayılan: sakura).
    "$HOME/.local/bin/theme" apply
    echo "Linked: ${PACKAGES[*]}"
    echo "niri services: ${NIRI_SERVICES[*]}"
}

do_uninstall() {
    for svc in "${NIRI_SERVICES[@]}"; do
        rm -f "$WANTS_DIR/$svc"
    done
    rmdir --ignore-fail-on-non-empty "$WANTS_DIR" 2>/dev/null || true
    stow_cmd --delete "${PACKAGES[@]}"
    systemctl --user daemon-reload
    # theme komutunun ürettiği dosyalar (yalnızca üretilmiş veriler).
    rm -rf "$THEME_STATE"
    # displays komutunun monitör kayıtları (config.kdl onu isteğe bağlı okur).
    rm -rf "$DISPLAYS_STATE"
    # Settings uygulamasının yazdıkları: touchpad, kilit süresi, gece ışığı sıcaklığı.
    rm -rf "$SETTINGS_STATE" "${XDG_CACHE_HOME:-$HOME/.cache}/settings"
    # Ayarlar → Default apps: yalnızca bizim yazdığımız dosyaysa (ilk satırı bizim başlığımız).
    NIRI_MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/niri-mimeapps.list"
    if head -1 "$NIRI_MIMEAPPS" 2>/dev/null | grep -q "^# niri oturumunun varsayılan uygulamaları"; then
        rm -f "$NIRI_MIMEAPPS"
    fi
    # Arama penceresinin hatırladığı sık kullanılan uygulamalar ve emojiler.
    rm -rf "$LAUNCHER_STATE"
    # Brave flags dosyası yalnızca bizim kopyamızsa silinir.
    if cmp -s "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST" 2>/dev/null; then
        rm -f "$BRAVE_FLAGS_DST"
    fi
    echo "Removed links, generated theme files, saved monitor positions, settings, default apps and launcher history. The repo is still at: $DOTFILES"
    # local.kdl elle düzenlenmiş olabilir; silinmez.
    [[ -e "$NIRI_LOCAL" ]] && echo "Kept $NIRI_LOCAL (your own settings for this computer); delete it by hand if you like."
    return 0
}

case "${1:-install}" in
    install)   do_install 0 ;;
    --backup)  do_install 1 ;;
    uninstall) do_uninstall ;;
    *) echo "Usage: $0 [install|--backup|uninstall]" >&2; exit 1 ;;
esac
