#!/bin/sh
# install.sh — niri masaüstünü kurar. Etkileşimli: hangi sistemde olduğunu sorar (Fedora,
# FreeBSD ya da başka), gereken paketleri gösterip kurmayı önerir, fontları indirir, ayar
# dosyalarını ~ altına bağlar ve oturumu hazırlar. Tekrar tekrar çalıştırmak güvenlidir.
#
#   ./install.sh                   kur / güncelle (sorarak)
#   ./install.sh --backup          aynı adda dosyalar varsa önce yedeğe taşı, sonra bağla
#   ./install.sh uninstall         bağlantıları ve servis kayıtlarını kaldır (repo silinmez)
#
# Seçenekler (soruları atlamak için):
#   --os fedora|freebsd|other      sistemi sorma
#   --yes                          her soruya varsayılan cevabı ver (root işleri dahil)
#   --skip-packages                paket kurma adımını atla
#   --skip-fonts                   font indirme adımını atla
#
# POSIX sh: FreeBSD'de bash kurulu olmadan da çalışır. Root gereken işler (paket kurmak,
# FreeBSD'de servisleri açmak) her seferinde sorulur; sudo, doas ya da su ile yapılır.
# Ekrana yazılanlar İngilizce (arayüz kuralı); açıklamalar Türkçe.

set -eu

# Gerçek yol (pwd -P): bağlantıların hedefi bununla karşılaştırılır.
DOTFILES=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)

# ~ altına bağlanacak stow paketleri (repo'daki klasör adları).
PACKAGES="niri foot alacritty waybar fuzzel swaync mako bin autostart systemd swappy"

# Sadece niri oturumunda başlayacak kullanıcı servisleri (systemd'li sistemler; FreeBSD'de
# aynılarını `session daemon` başlatır).
NIRI_SERVICES="niri-polkit.service theme-apply.service waybar.service swaync.service mako.service
swayidle.service swaybg.service layout-mode.service launcher.service clipboard-history.service
device-notify.service theme-auto.timer night-light-auto.service night-light-auto.timer"

STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}
WANTS_DIR="$HOME/.config/systemd/user/niri.service.wants"
UNIT_DIR="$HOME/.config/systemd/user"
BACKUP_ROOT="$STATE_HOME/dotfiles-backup"
FONT_DIR="$HOME/.local/share/fonts"
# Paketi kendi servis dosyasını getirmeyen programlar için yazılan yedek servisin ilk satırı.
UNIT_MARK="# niri-config: written by install.sh"

# Bu bilgisayara özel niri ayarları (ekran ölçeği, klavye düzeni, imleç teması).
# Repoda değil: ilk kurulumda şablondan oluşturulur, sonra hiç dokunulmaz.
NIRI_LOCAL="$HOME/.config/niri/local.kdl"
NIRI_LOCAL_TEMPLATE="$DOTFILES/examples/niri-local.kdl"

# Brave (Flatpak) şifre/çerez anahtarını niri'de de KDE'deki gibi KWallet'te arasın.
# Flatpak sandbox'ı ~/dotfiles'ı göremez; bu yüzden symlink değil kopya.
BRAVE_FLAGS_SRC="$DOTFILES/flatpak/brave-flags.conf"
BRAVE_FLAGS_DST="$HOME/.var/app/com.brave.Browser/config/brave-flags.conf"
KWALLET_FILE="$HOME/.local/share/kwalletd/kdewallet.kwl"

OS=""
ASSUME_YES=0
SKIP_PACKAGES=0
SKIP_FONTS=0
INTERACTIVE=0
[ -t 0 ] && [ -t 1 ] && INTERACTIVE=1

# ── Ekran ve sorular ─────────────────────────────────────────────────────

if [ "$INTERACTIVE" = 1 ]; then
    B=$(printf '\033[1m'); D=$(printf '\033[2m'); R=$(printf '\033[0m')
else
    B=""; D=""; R=""
fi

step() { printf '\n%s==> %s%s\n' "$B" "$*" "$R"; }
info() { printf '    %s\n' "$*"; }
warn() { printf '    %sWARNING:%s %s\n' "$B" "$R" "$*" >&2; }
die()  { printf '\n%sERROR:%s %s\n' "$B" "$R" "$*" >&2; exit 1; }

# ask <soru> <y|n>: evet ise 0. Soru sorulamıyorsa (--yes ya da terminal yok) varsayılan.
ask() {
    if [ "$ASSUME_YES" = 1 ] || [ "$INTERACTIVE" = 0 ]; then
        [ "$2" = y ]
        return
    fi
    if [ "$2" = y ]; then hint="[Y/n]"; else hint="[y/N]"; fi
    while :; do
        printf '%s %s ' "$1" "$hint"
        read -r reply || reply=""
        case $reply in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            "") [ "$2" = y ]; return ;;
        esac
    done
}

