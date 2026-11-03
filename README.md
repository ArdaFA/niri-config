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
8. [Otomatik düzen: AUTO / FREE](#otomatik-düzen-auto--free)
9. [Kısayollar](#kısayollar)
10. [Waybar modülleri](#waybar-modülleri)
11. [Hızlı ayarlar ve bildirimler](#hızlı-ayarlar-ve-bildirimler)
12. [Font](#font)
13. [Ekranlar](#ekranlar)
14. [Kilit ve boşta kalma](#kilit-ve-boşta-kalma)
15. [Bir şey bozulursa](#bir-şey-bozulursa)
16. [Her şeyi tamamen kaldırmak](#her-şeyi-tamamen-kaldırmak)
17. [Notlar](#notlar)

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
Waybar, swaync gibi servisler bu modda başlamaz, çünkü onlar oturumun systemd servisine bağlı.

---

## Kurulum (sıfırdan)

```bash
# 1) Paketler — hepsi resmi Fedora reposundan (sudo gerekir)
sudo dnf install --setopt=install_weak_deps=False \
    niri xwayland-satellite foot stow brightnessctl playerctl \
    waybar fuzzel SwayNotificationCenter mako swaylock swayidle swaybg \
    network-manager-applet pavucontrol blueman cargo wlsunset

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
fontawesome'un kurulmasını engeller. mako, SwayNotificationCenter kaldırılırsa devreye giren
yedek bildirim programı (bkz. [Hızlı ayarlar ve bildirimler](#hızlı-ayarlar-ve-bildirimler)).

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
| `niri/.config/niri/input.kdl` | Klavye düzeni (`de`), touchpad (dokunarak tıklama, yazarken kapanma), odağın fareyi takip etmesi, sürüklerken kenarda kaymama, sol üst köşe |
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
| `waybar/.config/waybar/style.css` | Panel görünümü (font, boşluk, durum renkleri) |
| `fuzzel/.config/fuzzel/fuzzel.ini` | Uygulama başlatıcı |
| `swaync/.config/swaync/config.json` | Bildirimler ve hızlı ayarlar paneli: bölümler, düğmeler, zaman aşımları |
| `swaync/.config/swaync/style.css` | Bildirimlerin ve panelin görünümü |
| `mako/.config/mako/config` | Yedek bildirim programı (yalnızca swaync kaldırılırsa çalışır) |
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
| `systemd/.config/systemd/user/swaync.service.d/niri-only.conf` | swaync'in KDE/GNOME'da başlamasını engeller |
| `systemd/.config/systemd/user/mako.service.d/niri-only.conf` | mako'yu yalnızca niri'de ve yalnızca swaync kurulu değilse başlatır |
| `systemd/.config/systemd/user/app-…@autostart.service.d/not-in-niri.conf` | KDE'den gelen bazı autostart programlarının niri'de **başlamaması** (bkz. [Notlar](#notlar)) |
| `autostart/.config/autostart/nm-applet.desktop` | Wi-Fi tepsi simgesi, yalnızca niri'de |
| `autostart/.config/autostart/blueman.desktop` | Bluetooth tepsi simgesi, yalnızca niri'de |
| `bin/.local/bin/osd` | Ses/mikrofon/parlaklık tuşları: değeri değiştirir, üst ortada gösterge açar |
| `bin/.local/bin/lock-screen` | Ekranı kilitler (zaten kilitliyse bir şey yapmaz) |
| `bin/.local/bin/layout-mode` | Otomatik ızgara düzeni (AUTO) ve elle düzen (FREE), bkz. [Otomatik düzen](#otomatik-düzen-auto--free) |
| `bin/.local/bin/calendar-popup` | Saate tıklayınca açılan takvim (GTK3 + gtk-layer-shell) |
| `bin/.local/bin/media-popup` | Medya başlığına tıklayınca açılan küçük kontrol kutusu (GTK3 + gtk-layer-shell) |
| `bin/.local/bin/quick-settings` | Hızlı ayarlar panelindeki düğmelerin komutları (Wi-Fi, Bluetooth, güç profili, oturum…) |
| `bin/.local/bin/bar-status` | Waybar'ın gerektiğinde görünen göstergeleri: MIC/CAM/SCR, MIC off, FAIL, CPU/MEM/TEMP, VPN, ECO/PERF |
| `bin/.local/bin/awake` | Ekranı açık tutar (kafein): boşta kilit ve ekran kapatma durur |
| `bin/.local/bin/night-light` | Gece ışığını açar/kapatır (`night-light.service`) |
| `systemd/.config/systemd/user/night-light.service` | Gece ışığı: wlsunset ile sıcak ekran rengi. Oturum açılışında başlamaz. |
| `systemd/.config/systemd/user/layout-mode.service` | `layout-mode`'u niri oturumunda arka planda çalıştırır |
| `flatpak/brave-flags.conf` | Brave'in niri'de de KWallet kullanması (bkz. [Notlar](#notlar)) |
| `wallpapers/` | Duvar kağıtların. İçindekiler git'e girmez (bkz. [Duvar kağıdı](#duvar-kağıdı)). |
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
        │    niri-polkit · theme-apply → waybar · swaync · swaybg · swayidle · layout-mode
        │    (mako: yalnızca swaync kurulu değilse)
        └─ XDG autostart (OnlyShowIn=niri olanlar + KDE'de de açılanlar)
             nm-applet · blueman · KDE Connect · …
             (Cisco Secure Client, Xwayland Video Bridge, imsettings/IBus niri'de başlamaz)
```

Bu servislerin hiçbiri KDE oturumunda başlamaz. Durumlarını görmek için:

```bash
systemctl --user status niri-polkit theme-apply waybar swaync swaybg swayidle layout-mode
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

Gelen presetler: **sakura** (varsayılan), kanagawa, rose-pine, rose-pine-dawn, catppuccin-mocha,
catppuccin-latte, gruvbox, tokyo-night, nord, everforest.

**Seçim kalıcıdır** (`~/.local/state/theme/state.json`). Her oturum açılışında yeniden uygulanır.

### Ne anında güncellenir?

| Bileşen | Nasıl |
|---|---|
| niri (odak halkası, arka plan, overview) | Dahil ettiği dosyayı kendisi izler, anında |
| Waybar | `@import` ettiği renk dosyasını kendisi izler (`reload_style_on_change`), anında |
| swaync (bildirimler, panel) | `swaync-client --reload-css`, anında |
| mako (yedek) | `makoctl reload`, anında |
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

1. Görselleri `~/dotfiles/wallpapers/` içine koy. Klasör yoksa: `mkdir -p ~/dotfiles/wallpapers`
2. `theme wallpaper <dosya-adı>` komutunu çalıştır. Sadece dosya adı yazarsan bu klasörde aranır; tam yol da verebilirsin.

| İstek | Komut |
|---|---|
| Renkleri görselden üret | `theme wallpaper x.jpg` |
| Görseli değiştir, renkler kalsın | `theme wallpaper x.jpg --keep-colors` |
| Görseli kaldır (temanın düz arka plan rengi) | `theme wallpaper none` |
| Preset'e geç (görsel kalır) | `theme preset rose-pine` |

**Görseller git'e girmez.** `.gitignore` bu klasörde yalnızca boş `.gitkeep` dosyasını izler;
klasör yeni bir klonda da hazır olur ama içi boş gelir. Bu yüzden görsellerin dotfiles'la birlikte
yedeklenmez: başka bir bilgisayara geçerken `wallpapers/` klasörünü ayrıca kopyala. Kayıtlı tema
görselin tam yolunu tutar. Görsel silinir ya da taşınırsa bir sonraki girişte arka plan düz renge
döner; ondan üretilmiş renkler kalır.

---

## Otomatik düzen: AUTO / FREE

niri pencereleri sağa doğru uzayan bir şeride dizer; sığmayanlar ekranın dışında bekler. Bunun
yerine ekranı dolduran sabit bir ızgara istediğin için `layout-mode` adlı küçük bir servis var:
niri'nin olaylarını dinler, pencereleri niri'nin IPC komutlarıyla doğru sütuna taşır ve
genişliklerini ayarlar. niri bunu kendisi yapmıyor, yani bu bizim eklentimiz.

İki mod var. Paneldeki küçük etiket hangisinde olduğunu gösterir. **`Super+T`**, etikete
tıklamak ya da hızlı ayarlar panelindeki **Auto layout** düğmesi modu değiştirir. Her girişte
AUTO ile başlar.

**AUTO (varsayılan):** her workspace'teki döşeli pencereler en fazla iki sütuna dizilir.

| Pencere sayısı | Düzen |
|---|---|
| 1 | Tam ekran |
| 2 | Yan yana, %50 / %50 |
| 3 | Solda bir pencere tam yükseklikte, sağda iki pencere alt alta |
| 4 | 2×2: ekran bir dikey ve bir yatay çizgiyle dört eşit parçaya bölünür |
| 5 ve fazlası | İki sütuna dengeli: 5'te solda 3 sağda 2, 6'da 3/3, 7'de 4/3… |

- Sütunlar eşit genişlikte, bir sütundaki pencereler eşit yükseklikte.
- **Sıra** okuma sırasıdır: önce sol sütun yukarıdan aşağı, sonra sağ sütun. Yeni açılan pencere
  sona, yani sağ alta eklenir. Başka workspace'ten gelen ya da `Super+V` ile döşeliye dönen
  pencere de öyle.
- Bir pencere kapanınca, başka workspace'e gidince ya da yüzen olunca düzen kalanlarla yeniden
  kurulur.
- **Yer değiştirmek:**
  - `Super+Ctrl+←/→` (ya da `H`/`L`): odaktaki pencere, yandaki sütunda aynı satırdaki pencereyle
    yer değiştirir. O yönde sütun yoksa pencere yandaki monitöre gider.
  - `Super+Ctrl+↑/↓` (ya da `K`/`J`): sütun içinde üstteki ya da alttakiyle yer değiştirir.
  - Fareyle: `Super` + sol tıkla pencereyi başka bir yere bırak. Düzen, bıraktığın yere göre
    yeniden kurulur.
- **Boyutlandırmak:**
  - Sütun genişliğini değiştirince (`Super` + sağ tık, `Super+R`, `Super+-` / `Super++`) diğer
    sütun kalan alana sığar. Diğer sütun en az 200 px kalır; daha fazla büyütürsen sütun geri
    çekilir.
  - Pencere yüksekliğini değiştirince (`Super+Shift+-` / `Super+Shift++`, sağ tıkla dikey sürükle)
    aynı sütundakileri niri kendisi sığdırır.
  - Elle verdiğin boyutlar, düzen yeniden kurulana kadar kalır: pencere açılıp kapanınca ya da
    yer değiştirince her şey yine eşitlenir.
- `Super+F` (sütunu büyüt) ve `Super+Shift+F` (tam ekran) bilerek taşırır; servis bunlara
  karışmaz.
- Sütuna katma/çıkarma (`Super+,` / `Super+.`) ve sütunu başa/sona taşıma
  (`Super+Ctrl+Home/End`) ızgarayı bozar; servis hemen okuma sırasına göre yeniden kurar. Bunlar
  FREE'de işe yarar.

**FREE:** servis düzenlemeyi bırakır; pencereler döşeli kalır, hiçbiri yüzen olmaz.

- Hiçbir şey yerinden oynamaz. Boyutu ve sırayı klavyeyle ya da `Super` + sağ tık / sol tık ile
  elle ayarlarsın.
- niri'nin olağan davranışı geçerlidir: yeni pencere odaktakinin sağına açılır, sığmayanlar
  ekranın dışında bekler.
- `Super+Ctrl+←/→` FREE'de sütunu taşır (niri'nin varsayılanı).
- Tek bir pencereyi yüzdürmek için `Super+V` (iki modda da).
- AUTO'ya dönünce ızgara mevcut okuma sırasıyla yeniden kurulur; elle verdiğin boyutlar sıfırlanır.

**Bilinen sınırlar:**

- **Yeniden kurma:** niri'de "şu pencereyi şu sütunun şu satırına koy" diye bir komut yok.
  - Servis pencereleri "sütuna kat / sütundan çıkar" komutlarıyla adım adım taşır. En kısa adım
    sırasını kendisi hesaplar ve hepsini tek seferde gönderir.
  - Yeni pencere bir an niri'nin koyduğu yerde görünür, ~0,15 sn sonra kısa bir animasyonla
    yerine kayar.
- **Çok pencere:** 7–8 pencerede satırlar epey alçalır. Belli bir yüksekliğin altına inmeyen
  uygulamalar sütuna sığmayabilir.
- **En küçük genişlik:** Bazı uygulamalar (ör. Brave) belli bir genişliğin altına inmez. O sütun
  o kadar geniş kalır, diğeri kalan alanı alır. İkisi de sığmıyorsa taşma önlenemez.
- **Görünüm hizalaması:** niri'de görünümü doğrudan ayarlayan bir komut yok. Genişlikler
  değişince görünüm kaymış kalabiliyor (solda boşluk, sağda kesik pencere). Servis bunu,
  bir anlığına ilk ve son pencereye odaklanıp sana geri dönerek düzeltir.
  - Alt+Tab listesi bundan etkilenmez, çünkü 750 ms bekleyerek ekliyor.
  - Bu birkaç milisaniyede bastığın bir tuş başka pencereye gidebilir.
  - Fareyle boyutlandırdıktan sonra hizalama, fare 1 sn durunca yapılır. Sürüklerken 1 sn'den
    uzun beklersen sürükleme biter; tekrar tutman gerekir.
- **Gizli workspace'ler:** Görünmeyen bir workspace'te düzen hemen kurulur ve odak değişmez.
  Görünüm hizalaması o workspace'e geçince yapılır.

**Komutlar:**

```bash
layout-mode toggle            # AUTO ↔ FREE (Super+T ile aynı)
layout-mode auto | free       # belirli moda geç
layout-mode status            # auto / free / off (servis çalışmıyorsa)
layout-mode move left|right   # AUTO: yandakiyle yer değiştir, FREE: sütunu taşı (Super+Ctrl+←/→)
systemctl --user status layout-mode     # servis durumu ve hataları
systemctl --user stop layout-mode       # bu oturum için kapat (pencereler olduğu gibi kalır)
```

- **Tamamen kapatmak:**
  - `install.sh` içindeki `NIRI_SERVICES` listesinden `layout-mode.service`'i sil.
  - `systemctl --user remove-wants niri.service layout-mode.service` çalıştır.
  - Waybar'dan etiketi kaldırmak için `config.jsonc`'deki `"custom/layout"` girdisini sil.
  - Servis kapalıyken `Super+Ctrl+←/→` niri'nin olağan sütun taşımasını yapar.
- **Ayrıntılı günlük:** `systemctl --user edit layout-mode` → `[Service]` altına
  `Environment=LAYOUT_MODE_DEBUG=1`, sonra `systemctl --user restart layout-mode` ve
  `journalctl --user -u layout-mode -f`.
- **Ayarlar:**
  - Bekleme süreleri ve en küçük sütun genişliği (200 px) scriptin başındaki sabitlerde.
  - Pencerelerin sütunlara dağılımı `grid()` fonksiyonunda (ör. 3 pencerede soldaki tek pencere).
  - niri'deki `gaps` değerini `layout.kdl`'den kendisi okur.
  - `./check.sh` planlayıcıyı rastgele düzenlerle dener (`layout planner`).

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
| `Super+T` | Düzen modu: AUTO (ızgara) ↔ FREE (elle), bkz. [Otomatik düzen](#otomatik-düzen-auto--free) |

### Odak ve taşıma

| Kısayol | İş |
|---|---|
| `Super+←/→` veya `Super+H/L` | Sol/sağ sütuna odaklan. Kenardaysa yandaki monitöre geçer. |
| `Super+↑/↓` veya `Super+K/J` | Sütun içinde üst/alt pencere |
| `Super+Home` / `Super+End` | İlk / son sütun |
| `Super+Ctrl+←/→` veya `Super+Ctrl+H/L` | AUTO: odaktaki pencereyi yandaki sütundaki komşusuyla yer değiştir. FREE: sütunu sola/sağa taşı. Kenardaysa yandaki monitöre. |
| `Super+Ctrl+↑/↓` veya `Super+Ctrl+K/J` | Pencereyi sütun içinde üstteki/alttaki ile yer değiştir |
| `Super+Ctrl+Home` / `Super+Ctrl+End` | Sütunu en başa / sona taşı |

### Fare

Ayarı: `niri/.config/niri/input.kdl`.

| Hareket | İş |
|---|---|
| Fareyi bir pencerenin üstüne getir | O pencere odaklanır, ama yalnızca tamamen görünüyorsa. Kısmen görünen bir pencere odak almaz ve görünüm kaymaz. |
| Pencereye tıkla | Odaklanır; kısmen görünüyorsa görünüm ona kayar |
| `Super` + sol tıkla sürükle | Pencereyi taşı. Sürüklerken sağ tık: yüzen ↔ döşeli. Ekran kenarı duvar gibidir, görünüm kaymaz. |
| `Super` + sağ tıkla sürükle | Pencereyi boyutlandır (aşağıya bak). AUTO modunda diğerleri kalan alana sığar. |
| `Super` + sağ çift tık, pencerenin sol/sağ kısmında | Sütun tam genişliğe yayılır |
| `Super` + sağ çift tık, pencerenin üst/alt kısmında | Pencere yüksekliği otomatiğe döner |
| `Super` + orta tuşla (tekerleğe basılı) sürükle | Yatay: görünümü kaydır · dikey: workspace değiştir |
| İmleci sol üst köşeye götür | Genel bakış (overview) |

**Boyutlandırma (`Super` + sağ tık sürükle):** niri pencereyi 3×3'lük bir ızgaraya böler ve
imlecin olduğu yere göre hangi kenarın taşınacağını seçer: sol/sağ üçte bir sütun genişliğini,
üst/alt üçte bir pencere yüksekliğini değiştirir, köşeler ikisini birden. Tam ortadan tutarsan
hiçbir şey olmaz. Sütunun en üstteki penceresinde **üst** kenar hareket etmez; yüksekliği alt
kenardan değiştirirsin. Yüksekliği eski haline getirmek için `Super+Ctrl+R`.

**Kenarından tutarak boyutlandırma neden yok:** niri pencerelerin etrafına kendisi tutulacak bir
kenar koymuyor; kenardan boyutlandırma, uygulamanın kendi çizdiği çerçeveyle (CSD) çalışır.
`config.kdl`'deki `prefer-no-csd` uygulamalardan bu çerçeveyi çizmemelerini istediği için kenar
tutamakları da kayboluyor (niri belgelerinde de böyle yazıyor). `prefer-no-csd`'yi kaldırmak
da tam çözüm değil: GTK uygulamalarına tutamaklar geri gelir ama foot, Qt uygulamaları ve Brave
kendi başlık çubuklarını çizer, görünüm uygulamadan uygulamaya değişir ve bazılarında yine
tutamak olmaz. Bu yüzden `Super` + sağ tık her pencerede aynı çalışan yol.

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
| `Super+N` | Hızlı ayarlar ve bildirim paneli (aç/kapa) |
| `Super+Shift+N` | Açık bildirimleri gizle (panelde kalırlar) |
| `Super+Ctrl+N` | Rahatsız Etme aç/kapa |
| `Super+M` | Medya kontrol kutusu (aç/kapa; sağ üstte açılır) |

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
| `AUTO` / `FREE` | Tıkla: düzen modunu değiştir (`Super+T` ile aynı). `----` = servis çalışmıyor |
| `AWAKE` · `NIGHT` · `ECO` / `PERF` | Yalnızca açıkken görünür. Tıkla: kapat (ECO/PERF → balanced) |
| `VPN` | Yalnızca VPN bağlıyken. Üstüne gel: hangi bağlantı |
| Saat | Tıkla: takvim. Tekrar tıkla, `Esc`'e bas ya da dışarı tıkla: kapanır. Üstüne gel: tam tarih. |
| `\|<` `>` / `\|\|` `>\|` ♪ başlık | Yalnızca bir çalar açıkken görünür. Önceki · oynat/duraklat · sonraki. Başlığa tıkla: kontrol kutusu (aşağıda), orta tık: önceki, sağ tık: sonraki. |
| `MIC CAM SCR` (kırmızı) | Mikrofon / kamera / ekran paylaşımı kullanılırken. Üstüne gel: hangi uygulama |
| `FAIL n` | Bir servis çöktüğünde. Üstüne gel: adları · tıkla: ayrıntılar (terminalde) |
| `CPU` `MEM` `TEMP` | Yalnızca 15 sn boyunca yüksek kalırsa. Tıkla: GNOME System Monitor |
| `MIC off` | Mikrofon sessizdeyken. Tıkla: aç |
| `VOL` | Tıkla: hızlı ayarlar · orta tık: pavucontrol · sağ tık: sessiz · tekerlek: ses ±%5 |
| `LCD` | Tıkla: hızlı ayarlar · tekerlek: parlaklık ±%5 (parlaklık tuşları gibi gösterge açar) |
| `NET` | Tıkla: hızlı ayarlar · sağ tık: ağ bağlantıları penceresi |
| `BAT` / `AC` | Tıkla: hızlı ayarlar |
| `MSG` / `DND` | `MSG`: geçmiş boş · `MSG •`: bildirim var · `DND`: Rahatsız Etme açık. Tıkla: panel · sağ tık: Rahatsız Etme aç/kapa |
| Tepsi | Wi-Fi (nm-applet), Bluetooth (blueman) ve diğer uygulamalar |

**Tepsi simgeleri ve açık temalar:** Tepsi simgeleri, KDE'de seçili simge temasından gelir
(şu an Colloid). Colloid bu simgeleri sabit açık gri çiziyor; açık bir temada (rose-pine-dawn,
catppuccin-latte, açık duvar kağıdı) zeminde kayboluyorlardı. Bu yüzden açık temalarda tepsi
koyu küçük bir zeminin üstünde durur; koyu temalarda zemin yoktur. Zemin rengi temadan gelir
(`@tray`, `theme` üretir). KDE'de koyu simgeli bir tema seçersen koyu temalarda da görünür kalır.

---

## Waybar modülleri

Hangi modülün nerede durduğu `waybar/.config/waybar/config.jsonc` içindeki üç listede tanımlı:

```jsonc
"modules-left":   ["niri/workspaces", "custom/layout",
                   "custom/awake", "custom/night", "custom/power", "custom/vpn", "niri/window"],
"modules-center": ["clock"],
"modules-right":  ["custom/privacy", "custom/failed", "custom/system", "group/media", "tray",
                   "custom/mic", "wireplumber", "backlight", "network", "battery", "custom/notifications"],
```

Panel ekranın üstüne yapışık ve tam genişlikte; kenar boşluğu ve yuvarlak köşe yok, altta ince
bir çizgi var (`style.css` → `window#waybar`).

- **Takvim** (`clock` → `on-click`): `calendar-popup` küçük bir GTK penceresi açar. Ay ve gün
  adları her zaman İngilizce. Dışarı tıklamayı yakalamak için ekranı kaplayan saydam bir katman
  açar; boş masaüstüne tıklamak da kapatır. Renkleri temadan gelir (`themes/templates/panel.css`).
  Açılması ~0,3 sn sürer (Python + GTK her seferinde yeniden başlar).
- **Medya** (`group/media`): üç düğme (`custom/media-prev`, `-play`, `-next`) ve başlık (`mpris`).
  - Düğmeler `playerctl --follow` ile durumu izler. Çalar kapanınca playerctl boş satır yazar ve
    Waybar düğmeleri gizler.
  - Hepsi en son kullanılan çaları hedefler: Waybar'ın `mpris` modülü playerctld'yi izler,
    playerctl da playerctld çalışırken aynı çaları seçer.
  - Panelin fontunda medya simgeleri olmadığı için düz metin kullanılıyor (`|<`, `>`, `||`, `>|`).
  - Bar kalabalıklaşınca önce başlık kısalır (`…`), NET/VOL gibi yazılar değil (`max-length`).
- **Medya kutusu** (`mpris` → `on-click`, ya da `Super+M`): `media-popup` başlığın hemen altında
  küçük, yuvarlak bir kutu açar (Dynamic Island benzeri): kapak, başlık, sanatçı, çalar adı,
  sürüklenebilir ilerleme çubuğu, önceki · oynat/duraklat · sonraki.
  - Klavye: `Space` oynat/duraklat, `←` `→` 5 sn sar, `N` sonraki, `P` önceki, `Esc` kapat.
  - Kapanır: dışarı tıklayınca, `Esc`, aynı yere tekrar tıklayınca, ya da çalar kapanınca.
    Çalan bir şey yoksa sağ üstte kısa bir "Nothing playing" yazısı çıkar.
  - Barla aynı çaları gösterir (playerctld'nin en son kullanılanı).
  - Kapak: yerel dosya doğrudan okunur; internetteki kapak `~/.cache/media-popup`'a indirilir
    (en fazla 50 dosya tutulur). Kapak yoksa `♪`.
  - `--at-pointer`: imlecin altına ortalar (Waybar böyle çağırır); onsuz sağ üstte açılır.
  - Gölgeyi niri çizer (`rules.kdl` → `layer-rule`, `media-popup`). Renkler `panel.css`'ten.
  - Açılırken bardan aşağı kayar. Pencere baştan tam boyda açılır: niri, büyüyen bir katman
    penceresine yeni kare vermediği için boyu değişen pencerede animasyon donuyordu.

### Gerektiğinde görünen göstergeler

Normal bir anda bar eskisi gibi görünür. Aşağıdakiler yalnızca bir şey olduğunda çıkar, sonra
kendiliğinden kaybolur. Solda **senin açtığın modlar**, sağda **o an olup bitenler** durur.
Sağ yarı zaten dolu olduğu için modlar solda; orada pencere başlığı gerekirse kısalır.

| Gösterge | Ne zaman | Nasıl anlıyor |
|---|---|---|
| `AWAKE` | Hızlı ayarlar → Stay awake açıkken | `awake` scripti; swayidle bu sırada kilitlemez, ekranı kapatmaz |
| `NIGHT` | Hızlı ayarlar → Night light açıkken | `night-light.service` (wlsunset) çalışıyor mu |
| `ECO` / `PERF` | Güç profili balanced değilken | tuned-ppd'nin D-Bus sinyali (anında) |
| `VPN` | Trafik bir VPN'den geçerken | Cisco (`cscotun*`), NetworkManager VPN/WireGuard, varsayılan rota. **Tailscale** hep açık olduğu için yalnızca exit node kullanılırken sayılır. |
| `MIC CAM SCR` | Mikrofon, kamera ya da ekran paylaşımı kullanılırken | Mikrofon: PipeWire kayıt akışları (pavucontrol'ün seviye göstergeleri ve hoparlör dinleyenler sayılmaz). Kamera: `/dev/video*`'yu açık tutan süreçler. Ekran: `niri msg casts`. 2 sn'de bir bakar. |
| `FAIL n` | Bir systemd servisi (kullanıcı ya da sistem) çöktüğünde | systemd'nin D-Bus sinyali. Silmek için: `systemctl --user reset-failed` |
| `CPU` `MEM` `TEMP` | CPU %80, bellek %85, sıcaklık 85 °C üstünde **15 sn kalırsa** | 5 sn'de bir ölçer; kısa sıçramalarda yanıp sönmez. Eşikler `bar-status` başında. |
| `MIC off` | Mikrofon sessizdeyken (görüşmelerde hatırlatma) | `pactl subscribe` (anında) |

Hepsi `bar-status`, `awake` ve `night-light` scriptlerinden gelir. Modül boş metin yazınca Waybar
onu gizler ve yer kaplamaz. Kurallar `./check.sh` içinde örnek verilerle sınanır
(`bar-status selftest`).

**Neden Waybar'ın kendi modülleri değil (Waybar 0.14'te test edildi):**

- `wireplumber` (mikrofon için) boş format'ta gizlenmiyor, boş bir kutu olarak yer kaplıyor.
- `systemd-failed-units` bir kez gizlendikten sonra bir daha görünmüyor.
- `cpu` / `temperature` anlık değere bakıyor. Bu laptop kısa yüklerde hemen 85 °C'yi geçtiği için
  gösterge yanıp sönüyordu.
- `privacy` metin değil simge gösteriyor ve kamerayı yalnızca PipeWire üzerinden görüyor;
  tarayıcılar kamerayı çoğunlukla doğrudan `/dev/video*` ile açar.

- **Kaldırmak:** Listeden sil.
- **Yer değiştirmek:** Listeler arasında taşı.
- **Eklemek:** Listeye adını yaz ve altına ayar bloğunu ekle. Örnek, disk doluluğu:

  ```jsonc
  "modules-right": [..., "disk", "wireplumber", ...],
  "disk": {
      "path": "/",
      "format": "<span alpha='55%'>DSK</span> {percentage_used}%"
  },
  ```

  Aralık için `style.css`'teki `#wireplumber, #backlight, #network, #battery { padding: … }`
  listesine `#disk` ekle.

Modüllerin bütün seçenekleri man sayfalarında: `man waybar-clock`, `man waybar-battery`,
`man waybar-niri-workspaces`… Liste için: `ls /usr/share/man/man5 | grep waybar`.

Ne zaman ne yapılır:

- `style.css` ya da tema renkleri değiştiğinde Waybar kendisi yenilenir (`reload_style_on_change`).
- `config.jsonc`'yi değiştirdiysen: `systemctl --user restart waybar`.
- **`reload` ya da SIGUSR2 kullanma.** Waybar 0.14 bu yolla eski barları kapatmadan yenilerini
  açıyor, tepsi simgeleri de yeni barlara gelmiyor.

Panelin renkleri `style.css`'e değil temaya ait; `@accent`, `@fg` gibi adlar kullanılır.

---

## Hızlı ayarlar ve bildirimler

Bildirimleri ve hızlı ayarlar panelini **SwayNotificationCenter** (swaync, resmi Fedora reposu)
gösterir. Yalnızca niri oturumunda başlar; KDE'nin bildirimlerine dokunmaz.

**Paneli açmak:** Waybar'da `VOL`, `LCD`, `NET`, `BAT` ya da `MSG`'ye tıkla ya da `Super+N`.
Kapatmak: tekrar tıkla, `Esc`'e bas ya da panelin dışına tıkla.

Panelde yukarıdan aşağıya:

| Bölüm | Ne yapar |
|---|---|
| `Settings ▼` | Sound (pavucontrol) · Network (nm-connection-editor) · Bluetooth (blueman-manager) |
| `Lock` | Ekranı kilitler |
| `Power ▼` | Log out · Restart · Shut down. fuzzel'de onay ister; listede ilk sıradaki `Cancel`, yani Enter'a hemen basmak iptal eder. |
| Wi-Fi | Aç/kapa (`nmcli radio wifi`) |
| Bluetooth | Aç/kapa (`bluetoothctl power`; rfkill ile kapatılmışsa önce onu kaldırır) |
| Do not disturb | Açıkken bildirimler açılır pencerede görünmez, yalnızca panelde birikir. Waybar'da `DND`. |
| Power saver / Performance | Güç profili (tuned-ppd üzerinden, şifre istemez). İkisi de kapalıysa Balanced. |
| Auto layout | AUTO ↔ FREE, `Super+T` ile aynı (bkz. [Otomatik düzen](#otomatik-düzen-auto--free)) |
| Microphone | Mikrofonu sessize al / aç. Sessizken Waybar'da `MIC off`. |
| Night light | Ekran renklerini sıcak tona çeker (wlsunset, 4000 K). Açıkken gün içinde de sıcak kalır; oturumdan çıkınca kapanır. Waybar'da `NIGHT`. wlsunset kurulu değilse kurulum komutunu bildirimle söyler. |
| Stay awake | Ekranı açık tutar: boşta kilit ve ekran kapatma durur. Uyku öncesi kilit yine çalışır. Oturumdan çıkınca kapanır. Waybar'da `AWAKE`. |
| `VOL`, `LCD` | Ses ve laptop ekranı parlaklığı kaydırıcıları |
| Medya | Bir çalar açıksa: başlık, önceki · oynat/duraklat · sonraki |
| Notifications | Bildirim geçmişi. Bildirime tıkla: uygulamasını açar · `×`: kapat · `Clear`: hepsini sil |

**Açılır bildirimler:**

- Sağ üstte, panelin hemen altında görünürler. Normal bildirim 6 sn, düşük öncelikli 4 sn kalır;
  kritik olanlar sen kapatana kadar durur.
- Kenar rengi önceliği gösterir: soluk = düşük, vurgu = normal, kırmızı = kritik.
- Aynı uygulamanın bildirimleri panelde gruplanır.
- Ses/parlaklık göstergesi (`osd`) de bir bildirimdir ama geçmişe yazılmaz. Artık üst ortada
  değil, diğer bildirimlerle birlikte sağ üstte çıkar; swaync bütün bildirimleri tek yerde gösteriyor.

**Bilinen sınırlar:**

- Hızlı ayarlar ve bildirim geçmişi **aynı panelde**. swaync tek panel kullanıyor; GNOME'daki
  gibi iki ayrı menü yok.
- Panelde **Wi-Fi ağ listesi yok**. Ağ seçmek için tepsideki Wi-Fi simgesi (nm-applet) ya da
  `Settings ▼` → Network.
- Düğmelerin açık/kapalı hali panel açılırken okunur. Panel açıkken Power saver'dan doğrudan
  Performance'a geçersen Power saver düğmesi panel kapanıp açılana kadar yanık görünür. Wi-Fi'yi
  başka yerden değiştirirsen de düğme bir sonraki açılışta güncellenir.
- Parlaklık kaydırıcısı yalnızca laptop ekranını (`intel_backlight`) ayarlar; harici monitörler
  değişmez. Ses kaydırıcısı varsayılan çıkışı ayarlar; çıkış seçmek için `Settings ▼` → Sound.
- Paneldeki düğme yazıları düz metin, çünkü panelin fontunda simge yok.
- Night light'ın sıcaklığı `night-light.service` içinde (`-t 4000`). Daha sıcak için düşür
  (ör. 3500); `-T` her zaman bir fazlası olsun. Sonra `systemctl --user daemon-reload` ve
  düğmeyi kapatıp aç.

**Ayar dosyaları:**

- `swaync/.config/swaync/config.json`: panelin bölümleri, düğmeler, zaman aşımları.
  - Seçenekler: `man 5 swaync`, şema: `/etc/xdg/swaync/configSchema.json`. `./check.sh`
    config'i bu şemaya göre doğrular.
  - Değiştirdikten sonra: `swaync-client --reload-config`.
  - JSON yorum satırı kabul etmediği için açıklamalar bu README'de.
- `swaync/.config/swaync/style.css`: görünüm. Renkler temadan gelir
  (`themes/templates/swaync.css`); tema değişince `theme` swaync'e yeni renkleri kendisi okutur.
  Elle değiştirdikten sonra: `swaync-client --reload-css`.
- `bin/.local/bin/quick-settings`: düğmelerin komutları. Elle de çalışır, ör.
  `quick-settings wifi status`, `quick-settings bluetooth status`.
- **Düğme eklemek:** `config.json` → `"buttons-grid"` → `"actions"` listesine ekle:

  ```json
  { "label": "My toggle", "type": "toggle",
    "command": "sh -c '...'", "update-command": "sh -c '... echo true ya da false'" }
  ```

  swaync komutları kabuk olmadan çalıştırır; `~` ve `$HOME` için `sh -c` şart. Aç/kapa
  düğmesinde tıklamadan sonraki hal `SWAYNC_TOGGLE_STATE` (`true`/`false`) değişkeninde gelir.

**Komutlar:**

```bash
swaync-client -t              # paneli aç/kapa
swaync-client -d              # Rahatsız Etme aç/kapa
swaync-client -C              # bütün bildirimleri sil
systemctl --user status swaync
journalctl --user -b -u swaync
```

**mako (yedek):** Eskiden bildirimleri mako gösteriyordu. Config'i repoda duruyor. mako artık
yalnızca swaync kurulu değilse başlıyor (`mako.service.d/niri-only.conf` →
`ConditionPathExists=!/usr/bin/swaync`). swaync'i kaldırırsan bir sonraki girişte bildirimler
mako'yla eskisi gibi görünür; panel ve `MSG` modülü görünmez, `Super+N` bir şey yapmaz.

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
| Bildirimler ve hızlı ayarlar paneli | `swaync/.config/swaync/style.css` → `font-family`, `font-size` |
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
  sonsuz uzanan bir şerit; sığmayan sütunlar ekranın kenarının ötesinde bekler. Bu, kapak açık
  ya da kapalı fark etmeden böyledir. AUTO modunda ([Otomatik düzen](#otomatik-düzen-auto--free))
  servis sütunları ekrana sığdırır; FREE modunda ya da servis kapalıyken şerit niri'nin
  bildiği gibi çalışır. Gezinmek için `Super+H/L`, `Super+Home/End` ya da `Super+O` (genel bakış). Pencere sürüklerken ekran kenarında görünümün kayması kapalı
  (`input.kdl` → `dnd-edge-view-scroll`, `trigger-width 0`). niri varsayılanına dönmek için o bloğu sil.
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
- **Stay awake** (hızlı ayarlar ya da `awake on`): kilit ve ekran kapatma, sen kapatana ya da
  oturumdan çıkana kadar durur. Waybar'da `AWAKE` görünür; tıklayınca kapanır. Kapağı kapatınca
  ekran yine kilitlenir (uyku öncesi kilit `awake`'ten etkilenmez).

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
journalctl --user -b -u layout-mode   # otomatik düzen
journalctl --user -b -u swaync        # bildirimler ve hızlı ayarlar paneli
systemctl --user status waybar swaync swaybg swayidle theme-apply niri-polkit layout-mode
systemctl --user restart waybar       # panel kaybolduysa
```

**Pencereler garip davranıyorsa:** `Super+T` ile FREE'ye geç ya da
`systemctl --user stop layout-mode` ile servisi bu oturum için kapat. niri o zaman kendi
bildiği gibi çalışır.

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
    waybar fuzzel SwayNotificationCenter mako swaylock swayidle swaybg \
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
  - `swaync.service.d/niri-only.conf` ve `mako.service.d/niri-only.conf`: swaync ve mako
    paketleri, bildirim gönderilince D-Bus üzerinden kendiliğinden başlayabilecek şekilde geliyor.
    Bu dosyalar KDE'de ikisinin de tetiklenip Plasma'nın bildirimlerinin yerine geçmesini
    engelliyor. Bu yüzden kullanıcı düzeyinde bir D-Bus geçersiz kılması **eklenmedi**: o,
    Plasma'nın kendi bildirim servis dosyasını da gölgelerdi.
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
- **Sol üst köşe** niri'de genel bakışı açar. Kapatmak için `input.kdl`'deki `gestures`
  bloğunda hazır duran `hot-corners { off }` satırlarının başındaki `//` işaretlerini sil.
  İkinci bir `gestures` bloğu açma, aynı dosyada mevcut olanı kullan.
- **Güç tuşu** niri'de bilgisayarı kapatmaz, uyutur (niri varsayılanı).
- niri belgeleri: <https://github.com/niri-wm/niri/wiki>.
