#!/bin/sh
# get.sh — niri masaüstünü tek komutla indirir ve kurar (FreeBSD, Fedora, başka).
#
#   FreeBSD:  fetch -qo - https://raw.githubusercontent.com/ArdaFA/niri-config/main/get.sh | sh
#   Fedora:   curl -fsSL https://raw.githubusercontent.com/ArdaFA/niri-config/main/get.sh | sh
#
# Repoyu ~/dotfiles'a klonlar (zaten klonlanmışsa günceller), sonra ./install.sh'yi terminalde
# soru sorarak çalıştırır. git yoksa önce onu kurar (yönetici şifresini sorar).
#   install.sh'ye seçenek vermek:  … | sh -s -- --backup
#   başka bir klasör:              … | env NIRI_CONFIG_DIR=$HOME/src/niri-config sh
#
# Bütün betik main() içinde: `| sh` ile okunurken önce tamamı okunur, sonra çalışır.
# install.sh'nin soruları terminalden (/dev/tty) okunur, çünkü stdin bu betiğin kendisi.
# Ekrana yazılanlar İngilizce (arayüz kuralı); açıklamalar Türkçe.

main() {
    set -eu
    repo=https://github.com/ArdaFA/niri-config.git
    dir=${NIRI_CONFIG_DIR:-$HOME/dotfiles}

    say() { printf '==> %s\n' "$*"; }
    die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

    # Root için izni gerçekten olan araç (install.sh'deki gibi): doas -C, sudo -l, yoksa su.
    doas_ok() {
        command -v doas >/dev/null 2>&1 || return 1
        for conf in /usr/local/etc/doas.conf /etc/doas.conf; do
            [ -r "$conf" ] && doas -C "$conf" sh 2>/dev/null | grep -q '^permit' && return 0
        done
        return 1
    }
    sudo_ok() {
        command -v sudo >/dev/null 2>&1 || return 1
        sudo -n -l sh >/dev/null 2>&1 || { sudo -v && sudo -n -l sh >/dev/null 2>&1; }
    }
    as_root() {  # basit tek komutlar için (tırnaksız)
        if doas_ok; then
            doas sh -c "$1"
        elif sudo_ok; then
            sudo sh -c "$1"
        else
            echo "    (asking for the root password with su; your user must be in the 'wheel' group)"
            su root -c "$1"
        fi
    }

    if [ "$(id -u)" = 0 ]; then
        die "run this as your normal user, without doas/sudo in front. It sets up your own home folder and asks for the password when it needs root."
    fi

    if [ -d "$dir/.git" ]; then
        say "Updating $dir"
        git -C "$dir" pull --ff-only \
            || die "could not update $dir (changed files?). See 'git -C $dir status', or move the folder away and run this again."
    elif [ -e "$dir" ]; then
        die "$dir already exists and is not a git clone. Move it away (or use NIRI_CONFIG_DIR) and run this again."
    else
        if ! command -v git >/dev/null 2>&1; then
            say "Installing git (needed for downloading and updating)"
            case $(uname -s) in
                FreeBSD)
                    # ASSUME_ALWAYS_YES: pkg ilk kez çalışıyorsa kendini de sormadan kurar.
                    as_root "env ASSUME_ALWAYS_YES=yes pkg install git" || die "could not install git" ;;
                *)
                    if command -v dnf >/dev/null 2>&1; then
                        as_root "dnf install -y git" || die "could not install git"
                    else
                        die "git is not installed. Install it with your package manager and run this again."
                    fi ;;
            esac
        fi
        say "Downloading into $dir"
        git clone --quiet "$repo" "$dir"
    fi

    cd "$dir"
    if (: < /dev/tty) 2>/dev/null; then
        exec sh ./install.sh "$@" < /dev/tty
    fi
    exec sh ./install.sh "$@"
}

main "$@"