# ask_root <soru>: root olarak bir şey yapmadan önce. Terminal yoksa yalnızca --yes ile evet.
ask_root() {
    if [ "$INTERACTIVE" = 0 ] && [ "$ASSUME_YES" = 0 ]; then
        return 1
    fi
    ask "$1" y
}

# as_root <kabuk satırı>: sudo, doas ya da su (root şifresi) ile çalıştırır.
as_root() {
    if [ "$(id -u)" = 0 ]; then
        sh -c "$1"
    elif command -v sudo >/dev/null 2>&1; then
        sudo sh -c "$1"
    elif command -v doas >/dev/null 2>&1; then
        doas sh -c "$1"
    else
        info "${D}(no sudo or doas: asking for the root password with su)${R}"
        # su komutu root'un giriş kabuğuyla çalıştırır (eski kurulumlarda csh olabilir):
        # sh sözdizimi bozulmasın diye komut bir dosyadan /bin/sh ile okunur.
        script=$(mktemp)
        printf '%s\n' "$1" > "$script"
        rc=0
        su root -c "/bin/sh $script" || rc=$?
        rm -f "$script"
        return $rc
    fi
}

root_hint() {
    if [ "$OS" = freebsd ] && ! command -v sudo >/dev/null 2>&1 && ! command -v doas >/dev/null 2>&1; then
        info "To run commands as root you need to be in the 'wheel' group (for su), or set up sudo/doas."
    fi
}

# ── Sistem seçimi ─────────────────────────────────────────────────────────

detect_os() {
    case $(uname -s) in
        FreeBSD) echo freebsd; return ;;
        Linux) ;;
        *) echo other; return ;;
    esac
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        ids=$(. /etc/os-release; echo " ${ID:-} ${ID_LIKE:-} ")
        case $ids in *" fedora "*) echo fedora; return ;; esac
    fi
    echo other
}

os_name() {
    case $1 in
        fedora) echo "Fedora" ;;
        freebsd) echo "FreeBSD" ;;
        *) echo "another system" ;;
    esac
}

choose_os() {
    detected=$(detect_os)
    if [ -z "$OS" ]; then
        if [ "$INTERACTIVE" = 0 ]; then
            OS=$detected
        else
            case $detected in fedora) n=1 ;; freebsd) n=2 ;; *) n=3 ;; esac
            echo
            echo "${B}Which system are you installing on?${R}"
            echo "  1) Fedora"
            echo "  2) FreeBSD"
            echo "  3) Other ${D}(you install the programs yourself; this script links the configs)${R}"
            while :; do
                printf 'Choice [%s]: ' "$n"
                read -r c || c=""
                case ${c:-$n} in
                    1|fedora|Fedora) OS=fedora; break ;;
                    2|freebsd|FreeBSD) OS=freebsd; break ;;
                    3|other|Other) OS=other; break ;;
                    *) echo "Please type 1, 2 or 3." ;;
                esac
            done
        fi
    fi
    case $OS in
        fedora|freebsd|other) ;;
        *) die "unknown system '$OS' (use fedora, freebsd or other)" ;;
    esac
    if [ "$OS" != other ] && [ "$OS" != "$detected" ]; then
        warn "this computer looks like $(os_name "$detected"), not $(os_name "$OS")."
        ask "Continue anyway?" n || exit 1
    fi
}

# ── Paketler ──────────────────────────────────────────────────────────────

# Fedora: hepsi resmi Fedora deposundan. --setopt=install_weak_deps=False: Waybar'ın önerdiği
# fontawesome kendiliğinden gelmesin.
FEDORA_PACKAGES="niri xwayland-satellite foot alacritty stow brightnessctl playerctl
waybar fuzzel SwayNotificationCenter mako swaylock swayidle swaybg
jetbrains-mono-fonts ibm-plex-mono-fonts source-foundry-hack-fonts
network-manager-applet pavucontrol blueman cargo wlsunset
swappy wf-recorder slurp qalculate jq
xdg-desktop-portal-gnome xdg-desktop-portal-gtk nautilus
python3-gobject python3-pillow gtk-layer-shell"

