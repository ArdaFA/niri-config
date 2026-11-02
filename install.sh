#!/usr/bin/env bash
# Dotfile'ları ~ altına symlink olarak bağlar ve niri oturumuna özel servisleri ayarlar.
# sudo gerektirmez; tekrar tekrar çalıştırmak güvenlidir.
#
#   ./install.sh            bağla / güncelle
#   ./install.sh uninstall  bağlantıları ve servis kayıtlarını kaldır (repo silinmez)

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ~ altına bağlanacak stow paketleri (repo'daki klasör adları).
PACKAGES=(niri foot waybar fuzzel mako swaylock bin autostart systemd)

# Sadece niri oturumunda başlayacak kullanıcı servisleri.
NIRI_SERVICES=(niri-polkit.service waybar.service mako.service swayidle.service swaybg.service)

WANTS_DIR="$HOME/.config/systemd/user/niri.service.wants"

stow_cmd() {
    # --no-folding: klasörleri değil tek tek dosyaları bağla; programların
    # ~/.config altına yazdığı dosyalar repo'ya karışmasın.
    stow --dir "$DOTFILES" --target "$HOME" --no-folding "$@"
}

install() {
    stow_cmd --restow "${PACKAGES[@]}"
    systemctl --user daemon-reload
    for svc in "${NIRI_SERVICES[@]}"; do
        systemctl --user add-wants niri.service "$svc"
    done
    echo "Bağlandı: ${PACKAGES[*]}"
    echo "niri servisleri: ${NIRI_SERVICES[*]}"
}

uninstall() {
    for svc in "${NIRI_SERVICES[@]}"; do
        rm -f "$WANTS_DIR/$svc"
    done
    rmdir --ignore-fail-on-non-empty "$WANTS_DIR" 2>/dev/null || true
    stow_cmd --delete "${PACKAGES[@]}"
    systemctl --user daemon-reload
    echo "Bağlantılar kaldırıldı. Repo yerinde duruyor: $DOTFILES"
}

case "${1:-install}" in
    install)   install ;;
    uninstall) uninstall ;;
    *) echo "Kullanım: $0 [install|uninstall]" >&2; exit 1 ;;
esac
