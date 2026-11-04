#!/usr/bin/env bash
# Dotfile'ları ~ altına symlink olarak bağlar ve niri oturumuna özel servisleri ayarlar.
# sudo gerektirmez; tekrar tekrar çalıştırmak güvenlidir.
#
#   ./install.sh            bağla / güncelle
#   ./install.sh uninstall  bağlantıları ve servis kayıtlarını kaldır (repo silinmez)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
)

WANTS_DIR="$HOME/.config/systemd/user/niri.service.wants"
THEME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/theme"
DISPLAYS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/displays"
SETTINGS_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/settings"
LAUNCHER_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/launcher"

# Brave (Flatpak) şifre/çerez anahtarını niri'de de KDE'deki gibi KWallet'te arasın.
# Flatpak sandbox'ı ~/dotfiles'ı göremez; bu yüzden symlink değil kopya.
BRAVE_FLAGS_SRC="$DOTFILES/flatpak/brave-flags.conf"
BRAVE_FLAGS_DST="$HOME/.var/app/com.brave.Browser/config/brave-flags.conf"

install_brave_flags() {
    [[ -d "$HOME/.var/app/com.brave.Browser" ]] || return 0
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

do_install() {
    stow_cmd --restow "${PACKAGES[@]}"
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
    # Arama penceresinin hatırladığı sık kullanılan uygulamalar ve emojiler.
    rm -rf "$LAUNCHER_STATE"
    # Brave flags dosyası yalnızca bizim kopyamızsa silinir.
    if cmp -s "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST" 2>/dev/null; then
        rm -f "$BRAVE_FLAGS_DST"
    fi
    echo "Removed links, generated theme files, saved monitor positions, settings and launcher history. The repo is still at: $DOTFILES"
}

case "${1:-install}" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    *) echo "Usage: $0 [install|uninstall]" >&2; exit 1 ;;
esac