# FreeBSD: hepsi resmi pkg deposundan (quarterly ve latest). Python modülleri sürüm önekiyle
# gelir (py312-…); önek kurulumda python3'ten okunur. Departure Mono, Monaspace ve wallust
# FreeBSD'de hazır paket. Ses: FreeBSD'nin kendi mikseri (PipeWire gerekmez).
FREEBSD_PACKAGES="niri xwayland-satellite xwayland foot alacritty stow
waybar fuzzel swaync mako swaylock swayidle swaybg wl-clipboard libnotify playerctl
python3 gtk3 gtk-layer-shell adwaita-icon-theme
jetbrains-mono plex-ttf hack-font departure-mono monaspace
wlsunset swappy wf-recorder slurp libqalculate jq wallust
xdg-desktop-portal-gtk xdg-utils xdg-user-dirs freedesktop-sound-theme
seatd dbus drm-kmod upower bash curl git"
FREEBSD_PY_MODULES="pygobject pillow"

# Başka bir sistemde aranacak programlar (paket adları dağıtıma göre değişir).
OTHER_PROGRAMS="niri xwayland-satellite foot alacritty stow waybar fuzzel swaync (or mako)
swaylock swayidle swaybg wl-clipboard notify-send (libnotify) playerctl jq python3
PyGObject (GTK 3 + gtk-layer-shell typelibs) Pillow wlsunset swappy wf-recorder slurp qalc"

missing_packages() {  # missing_packages <paketler…> → kurulu olmayanlar
    for p in "$@"; do
        case $OS in
            fedora) rpm -q --quiet "$p" 2>/dev/null || echo "$p" ;;
            freebsd) pkg info -e "$p" 2>/dev/null || echo "$p" ;;
        esac
    done
}

install_packages() {
    step "Packages for $(os_name "$OS")"
    if [ "$OS" = other ]; then
        info "Install these with your package manager (names differ between distributions):"
        echo "$OTHER_PROGRAMS" | sed 's/^/      /'
        info "niri: https://github.com/niri-wm/niri/wiki/Getting-Started"
        return 0
    fi
    if [ "$SKIP_PACKAGES" = 1 ]; then
        info "skipped (--skip-packages)"
        return 0
    fi

    if [ "$OS" = fedora ]; then
        # shellcheck disable=SC2086
        want=$FEDORA_PACKAGES
        # Yönetici şifresi soran pencere: KDE Plasma varsa onunki, yoksa mate-polkit.
        [ -x /usr/libexec/kf6/polkit-kde-authentication-agent-1 ] || want="$want mate-polkit"
        # shellcheck disable=SC2086
        missing=$(missing_packages $want | tr '\n' ' ')
        cmd="dnf install --setopt=install_weak_deps=False"
        [ "$ASSUME_YES" = 1 ] && cmd="$cmd -y"
        cmd="$cmd $missing"
    else
        if pkg -N >/dev/null 2>&1; then
            # shellcheck disable=SC2086
            missing=$(missing_packages $FREEBSD_PACKAGES | tr '\n' ' ')
            py=$(pkg query '%dn' python3 2>/dev/null | sed -n 's/^python3\([0-9]*\)$/py3\1/p' | head -n 1)
            for m in $FREEBSD_PY_MODULES; do
                if [ -z "$py" ] || ! pkg info -e "$py-$m" 2>/dev/null; then
                    missing="$missing$m(python) "
                fi
            done
        else
            missing="$FREEBSD_PACKAGES (pkg is not set up yet)"
        fi
        yes=""; [ "$ASSUME_YES" = 1 ] && yes=" -y"
        # Python modülleri python3 kurulduktan sonra, onun sürüm önekiyle (py312-pygobject…).
        pkgs=$(echo "$FREEBSD_PACKAGES" | tr '\n' ' ')
        cmd="pkg -N >/dev/null 2>&1 || env ASSUME_ALWAYS_YES=yes pkg bootstrap -f
pkg install$yes $pkgs || exit 1
py=\$(python3 -c 'import sys; print(\"py%d%d\" % sys.version_info[:2])') || exit 1
pkg install$yes \$py-pygobject \$py-pillow"
    fi

    missing=$(echo "$missing" | sed 's/ *$//')
    if [ -z "$missing" ]; then
        info "All packages are already installed."
        return 0
    fi
    info "Not installed yet:"
    echo "$missing" | fold -s -w 76 | sed 's/^/      /'
    if ask_root "Install them now (needs your password)?"; then
        root_hint
        as_root "$cmd" || die "package installation failed (see above). Fix it and run ./install.sh again."
    else
        info "Skipped. Install them yourself, then run ./install.sh again. The command:"
        echo "$cmd" | sed 's/^/      /'
    fi
}

