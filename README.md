# niri masaüstü — clean · retro · sakura

Fedora 43'te KDE Plasma'nın **yanında**, giriş ekranından ayrı bir oturum olarak seçilen,
sıfırdan yazılmış bir [niri](https://github.com/niri-wm/niri) masaüstü.

- Bütün ayarlar bu repoda. GNU stow ile `~/.config` (ve `~/.local/bin`) altına symlink olarak bağlanır.
- KDE ayarlarına, giriş ekranına (GDM) ve varsayılan kabuğa (zsh) dokunulmaz.
- Renkler tek kaynaktan gelir: `theme` komutu (preset ya da duvar kağıdı).
- Font: Departure Mono (piksel). Köşeler 6 px, boşluklar 12 px, animasyonlar kısa ve sekmesiz.
- **Arayüz İngilizce:** Saat, takvim, panel etiketleri, bildirimler, kilit ekranı, kısayol
  listesi ve komutların ekrana yazdıkları. Türkçe yalnızca bu README'de ve config dosyalarındaki
  açıklama satırlarında var. Yeni bir arayüz metni eklerken de İngilizce yaz.

---

## İçindekiler

1. [Hızlı başlangıç](#hızlı-başlangıç)
2. [Kurulum (sıfırdan)](#kurulum-sıfırdan)
3. [Hangi dosya neyi kontrol ediyor](#hangi-dosya-neyi-kontrol-ediyor)
4. [Oturum nasıl başlıyor](#oturum-nasıl-başlıyor)
5. [Renkler: `theme` komutu](#renkler-theme-komutu)
6. [Yeni preset eklemek](#yeni-preset-eklemek)
7. [Duvar kağıdı](#duvar-kağıdı)
8. [Kısayollar](#kısayollar)
9. [Waybar modülleri](#waybar-modülleri)
10. [Font](#font)
11. [Ekranlar](#ekranlar)
12. [Kilit ve boşta kalma](#kilit-ve-boşta-kalma)
13. [Bir şey bozulursa](#bir-şey-bozulursa)
14. [Her şeyi tamamen kaldırmak](#her-şeyi-tamamen-kaldırmak)
15. [Notlar](#notlar)

---

## Hızlı başlangıç

**Oturuma girmek:** GDM'de kullanıcı adına tıkla → sağ alttaki ⚙️ → **Niri** → şifre.
GDM son seçilen oturumu hatırlar. KDE'ye dönmek için aynı menüden **Plasma**'yı seç.

| Kısayol | İş |
|---|---|
| `Super+Enter` | terminal (foot) |
| `Super+D` | uygulama başlatıcı (fuzzel) |
| `Super+Q` | pencereyi kapat |
| `Super+Shift+ß` (yani `Super+?`) | ekranda kısayol listesi |
| `Super+Shift+E` | oturumu kapat |

**KDE içinde pencere olarak denemek:** Konsole'da `niri` yaz. Bu modda Mod tuşu **Alt**'tır.
Waybar, mako gibi servisler bu modda başlamaz, çünkü onlar oturumun systemd servisine bağlı.

---

## Kurulum (sıfırdan)

```bash
# 1) Paketler — hepsi resmi Fedora reposundan (sudo gerekir)
sudo dnf install --setopt=install_weak_deps=False \
    niri xwayland-satellite foot stow brightnessctl playerctl \
    waybar fuzzel mako swaylock swayidle swaybg \
    network-manager-applet pavucontrol blueman cargo

# 2) wallust — duvar kağıdından renk üretir (resmi repoda yok; crates.io'dan derlenir)
cargo install --locked wallust          # → ~/.cargo/bin/wallust

# 3) Departure Mono — resmi sürüm, SIL OFL 1.1
mkdir -p /tmp/dm && cd /tmp/dm
curl -fLO https://github.com/rektdeckard/departure-mono/releases/download/v1.500/DepartureMono-1.500.zip
echo "bf3e48059aeef4617ec585bdea81dcc3491c576b3e7a472f52faf40e09ee5c3a  DepartureMono-1.500.zip" | sha256sum -c
unzip -q DepartureMono-1.500.zip
install -D -m 644 -t ~/.local/share/fonts/DepartureMono \
    DepartureMono-1.500/DepartureMono-Regular.otf DepartureMono-1.500/LICENSE
fc-cache -f

# 4) Bağla, servisleri kaydet, temayı üret (sudo yok)
~/dotfiles/install.sh

# 5) Kontrol
~/dotfiles/check.sh
```

`--setopt=install_weak_deps=False` niri'nin önerdiği alacritty'nin ve Waybar'ın önerdiği
fontawesome'un kurulmasını engeller.

Fedora Workstation'da zaten gelenler: xdg-desktop-portal-gnome/-gtk, gnome-keyring, nautilus
(dosya seçici), polkit-kde, wireplumber, wl-clipboard, libnotify, python3, python3-pillow.

`install.sh` tekrar tekrar çalıştırılabilir. Repo'ya yeni dosya eklediğinde de yeniden çalıştır.

---

## Hangi dosya neyi kontrol ediyor

Repo'daki her üst klasör bir **stow paketidir**: içindeki yol `~` altına aynen bağlanır
(ör. `niri/.config/niri/config.kdl` → `~/.config/niri/config.kdl`).

### niri

| Dosya | Ne yapar |
|---|---|
| `niri/.config/niri/config.kdl` | Ana dosya: diğerlerini sırayla dahil eder, imleç, ekran görüntüsü yolu, ortam değişkenleri |
| `niri/.config/niri/input.kdl` | Klavye düzeni (`de`), touchpad (dokunarak tıklama, yazarken kapanma) |
| `niri/.config/niri/outputs.kdl` | Ekranlar: ölçek, konum, harici monitör |
| `niri/.config/niri/layout.kdl` | Boşluklar, sütun genişlikleri, odak halkası kalınlığı, gölge, yedek renkler |
| `niri/.config/niri/binds.kdl` | Bütün kısayollar |
| `niri/.config/niri/rules.kdl` | Pencere kuralları: yuvarlak köşeler, yüzen pencerelere gölge, hangi pencereler yüzen açılır |
| `niri/.config/niri/animations.kdl` | Animasyonlar |

niri config'i **canlı yenilenir**: kaydettiğin an uygulanır.

### Panel, başlatıcı, bildirim, terminal

| Dosya | Ne yapar |
|---|---|
| `waybar/.config/waybar/config.jsonc` | Panel: hangi modüller nerede, biçimleri, tıklama eylemleri |
| `waybar/.config/waybar/style.css` | Panel görünümü (font, boşluk, köşe, durum renkleri) |
| `fuzzel/.config/fuzzel/fuzzel.ini` | Uygulama başlatıcı |
| `mako/.config/mako/config` | Bildirimler ve ses/parlaklık göstergesinin yeri ve boyutu |
| `foot/.config/foot/foot.ini` | Terminal: font, iç boşluk, imleç, geçmiş |

### Renk sistemi

| Dosya | Ne yapar |
|---|---|
| `bin/.local/bin/theme` | Renk yöneticisi (Python) |
| `themes/presets/*.toml` | Paletler. Her preset tek bir dosya. |
| `themes/templates/*` | Her bileşen için renk şablonu. **swaylock'un bütün ayarları** da burada (`swaylock.conf`), çünkü swaylock include desteklemiyor. |
| `themes/wallust/` | wallust ayarı ve ham palet şablonu (yalnızca `theme wallpaper` kullanır) |

### Servisler ve yardımcılar

| Dosya | Ne yapar |
|---|---|
| `systemd/.config/systemd/user/niri-polkit.service` | KDE'nin polkit (yönetici şifresi) penceresi, yalnızca niri'de |
| `systemd/.config/systemd/user/theme-apply.service` | Oturum açılışında kayıtlı temayı uygular |
| `systemd/.config/systemd/user/swaybg.service` | Duvar kağıdı |
| `systemd/.config/systemd/user/swayidle.service` | Boşta kalınca kilit ve ekran kapatma süreleri |
| `systemd/.config/systemd/user/mako.service.d/niri-only.conf` | mako'nun KDE/GNOME'da başlamasını engeller |
| `systemd/.config/systemd/user/app-…@autostart.service.d/not-in-niri.conf` | KDE'den gelen bazı autostart programlarının niri'de **başlamaması** (bkz. [Notlar](#notlar)) |
| `autostart/.config/autostart/nm-applet.desktop` | Wi-Fi tepsi simgesi, yalnızca niri'de |
| `autostart/.config/autostart/blueman.desktop` | Bluetooth tepsi simgesi, yalnızca niri'de |
| `bin/.local/bin/osd` | Ses/mikrofon/parlaklık tuşları: değeri değiştirir, üst ortada gösterge açar |
| `bin/.local/bin/lock-screen` | Ekranı kilitler (zaten kilitliyse bir şey yapmaz) |
| `flatpak/brave-flags.conf` | Brave'in niri'de de KWallet kullanması (bkz. [Notlar](#notlar)) |
| `wallpapers/` | Duvar kağıtların |
| `install.sh` | Bağlar, servisleri kaydeder, temayı üretir. `uninstall` ile geri alır. |
| `check.sh` | Bütün config'leri programları çalıştırmadan doğrular |

### Repo dışında kalanlar (üretilen ya da kopyalanan)

| Yol | Nedir |
|---|---|
| `~/.local/state/theme/` | `theme` komutunun ürettiği renk dosyaları, kayıtlı seçim, duvar kağıdı bağlantısı |
| `~/.config/systemd/user/niri.service.wants/` | `install.sh`'nin oluşturduğu servis bağlantıları |
| `~/.local/share/fonts/DepartureMono/` | Font |
| `~/.cargo/bin/wallust` | wallust |
| `~/.var/app/com.brave.Browser/config/brave-flags.conf` | Brave flags'in kopyası (Flatpak sandbox'ı symlink'i göremez) |

---

## Oturum nasıl başlıyor

```
GDM → niri-session → niri.service
        ├─ niri.service.wants/ (install.sh kaydeder)
        │    niri-polkit · theme-apply → waybar · mako · swaybg · swayidle
        └─ XDG autostart (OnlyShowIn=niri olanlar + KDE'de de açılanlar)
             nm-applet · blueman · KDE Connect · …
             (Cisco Secure Client, Xwayland Video Bridge, imsettings/IBus niri'de başlamaz)
```

Bu servislerin hiçbiri KDE oturumunda başlamaz. Durumlarını görmek için:

```bash
systemctl --user status niri-polkit theme-apply waybar mako swaybg swayidle
```

---

## Renkler: `theme` komutu

```bash
theme preset sakura                 # sabit palet
theme wallpaper sakura-gece.jpg     # duvar kağıdını değiştir + renkleri ondan üret
theme wallpaper foto.png --light    # açık tema zorla (ya da --dark)
theme wallpaper foto.png --keep-colors   # yalnızca duvar kağıdı, renkler aynı
theme wallpaper none                # duvar kağıdını kaldır (düz renk)
theme list                          # presetler (* = geçerli)
theme current                       # geçerli seçim
theme apply                         # kayıtlı seçimi yeniden uygula
```

Gelen presetler: **sakura** (varsayılan), rose-pine, rose-pine-dawn, catppuccin-mocha,
catppuccin-latte, gruvbox.

**Seçim kalıcıdır** (`~/.local/state/theme/state.json`). Her oturum açılışında yeniden uygulanır.

### Ne anında güncellenir?

| Bileşen | Nasıl |
|---|---|
| niri (odak halkası, arka plan, overview) | Dahil ettiği dosyayı kendisi izler, anında |
| Waybar | `@import` ettiği renk dosyasını kendisi izler (`reload_style_on_change`), anında |
| mako | `makoctl reload`, anında |
| Açık foot pencereleri | Kaçış dizileriyle, anında |
| Yeni foot pencereleri | include ettiği dosyadan |
| fuzzel, swaylock | Her açılışta dosyayı okur |
| swaybg | Yalnızca görsel ya da renk değiştiyse yeniden başlar |

### Renk anahtarları

Bütün şablonlar ve presetler aynı adları kullanır:

| Anahtar | Kullanıldığı yer |
|---|---|
| `bg` | Ana arka plan (panel, bildirim, başlatıcı, kilit ekranı, terminal) |
| `surface` | Bir ton farklı yüzey (overview arka planı) |
| `overlay` | Seçim, hover, pasif odak halkası |
| `muted` | Soluk yazı, boş workspace |
| `subtle` | İkincil yazı (pencere başlığı) |
| `fg` | Ana yazı |
| `accent` | Vurgu: odak halkası, seçili workspace, imleç, kenarlıklar |
| `accent2` | İkinci vurgu: ses/parlaklık göstergesi, linkler, kilit ekranı doğrulama |
| `urgent` | Hata, acil bildirim, kritik pil |
| `warn` | Uyarı, düşük pil, Caps Lock |
| `ok` | Şarjda |
| `color0` … `color15` | Terminalin 16 rengi |

### Duvar kağıdından renk üretimi nasıl çalışır?

`theme wallpaper` wallust'ı `lchansi` + `ansidark16` ile çalıştırır. Bu ayar terminal renklerinde
ANSI sırasını korur (1 kırmızı, 2 yeşil, 3 sarı, 4 mavi, 5 macenta, 6 camgöbeği), yani hata
çıktıları yine kırmızı görünür. Tonlar görselden gelir, açıklık ve doygunluk sakin bir pastel
aralığa çekilir. Vurgu rengi her zaman macenta yuvasından gelir, böylece her görselde sakura
pembesine yakın kalır.

Açık ya da koyu tema, görselin ortalama parlaklığına göre seçilir. `--light` ya da `--dark`
ile zorlayabilirsin.

---

## Yeni preset eklemek

Yeni bir preset **tek bir dosya** demek:

```bash
cp ~/dotfiles/themes/presets/sakura.toml ~/dotfiles/themes/presets/benim.toml
# benim.toml'u düzenle: name, variant ve renkler
theme preset benim
```

Dosya biçimi:

```toml
name = "Benim Temam"
variant = "dark"          # ya da "light"

[ui]                      # ZORUNLU: 11 renk, #rrggbb
bg      = "#1d1a21"
surface = "#26222b"
overlay = "#332d39"
muted   = "#6f6577"
subtle  = "#a397a8"
fg      = "#ede4ea"
accent  = "#f4a7b9"
accent2 = "#c9a7e0"
urgent  = "#e8697d"
warn    = "#e9c28b"
ok      = "#a8c9a0"

[term]                    # İSTEĞE BAĞLI: yazmadığın terminal renkleri [ui]'dan türetilir
color0 = "#2b2630"
# … color15'e kadar
```

Eksik ya da hatalı bir renk varsa `theme` hangi anahtar olduğunu söyler. Sonra
`~/dotfiles/check.sh` yeni preseti her bileşen için doğrular.

**Yeni bir bileşeni renk sistemine bağlamak:** `themes/templates/` içine bir dosya koy.
İçinde `{{bg}}` → `#1d1a21` ve `{{bg.hex}}` → `1d1a21` biçimleri kullanılabilir. `theme`, dosyayı
aynı adla `~/.local/state/theme/` altına üretir. Programın config'inden o dosyayı include et.

---

## Duvar kağıdı

1. Görselleri `~/dotfiles/wallpapers/` içine koy.
2. `theme wallpaper <dosya-adı>` komutunu çalıştır. Sadece dosya adı yazarsan bu klasörde aranır; tam yol da verebilirsin.

| İstek | Komut |
|---|---|
| Renkleri görselden üret | `theme wallpaper x.jpg` |
| Görseli değiştir, renkler kalsın | `theme wallpaper x.jpg --keep-colors` |
| Görseli kaldır (temanın düz arka plan rengi) | `theme wallpaper none` |
| Preset'e geç (görsel kalır) | `theme preset rose-pine` |

Görseller git'e de girer. İstemezsen `.gitignore`'a `wallpapers/*` ve `!wallpapers/.gitkeep`
satırlarını ekle.

---

## Kısayollar

Değiştirmek için: `niri/.config/niri/binds.kdl`. Kaydettiğin an geçerli olur.

- **Mod** = Super (Windows tuşu). KDE içinde pencere olarak açıkken Mod = Alt.
- Kalıp: **Ctrl** = taşı, **Shift** = monitör ya da dikey, **Shift+Ctrl** = monitöre taşı.
- Almanca klavyede AltGr isteyen `[ ] / =` tuşları bilerek kullanılmadı.
- Ekranda liste: `Super+Shift+ß` (Super+?). Listedeki açıklamalar İngilizce; `binds.kdl`'de
  `hotkey-overlay-title="…"` ile yazılıyor.

### Genel

| Kısayol | İş |
|---|---|
| `Super+Enter` | Terminal (foot) |
| `Super+D` / `Super+Space` | Uygulama başlatıcı (fuzzel) |
| `Super+Q` | Pencereyi kapat |
| `Super+O` | Genel bakış (overview). Sol üst köşeye fareyle gitmek de açar. |
| `Super+Shift+ß` | Kısayol listesi |
| `Super+Alt+L` | Ekranı kilitle |
| `Super+Shift+P` | Ekranları kapat (fare/klavye ile açılır) |
| `Super+Shift+E` | Oturumu kapat (onay ister) |
| `Super+Escape` | Bir uygulama (ör. sanal makine) kısayolları yakaladıysa geri al |

### Odak ve taşıma

| Kısayol | İş |
|---|---|
| `Super+←/→` veya `Super+H/L` | Sol/sağ sütuna odaklan. Kenardaysa yandaki monitöre geçer. |
| `Super+↑/↓` veya `Super+K/J` | Sütun içinde üst/alt pencere |
| `Super+Home` / `Super+End` | İlk / son sütun |
| `Super+Ctrl+←/→` veya `Super+Ctrl+H/L` | Sütunu sola/sağa taşı. Kenardaysa yandaki monitöre. |
| `Super+Ctrl+↑/↓` veya `Super+Ctrl+K/J` | Pencereyi sütun içinde yukarı/aşağı taşı |
| `Super+Ctrl+Home` / `Super+Ctrl+End` | Sütunu en başa / sona taşı |

### Monitörler

| Kısayol | İş |
|---|---|
| `Super+Shift+←/→/↑/↓` veya `Super+Shift+H/L/K/J` | O yöndeki monitöre odaklan |
| `Super+Shift+Ctrl+←/→/↑/↓` veya `Super+Shift+Ctrl+H/L/K/J` | Sütunu o yöndeki monitöre taşı |

### Workspace'ler (her monitörde dikey dizilir)

| Kısayol | İş |
|---|---|
| `Super+1` … `Super+9` | O workspace'e git |
| `Super+Ctrl+1` … `Super+Ctrl+9` | Sütunu o workspace'e taşı |
| `Super+U` / `Super+I` veya `Super+PgDn` / `Super+PgUp` | Alt / üst workspace |
| `Super+Ctrl+U` / `Super+Ctrl+I` veya `Super+Ctrl+PgDn/PgUp` | Sütunu alt / üst workspace'e taşı |
| `Super+Shift+U` / `Super+Shift+I` veya `Super+Shift+PgDn/PgUp` | Workspace'in kendisini aşağı / yukarı taşı |
| `Super+Tab` | Önceki workspace |
| `Super+tekerlek ↑/↓` | Üst / alt workspace |
| `Super+Ctrl+tekerlek ↑/↓` | Sütunu üst / alt workspace'e taşı |
| `Super+tekerlek ←/→`, `Super+Shift+tekerlek ↑/↓` | Sol / sağ sütun |

### Boyut ve yerleşim

| Kısayol | İş |
|---|---|
| `Super+R` | Sütun genişliği: 1/3 → 1/2 → 2/3 |
| `Super+Shift+R` | Pencere yüksekliği: 1/3 → 1/2 → 2/3 |
| `Super+Ctrl+R` | Pencere yüksekliğini sıfırla |
| `Super+F` | Sütunu büyüt |
| `Super+Shift+F` | Tam ekran |
| `Super+Ctrl+F` | Sütunu boş alana yay |
| `Super+-` / `Super++` | Sütun genişliği −/+ %10 |
| `Super+Shift+-` / `Super+Shift++` | Pencere yüksekliği −/+ %10 |
| `Super+C` | Sütunu ortala |
| `Super+Ctrl+C` | Görünen sütunları ortala |
| `Super+,` / `Super+.` | Pencereyi soldaki/sağdaki sütuna kat ya da sütundan çıkar |
| `Super+W` | Sütunu sekmeli göster |
| `Super+V` | Pencereyi yüzen yap / döşemeye geri al |
| `Super+Shift+V` | Odağı yüzen ↔ döşeli pencereler arasında değiştir |

### Ekran görüntüsü

Görüntü `~/Pictures/Screenshots/` içine kaydedilir ve panoya kopyalanır.

| Kısayol | İş |
|---|---|
| `Print` veya `Super+Shift+S` | Alan seç |
| `Ctrl+Print` | Bütün ekran |
| `Alt+Print` | Odaktaki pencere |

### Bildirimler

| Kısayol | İş |
|---|---|
| `Super+N` | Bildirimi kapat |
| `Super+Shift+N` | Hepsini kapat |
| `Super+Ctrl+N` | Son kapatılanı geri getir |

### Medya tuşları (kilit ekranında da çalışır)

| Tuş | İş |
|---|---|
| Ses +/− , sessiz | `osd volume up/down/mute`, üst ortada gösterge |
| Mikrofon sessiz | `osd mic mute` |
| Parlaklık +/− | `osd brightness up/down` (en az %1) |
| Oynat/duraklat, ileri, geri | `playerctl` |

### Panel (Waybar) üzerinde fare

| Yer | Eylem |
|---|---|
| Workspace numarası | Tıkla: o workspace'e git |
| Saat | Üstüne gel: takvim · sağ tık: ay/yıl görünümü · tekerlek: aylar arasında gez |
| `VOL` | Tıkla: pavucontrol · sağ tık: sessiz · tekerlek: ses ±%5 |
| `NET` | Tıkla: ağ bağlantıları penceresi |
| Tepsi | Wi-Fi (nm-applet), Bluetooth (blueman) ve diğer uygulamalar |

---

## Waybar modülleri

Hangi modülün nerede durduğu `waybar/.config/waybar/config.jsonc` içindeki üç listede tanımlı:

```jsonc
"modules-left":   ["niri/workspaces", "niri/window"],
"modules-center": ["clock"],
"modules-right":  ["wireplumber", "network", "battery", "tray"],
```

- **Kaldırmak:** Listeden sil.
- **Yer değiştirmek:** Listeler arasında taşı.
- **Eklemek:** Listeye adını yaz ve altına ayar bloğunu ekle. Örnek, parlaklık modülü:

  ```jsonc
  "modules-right": ["backlight", "wireplumber", "network", "battery", "tray"],
  "backlight": {
      "format": "<span alpha='55%'>LCD</span> {percent}%"
  },
  ```

  Aralık için `style.css`'teki `#wireplumber, #network, #battery { padding: … }` listesine
  `#backlight` ekle.

Modüllerin bütün seçenekleri man sayfalarında: `man waybar-clock`, `man waybar-battery`,
`man waybar-niri-workspaces`… Liste için: `ls /usr/share/man/man5 | grep waybar`.

Ne zaman ne yapılır:

- `style.css` ya da tema renkleri değiştiğinde Waybar kendisi yenilenir (`reload_style_on_change`).
- `config.jsonc`'yi değiştirdiysen: `systemctl --user restart waybar`.
- **`reload` ya da SIGUSR2 kullanma.** Waybar 0.14 bu yolla eski barları kapatmadan yenilerini
  açıyor, tepsi simgeleri de yeni barlara gelmiyor.

Panelin renkleri `style.css`'e değil temaya ait; `@accent`, `@fg` gibi adlar kullanılır.

---

## Font

Departure Mono **11 px ve katlarında** (22, 33…) piksel-mükemmel görünür. Laptop ekranı
ölçek 2'de olduğu için 11 px orada 22 fiziksel piksel olur; harici monitörde (ölçek 1) 11 px.
İkisi de keskin.

| Yer | Satır |
|---|---|
| Terminal | `foot/.config/foot/foot.ini` → `font=`, `font-bold=`, `font-italic=`, `font-bold-italic=` |
| Panel | `waybar/.config/waybar/style.css` → `font-family`, `font-size` |
| Başlatıcı | `fuzzel/.config/fuzzel/fuzzel.ini` → `font=` |
| Bildirimler | `mako/.config/mako/config` → `font=` (`11px` biçiminde) |
| Kilit ekranı | `themes/templates/swaylock.conf` → `font=`, `font-size=`, ardından `theme apply` |

Başka bir fonta geçersen:

- Adını öğrenmek için: `fc-list : family | grep -i <ad>`. Örneğin resmi repodaki `jetbrains-mono-fonts`.
- Departure Mono'nun kalın sürümü olmadığı için `foot.ini`'deki `font-bold/italic` satırları ve
  `bold-text-in-bright` var. Kalın sürümü olan bir fontta bu satırları silebilirsin.

---

## Ekranlar

Dosya: `niri/.config/niri/outputs.kdl`. Bağlı ekranları görmek için: `niri msg outputs`.

- **Laptop ekranı (`eDP-1`):** Ölçek **2**, mantıksal 1600×900. Daha fazla alan için `scale 1.85` yaz (KDE'deki değer); piksel font o zaman biraz yumuşar.
- **Harici monitör:** Konumu yazılmadığı için niri onu otomatik olarak laptopun **sağına** koyar. Takıp çıkarınca düzen yeniden kurulur.
- **Kapak kapalıyken:** niri iç ekranı kendisi kapatır, harici monitörü (0,0)'a alır ve laptop
  ekranındaki workspace'leri harici monitöre taşır. Kapak açılınca geri getirir. Harici monitör
  bağlıysa sistem uykuya geçmez, bağlı değilse uyur (logind varsayılanı). Kontrol etmek için
  kapak kapalıyken: `niri msg outputs` (eDP-1 "Disabled" görünmeli) ya da
  `journalctl --user -b -u niri | grep lid`.
- **Ekranın dışına taşan pencereler laptop ekranında değildir.** niri'de her workspace sağa ve sola
  sonsuz uzanan bir şerit; sığmayan sütunlar ekranın kenarının ötesinde bekler. Bir pencereyi
  fareyle kenara sürükleyince görünüm o yöne kayar. Bu, kapak açık ya da kapalı fark etmeden
  böyledir. Gezinmek için `Super+H/L`, `Super+Home/End` ya da `Super+O` (genel bakış).
  Sürüklerken görünümün kaymasını istemezsen `config.kdl`'ye şunu ekle:

  ```kdl
  gestures {
      dnd-edge-view-scroll {
          trigger-width 0
      }
  }
  ```
- **Belirli bir monitöre özel ayar** (ör. 120 Hz modu, farklı konum): `niri msg outputs` çıktısındaki marka-model-seri adıyla ekle:

  ```kdl
  output "Dell Inc. DELL XXXX ABC123" {
      mode "1920x1080@120.000"
      scale 1
  }
  ```

Klavye düzeni ve touchpad: `niri/.config/niri/input.kdl`. Doğal kaydırma için `natural-scroll`
satırının başındaki `//` işaretini sil.

---

## Kilit ve boşta kalma

- **Elle kilit:** `Super+Alt+L`.
- **Süreler:** `systemd/.config/systemd/user/swayidle.service` dosyasında:
  - 5 dakika boşta → kilit
  - 5,5 dakika → ekranlar kapanır
  - Uykudan önce → kilit

  Değiştirdikten sonra:

  ```bash
  systemctl --user daemon-reload && systemctl --user restart swayidle
  ```
- **Kilit ekranının görünümü:** `themes/templates/swaylock.conf`, ardından `theme apply`.
- Video izlerken tarayıcılar ve oynatıcılar boşta kalmayı kendileri engeller.

---

## Bir şey bozulursa

**1. Neyin bozulduğunu bul:**

```bash
~/dotfiles/check.sh
```

Her bileşen için `ok` ya da `FAIL` ve hatanın satırını gösterir.

**2. niri config hatası:** niri son geçerli config'le çalışmaya devam eder ve ekranda bir hata
bildirimi gösterir. Ayrıntı için: `niri validate`.

**3. Günlükler:**

```bash
journalctl --user -b -u niri          # niri
journalctl --user -b -u waybar        # panel
systemctl --user status waybar mako swaybg swayidle theme-apply niri-polkit
systemctl --user restart waybar       # panel kaybolduysa
```

**4. Renkler karıştı:** `theme preset sakura`.

**5. Bir değişikliği geri al (git):**

```bash
cd ~/dotfiles
git status                      # ne değişmiş
git diff                        # nasıl değişmiş
git checkout -- <dosya>         # commit'lenmemiş değişikliği at
git log --oneline               # geçmiş
git revert <commit>             # bir commit'i geri alan yeni commit
./install.sh                    # dosya eklendi/silindiyse bağlantıları yenile
```

Aşamalar ayrı commit'ler hâlinde duruyor. Örneğin `git log --oneline` ile Aşama 3'ün
commit'ini bulup o andaki dosyayı görebilirsin: `git show <commit>:niri/.config/niri/binds.kdl`.

**6. niri oturumu hiç açılmıyor:** GDM'de ⚙️ → **Plasma** ile KDE'ye gir; KDE bundan etkilenmez.
Sonra Konsole'da `~/dotfiles/check.sh` ve `journalctl --user -b -1 -u niri` (bir önceki açılışın
günlüğü). Grafik arayüz hiç gelmezse `Ctrl+Alt+F3` ile metin konsoluna geçebilirsin.

**7. Brave'de oturumlar kapanmış:** `~/.var/app/com.brave.Browser/config/brave-flags.conf`
dosyasında `--password-store=kwallet6` olmalı. `./install.sh` bu dosyayı yeniden yazar.

---

## Her şeyi tamamen kaldırmak

Plasma oturumundayken yap.

```bash
# 1) Bağlantılar, niri servis kayıtları, autostart girdileri, üretilmiş tema dosyaları,
#    Brave flags kopyası (yalnızca bizimkiyse)
~/dotfiles/install.sh uninstall

# 2) wallust ve önbelleği
cargo uninstall wallust
rm -rf ~/.cache/wallust

# 3) Font
rm -rf ~/.local/share/fonts/DepartureMono && fc-cache -f

# 4) Paketler (sudo). stow ve cargo'yu başka işler için kullanıyorsan listeden çıkar.
sudo dnf remove niri xwayland-satellite foot stow brightnessctl playerctl \
    waybar fuzzel mako swaylock swayidle swaybg \
    network-manager-applet pavucontrol blueman

# 5) Repo
rm -rf ~/dotfiles
```

niri paketi kaldırılınca GDM'deki **Niri** oturumu da kaybolur. KDE, GDM ve zsh ayarları
baştan beri değiştirilmediği için geri alınacak başka bir şey yok.

---

## Notlar

- **KDE'yi etkileyebilecek tek dosyalar** ve neden etkilemedikleri:
  - `~/.config/autostart/nm-applet.desktop`, `blueman.desktop`: İkisinde de `OnlyShowIn=niri;` var. blueman paketi kendi autostart'ıyla KDE'de de başlıyordu; bu dosya onu yalnızca niri'yle sınırlıyor. Yani KDE'yi kurulumdan önceki hâlinde tutuyor.
  - `mako.service.d/niri-only.conf`: KDE'de bir uygulama bildirim gönderdiğinde mako'nun tetiklenip Plasma'nın bildirimlerinin yerine geçmesini engelliyor.
  - `brave-flags.conf`: Brave KDE'de zaten KWallet 6'yı seçiyordu. Bu dosya aynı seçimi niri'de de sabitliyor, KDE'de davranış değişmiyor.
  - `app-…@autostart.service.d/not-in-niri.conf` (üç tane): KDE'nin de kullandığı autostart
    girdilerine `ConditionEnvironment=!XDG_CURRENT_DESKTOP=niri` koşulu ekliyor. KDE'de koşul
    sağlandığı için orada eskisi gibi başlıyorlar; yalnızca niri'de başlamıyorlar:
    - **Cisco Secure Client**: niri'de gerektiğinde fuzzel'den açılır (`Super+D` → "Cisco").
    - **Xwayland Video Bridge**: yalnızca KWin için gerekli; niri'de boş bir pencere açıyordu.
    - **imsettings-start**: giriş yöntemini IBus'a geçiriyor ve "ibus start" uyarısı veriyordu.
- **Başka bir autostart programını niri'de durdurmak:**
  1. Birim adını bul: `systemctl --user list-units --all 'app-*@autostart.service'`
  2. Aynı biçimde bir klasör aç:
     `systemd/.config/systemd/user/<birim-adı>.service.d/not-in-niri.conf`
     İçine yukarıdaki koşulu yaz. Addaki `\x2d` gibi kaçışlar aynen kalmalı.
  3. `./install.sh` çalıştır.
- **Chrome, Vivaldi, Chromium** da KWallet kullanıyor. niri'de bunları kullanacaksan aynı
  `--password-store=kwallet6` bayrağı gerekir; şu an yalnızca Brave ayarlı.
- **Sol üst köşe** niri'de genel bakışı açar. Kapatmak için `config.kdl`'ye şunu ekle:

  ```kdl
  gestures {
      hot-corners {
          off
      }
  }
  ```
- **Güç tuşu** niri'de bilgisayarı kapatmaz, uyutur (niri varsayılanı).
- niri belgeleri: <https://github.com/niri-wm/niri/wiki>.