# Kurulum devam etmeden önce şart olanlar.
require_tools() {
    for t in stow python3; do
        command -v "$t" >/dev/null 2>&1 || die "'$t' is not installed. Install the packages first (see above)."
    done
    python3 -c 'import gi; gi.require_version("Gtk", "3.0"); from gi.repository import Gtk' 2>/dev/null \
        || warn "Python GTK bindings (PyGObject) are missing: settings, search and popups won't open."
    for t in niri waybar fuzzel swaylock swayidle swaybg; do
        command -v "$t" >/dev/null 2>&1 || warn "'$t' is not installed."
    done
}

# ── wallust (duvar kağıdından renk) ──────────────────────────────────────

install_wallust() {
    if command -v wallust >/dev/null 2>&1 || [ -x "$HOME/.cargo/bin/wallust" ]; then
        return 0
    fi
    step "wallust (colors from your wallpaper)"
    if ! command -v cargo >/dev/null 2>&1; then
        info "Not installed. Color presets work without it; for wallpaper colors install wallust"
        info "(Fedora: cargo install --locked wallust · FreeBSD: pkg install wallust)."
        return 0
    fi
    # Uzun bir derleme: soru sorulamıyorsa yalnızca --yes ile.
    if [ "$INTERACTIVE" = 0 ] && [ "$ASSUME_YES" = 0 ]; then
        info "Not installed. To build it: cargo install --locked wallust"
        return 0
    fi
    if ask "Build wallust with cargo now? (a few minutes)" y; then
        cargo install --locked wallust || warn "wallust build failed; presets still work."
    fi
}

# ── Fontlar ───────────────────────────────────────────────────────────────

has_font() {
    fc-list : family 2>/dev/null | tr ',' '\n' | grep -qx "$1"
}

download() {  # download <url> <dosya>
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$2" "$1"
    elif command -v fetch >/dev/null 2>&1; then
        fetch -q -o "$2" "$1"
    elif command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1"
    else
        warn "no curl, fetch or wget to download $1"
        return 1
    fi
}

# fetch_verified <url> <sha256> <dosya>: indirir ve özetini doğrular (python3: her sistemde aynı).
fetch_verified() {
    download "$1" "$3" || return 1
    sum=$(python3 -c 'import hashlib, sys; print(hashlib.sha256(open(sys.argv[1], "rb").read()).hexdigest())' "$3")
    if [ "$sum" != "$2" ]; then
        warn "checksum mismatch for $1 (got $sum)"
        rm -f "$3"
        return 1
    fi
}

unzip_files() {  # unzip_files <zip> <hedef klasör> <arşivdeki yol…>  (yalnızca adı verilenler)
    python3 - "$@" <<'EOF'
import os, sys, zipfile
archive, dest, names = sys.argv[1], sys.argv[2], sys.argv[3:]
with zipfile.ZipFile(archive) as z:
    for name in names:
        with z.open(name) as src, open(os.path.join(dest, os.path.basename(name)), "wb") as out:
            out.write(src.read())
EOF
}

# Resmi sürümlerden indirilen fontlar (Fedora'da paket yok; FreeBSD'de yalnızca Cozette'in
# vektör sürümü ve Monocraft eksik). Zaten kuruluysa (fc-list) atlanır.
install_fonts() {
    step "Fonts"
    if [ "$SKIP_FONTS" = 1 ]; then
        info "skipped (--skip-fonts)"
        return 0
    fi
    if ! command -v fc-list >/dev/null 2>&1; then
        warn "fontconfig (fc-list) is missing; skipping fonts."
        return 0
    fi
    need=""
    has_font "Departure Mono" || need="$need departure"
    has_font "CozetteVector" || need="$need cozette"
    has_font "Monocraft" || need="$need monocraft"
    has_font "Monaspace Neon" || need="$need neon"
    if [ -z "$need" ]; then
        info "All fonts are installed."
        return 0
    fi
    info "To download into $FONT_DIR:$need"
    ask "Download them now (official releases, checksums verified)?" y || return 0
    tmp=$(mktemp -d)
    for f in $need; do
        case $f in
            departure)
                # Departure Mono v1.500 — SIL OFL 1.1
                if fetch_verified https://github.com/rektdeckard/departure-mono/releases/download/v1.500/DepartureMono-1.500.zip \
                        bf3e48059aeef4617ec585bdea81dcc3491c576b3e7a472f52faf40e09ee5c3a "$tmp/dm.zip"; then
                    mkdir -p "$FONT_DIR/DepartureMono"
                    unzip_files "$tmp/dm.zip" "$FONT_DIR/DepartureMono" \
                        DepartureMono-1.500/DepartureMono-Regular.otf DepartureMono-1.500/LICENSE
                    info "Departure Mono"
                fi ;;
            cozette)
                # Cozette v1.30.0 — MIT
                base=https://github.com/the-moonwitch/Cozette/releases/download/v.1.30.0
                mkdir -p "$FONT_DIR/CozetteVector"
                if fetch_verified "$base/CozetteVector.ttf" \
                        2d54a586f824f32d9d2dd01ec3b990c2a4d6445efa77e20177efe382ebe51627 "$FONT_DIR/CozetteVector/CozetteVector.ttf" \
                   && fetch_verified "$base/CozetteVectorBold.ttf" \
                        9f113791362001d53cd4c09cbe91f9125c050ca7aab49d48393601e79b2b1d41 "$FONT_DIR/CozetteVector/CozetteVectorBold.ttf"; then
                    download "$base/LICENSE" "$FONT_DIR/CozetteVector/LICENSE-Cozette" || true
                    info "Cozette Vector"
                fi ;;
            monocraft)
                # Monocraft v4.2.1 — SIL OFL 1.1
                mkdir -p "$FONT_DIR/Monocraft"
                fetch_verified https://github.com/IdreesInc/Monocraft/releases/download/v4.2.1/Monocraft.ttc \
                    0ea1aea12f03d552a469fc017f19ea927b53bf9d21e60a41c5c476c3faf3c7f9 "$FONT_DIR/Monocraft/Monocraft.ttc" \
                    && info "Monocraft" ;;
            neon)
                # Monaspace v1.400 — SIL OFL 1.1 (yalnızca Neon, dört stil)
                if fetch_verified https://github.com/githubnext/monaspace/releases/download/v1.400/monaspace-static-v1.400.zip \
                        ab66d71be751495f679727332a3345597943bd4d7beebca03f5cde04bf994de7 "$tmp/neon.zip"; then
                    mkdir -p "$FONT_DIR/MonaspaceNeon"
                    d="Static Fonts/Monaspace Neon"
                    unzip_files "$tmp/neon.zip" "$FONT_DIR/MonaspaceNeon" \
                        "$d/MonaspaceNeon-Regular.otf" "$d/MonaspaceNeon-Bold.otf" \
                        "$d/MonaspaceNeon-Italic.otf" "$d/MonaspaceNeon-BoldItalic.otf"
                    info "Monaspace Neon"
                fi ;;
        esac
    done
    rm -rf "$tmp"
    fc-cache -f >/dev/null 2>&1 || true
    has_font "Departure Mono" || warn "Departure Mono (the default font) is still missing; the desktop will use a fallback font."
}

# ── FreeBSD: sistem ayarları ──────────────────────────────────────────────

# niri'nin ekrana ve klavyeye erişmesi (seatd + video grubu + grafik sürücüsü), oturum D-Bus'ı
# için sistem D-Bus'ı ve kapat/yeniden başlat/uyku için operator grubu.
freebsd_setup() {
    step "FreeBSD system settings"
    user=$(id -un)
    todo=""
    cmds=""
    add() { todo="$todo
      - $1"; cmds="$cmds
$2"; }

    kmod=""
    if [ ! -e /dev/dri/card0 ]; then
        case $(pciconf -l 2>/dev/null | grep '^vgapci' | head -n 1) in
            *vendor=0x8086*) kmod=i915kms ;;
            *vendor=0x1002*) kmod=amdgpu ;;
        esac
        if [ -n "$kmod" ]; then
            add "load the graphics driver ($kmod) now and at every boot" \
                "sysrc kld_list+=$kmod && { kldstat -q -n $kmod || kldload $kmod; }"
        else
            warn "graphics driver: /dev/dri/card0 is missing and the GPU was not recognised."
            info "Load the right DRM module yourself (drm-kmod package: i915kms, amdgpu or radeonkms)."
        fi
    fi
    [ "$(sysrc -n seatd_enable 2>/dev/null)" = YES ] && [ -S /var/run/seatd.sock ] \
        || add "enable and start seatd (screen and keyboard access for niri)" \
               "sysrc seatd_enable=YES && { service seatd status >/dev/null 2>&1 || service seatd start; }"
    [ "$(sysrc -n dbus_enable 2>/dev/null)" = YES ] \
        || add "enable and start the system D-Bus (battery, drives, notifications)" \
               "sysrc dbus_enable=YES && { service dbus status >/dev/null 2>&1 || service dbus start; }"
    groups=" $(id -Gn) "
    case $groups in *" video "*) ;; *)
        add "add $user to the 'video' group (needed for seatd)" "pw groupmod video -m $user" ;; esac
    case $groups in *" operator "*) ;; *)
        add "add $user to the 'operator' group (shut down, restart and suspend from the desktop)" \
            "pw groupmod operator -m $user" ;; esac

    if [ -z "$todo" ]; then
        info "Everything is set up."
        return 0
    fi
    info "These need root:$todo"
    if ask_root "Do this now?"; then
        root_hint
        as_root "set -e$cmds" || die "system setup failed (see above)."
        case $groups in *" video "*" operator "*|*" operator "*" video "*) ;; *)
            NEED_RELOGIN=1 ;; esac
    else
        info "Skipped. As root, run:"
        echo "$cmds" | sed '/^$/d; s/^/      /'
    fi
}

# ── Bağlama (stow) ────────────────────────────────────────────────────────

stow_cmd() {
    # --no-folding: klasörleri değil tek tek dosyaları bağla; programların
    # ~/.config altına yazdığı dosyalar repo'ya karışmasın.
    stow --dir "$DOTFILES" --target "$HOME" --no-folding --ignore='__pycache__' "$@"
}

# Paketlerdeki her dosyanın ~ altındaki karşılığı (repo'ya göre yol, satır başına bir tane).
package_files() {
    for pkg in $PACKAGES; do
        (cd "$DOTFILES/$pkg" && find . -name __pycache__ -prune -o \( -type f -o -type l \) -print) \
            | sed 's|^\./||'
    done
}

# Python ile (her sistemde aynı davranış; GNU readlink -m'nin karşılığı realpath'in kendisi).
# conflicts:  ~ altında zaten var olan ve bu repoya çıkmayan dosyalar (stow üstlerine yazmaz)
# prune:      repo'dan silinmiş dosyalara giden kırık bağlantıları siler
link_helper() {
    python3 - "$1" "$HOME" "$DOTFILES" $PACKAGES <<'EOF'
import os, sys
mode, home, repo, packages = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4:]
inside = lambda p: os.path.realpath(p).startswith(repo + os.sep)
for pkg in packages:
    root = os.path.join(repo, pkg)
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d != "__pycache__"]
        rel_dir = os.path.relpath(dirpath, root)
        if mode == "conflicts":
            for name in filenames:
                rel = os.path.normpath(os.path.join(rel_dir, name))
                dst = os.path.join(home, rel)
                if os.path.lexists(dst) and not inside(dst):
                    print(rel)
        elif mode == "prune" and rel_dir != ".":             # ~'nin kendisi taranmaz
            target = os.path.normpath(os.path.join(home, rel_dir))
            if os.path.isdir(target) and not os.path.islink(target):
                for entry in os.scandir(target):
                    if entry.is_symlink() and not os.path.exists(entry.path) and inside(entry.path):
                        os.unlink(entry.path)
EOF
}

backup_conflicts() {  # stdin: yollar
    dir="$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)"
    n=0
    while IFS= read -r rel; do
        mkdir -p "$dir/$(dirname -- "$rel")"
        mv -- "$HOME/$rel" "$dir/$rel"
        n=$((n + 1))
    done
    info "Moved $n existing file(s) to $dir"
}

link_files() {
    step "Linking the configs into your home folder"
    conflicts=$(link_helper conflicts)
    if [ -n "$conflicts" ]; then
        echo "These files already exist and are not from this repo:" >&2
        echo "$conflicts" | sed 's|^|  ~/|' >&2
        if [ "$BACKUP" = 1 ] || ask "Move them to $BACKUP_ROOT and continue?" n; then
            echo "$conflicts" | backup_conflicts
        else
            die "nothing was linked. Run '$0 --backup' to move them aside and install."
        fi
    fi
    link_helper prune
    # shellcheck disable=SC2086
    stow_cmd --restow $PACKAGES
    info "Linked: $PACKAGES"
}

# ── Bu bilgisayara özel ayarlar (local.kdl) ──────────────────────────────

# Laptop ekranının adı (eDP-1 gibi); bulunamazsa eDP-1 (masaüstünde blok etkisiz kalır).
# Linux: /sys/class/drm · FreeBSD'de sysfs yok, niri'nin adı yine eDP-1 olur.
laptop_panel() {
    for f in /sys/class/drm/card*-eDP-*/status /sys/class/drm/card*-LVDS-*/status \
             /sys/class/drm/card*-DSI-*/status; do
        [ -r "$f" ] && [ "$(cat "$f")" = connected ] || continue
        name=${f%/status}; name=${name##*/}
        echo "${name#card*-}"
        return 0
    done
    echo "eDP-1"
}

# Sistemin klavye düzeni okunabiliyor mu (Linux: systemd-localed; niri boş xkb'de onu kullanır).
system_keyboard_known() {
    command -v localectl >/dev/null 2>&1 && localectl status 2>/dev/null | grep -q "X11 Layout"
}

# FreeBSD: konsolun düzeninden (rc.conf keymap="tr.f.kbd") xkb tahmini: "tr f".
guess_layout() {
    km=$(sysrc -n keymap 2>/dev/null || true)
    case $km in ""|NO) echo us; return ;; esac
    km=${km%.kbd}
    layout=${km%%.*}
    case $km in
        *.f|*.f.*) echo "$layout f" ;;
        *.dvorak*) echo "$layout dvorak" ;;
        *) echo "$layout" ;;
    esac
}

make_niri_local() {
    [ -e "$NIRI_LOCAL" ] && return 0
    step "This computer's niri settings ($NIRI_LOCAL)"
    mkdir -p "$(dirname -- "$NIRI_LOCAL")"
    sed "s/@LAPTOP@/$(laptop_panel)/" "$NIRI_LOCAL_TEMPLATE" > "$NIRI_LOCAL"
    if ! system_keyboard_known; then
        guess=$(guess_layout)
        kb=$guess
        if [ "$INTERACTIVE" = 1 ] && [ "$ASSUME_YES" = 0 ]; then
            echo "Keyboard layout for niri. Examples: us · de · tr (Turkish Q) · tr f (Turkish F) · fr"
            printf 'Layout [%s]: ' "$guess"
            read -r kb || kb=""
            kb=${kb:-$guess}
        fi
        # shellcheck disable=SC2086
        set -- $kb
        {
            echo ""
            echo "// Kurulumda seçilen klavye düzeni (install.sh). Değiştirmek için düzenle."
            echo "input {"
            echo "    keyboard {"
            echo "        xkb {"
            echo "            layout \"${1:-us}\""
            [ -n "${2:-}" ] && echo "            variant \"$2\""
            echo "        }"
            echo "    }"
            echo "}"
        } >> "$NIRI_LOCAL"
        info "Keyboard layout: $kb"
    fi
    info "Created (screen scale, keyboard layout, cursor theme). Edit it any time; git pull won't touch it."
}

# ── Oturum servisleri ─────────────────────────────────────────────────────

systemd_user() {
    [ "$OS" != freebsd ] && command -v systemctl >/dev/null 2>&1 \
        && systemctl --user show-environment >/dev/null 2>&1
}

# Paketi servis dosyası getirmeyen programlar için (ör. Arch'ın waybar'ı) basit bir servis.
fallback_unit() {  # fallback_unit <ad> <komut> <açıklama>
    unit="$UNIT_DIR/$1.service"
    [ -n "$(systemctl --user show -p FragmentPath --value "$1.service" 2>/dev/null)" ] && return 0
    command -v "$2" >/dev/null 2>&1 || return 0
    mkdir -p "$UNIT_DIR"
    cat > "$unit" <<EOF
$UNIT_MARK (the $2 package has no service file); removed by ./install.sh uninstall
[Unit]
Description=$3
PartOf=graphical-session.target
After=graphical-session.target
Requisite=graphical-session.target

[Service]
ExecStart=/usr/bin/env $2
Restart=on-failure
EOF
    info "Wrote $unit"
}

setup_services() {
    step "Session services"
    if systemd_user; then
        fallback_unit waybar waybar "Waybar panel"
        fallback_unit swaync swaync "SwayNotificationCenter"
        fallback_unit mako mako "mako notifications"
        systemctl --user daemon-reload
        for svc in $NIRI_SERVICES; do
            systemctl --user add-wants niri.service "$svc" >/dev/null 2>&1 \
                || warn "could not register $svc"
        done
        info "systemd --user starts them with niri (niri-session)."
    else
        info "No systemd: niri starts them itself at login (~/.local/bin/session daemon)."
    fi
}

install_brave_flags() {
    [ -d "$HOME/.var/app/com.brave.Browser" ] || return 0
    # Yalnızca KWallet gerçekten kullanılıyorsa (KDE Plasma). GNOME'da Brave zaten
    # gnome-keyring'i kullanır; bayrak orada kayıtlı şifrelere erişimi bozardı.
    [ -f "$KWALLET_FILE" ] || return 0
    if [ -e "$BRAVE_FLAGS_DST" ] && ! cmp -s "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST"; then
        warn "$BRAVE_FLAGS_DST already exists and differs; left untouched."
        return 0
    fi
    mkdir -p "$(dirname -- "$BRAVE_FLAGS_DST")"
    cp "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST"
    chmod 644 "$BRAVE_FLAGS_DST"
}

finish() {
    step "Done"
    case $OS in
        fedora)
            info "Log out and choose ${B}Niri${R} on the login screen."
            info "Or from a text console (Ctrl+Alt+F3): ~/.local/bin/niri-start" ;;
        freebsd)
            [ "${NEED_RELOGIN:-0}" = 1 ] && info "${B}Log out and back in first${R} (new group memberships)."
            info "Start niri from the text console: ${B}~/.local/bin/niri-start${R}"
            info "It checks seatd, the graphics driver and your groups, and tells you what is missing." ;;
        *)
            info "Start niri with your display manager (Niri session) or from a text console:"
            info "~/.local/bin/niri-start" ;;
    esac
    info "First steps: Super+? lists the shortcuts, Super+S opens the settings."
    info "Check the configs any time: $DOTFILES/check.sh"
}

do_install() {
    echo "${B}niri desktop — installer${R}  ${D}($DOTFILES)${R}"
    choose_os
    install_packages
    require_tools
    install_fonts
    install_wallust
    [ "$OS" = freebsd ] && freebsd_setup
    link_files
    make_niri_local
    setup_services
    install_brave_flags
    step "Generating theme files"
    # Kayıtlı seçim yoksa varsayılan: sakura.
    "$HOME/.local/bin/theme" apply
    finish
}

# ── Kaldırma ──────────────────────────────────────────────────────────────

do_uninstall() {
    if command -v systemctl >/dev/null 2>&1 && [ "$(uname -s)" != FreeBSD ]; then
        for svc in $NIRI_SERVICES; do
            rm -f "$WANTS_DIR/$svc"
        done
        rmdir "$WANTS_DIR" 2>/dev/null || true
        for unit in "$UNIT_DIR"/waybar.service "$UNIT_DIR"/swaync.service "$UNIT_DIR"/mako.service; do
            if [ -f "$unit" ] && [ ! -L "$unit" ] && head -n 1 "$unit" | grep -q "^$UNIT_MARK"; then
                rm -f "$unit"
            fi
        done
    fi
    # shellcheck disable=SC2086
    stow_cmd --delete $PACKAGES
    if command -v systemctl >/dev/null 2>&1 && [ "$(uname -s)" != FreeBSD ]; then
        systemctl --user daemon-reload 2>/dev/null || true
    fi
    # theme komutunun ürettiği dosyalar (yalnızca üretilmiş veriler).
    rm -rf "$STATE_HOME/theme"
    # displays komutunun monitör kayıtları (config.kdl onu isteğe bağlı okur).
    rm -rf "$STATE_HOME/displays"
    # Settings uygulamasının yazdıkları: touchpad, kilit süresi, gece ışığı sıcaklığı.
    rm -rf "$STATE_HOME/settings" "${XDG_CACHE_HOME:-$HOME/.cache}/settings"
    # Ayarlar → Default apps: yalnızca bizim yazdığımız dosyaysa (ilk satırı bizim başlığımız).
    mimeapps="${XDG_CONFIG_HOME:-$HOME/.config}/niri-mimeapps.list"
    if head -n 1 "$mimeapps" 2>/dev/null | grep -q "^# niri oturumunun varsayılan uygulamaları"; then
        rm -f "$mimeapps"
    fi
    # Arama penceresinin hatırladığı sık kullanılan uygulamalar ve emojiler.
    rm -rf "$STATE_HOME/launcher"
    # systemd'siz oturumun servis günlükleri.
    rm -rf "$STATE_HOME/niri-session"
    # Brave flags dosyası yalnızca bizim kopyamızsa silinir.
    if cmp -s "$BRAVE_FLAGS_SRC" "$BRAVE_FLAGS_DST" 2>/dev/null; then
        rm -f "$BRAVE_FLAGS_DST"
    fi
    echo "Removed links, generated theme files, saved monitor positions, settings, default apps and launcher history. The repo is still at: $DOTFILES"
    # local.kdl elle düzenlenmiş olabilir; silinmez. Fontlar ve paketler de yerinde kalır.
    [ -e "$NIRI_LOCAL" ] && echo "Kept $NIRI_LOCAL (your own settings for this computer); delete it by hand if you like."
    return 0
}

usage() {
    sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//' >&2
    exit "${1:-1}"
}

ACTION=install
BACKUP=0
while [ $# -gt 0 ]; do
    case $1 in
        install) ACTION=install ;;
        uninstall) ACTION=uninstall ;;
        --backup) BACKUP=1 ;;
        --os) [ $# -ge 2 ] || usage; OS=$2; shift ;;
        --os=*) OS=${1#--os=} ;;
        --yes|-y) ASSUME_YES=1 ;;
        --skip-packages) SKIP_PACKAGES=1 ;;
        --skip-fonts) SKIP_FONTS=1 ;;
        -h|--help) usage 0 ;;
        *) echo "Unknown option: $1" >&2; usage ;;
    esac
    shift
done

case $ACTION in
    install) do_install ;;
    uninstall) do_uninstall ;;
esac
