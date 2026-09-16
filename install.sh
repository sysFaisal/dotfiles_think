#!/bin/bash
# mydotfiles_v2 install - untuk distro/OS baru (KECUALI ly-dm, itu manual via system/restore-ly.sh)
# Cara pakai:
#   ./install.sh                 -> copy dotfiles saja, cek dependensi
#   ./install.sh --install-deps  -> copy + coba install paket yang hilang
#                                  (pacman/apt/dnf/zypper/xbps-void)
set -u

MYDOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BACKUP_TS="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="$HOME/Backup_install_$BACKUP_TS"
INSTALL_DEPS=false
[[ "${1:-}" == "--install-deps" ]] && INSTALL_DEPS=true

log()  { echo -e "\e[34m[INFO]\e[0m $1"; }
ok()   { echo -e "\e[32m[OK]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }
err()  { echo -e "\e[31m[ERR]\e[0m $1"; }

backup_item() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  local rel="${target#$HOME/}"
  [[ "$rel" == "$target" ]] && rel="_root_$(basename "$target")"
  mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
  mv "$target" "$BACKUP_DIR/$rel"
  warn "backup $target -> $BACKUP_DIR/$rel"
}

copy_dir() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || { warn "skip (no src): $src"; return 0; }
  [[ -e "$dst" ]] && backup_item "$dst"
  mkdir -p "$dst"
  cp -rf "$src"/. "$dst"/
  log "copy $src/ -> $dst/"
}

copy_file() {
  local src="$1" dst="$2"
  [[ -f "$src" ]] || { warn "skip (no file): $src"; return 0; }
  mkdir -p "$(dirname "$dst")"
  [[ -e "$dst" ]] && backup_item "$dst"
  cp -f "$src" "$dst"
  log "copy $src -> $dst"
}

# merge dir tanpa backup dest (untuk wallpaper: jangan timpa yg sudah ada)
merge_dir_noclobber() {
  local src="$1" dst="$2"
  [[ -d "$src" ]] || { warn "skip (no src): $src"; return 0; }
  mkdir -p "$dst"
  cp -rn "$src"/. "$dst"/
  log "merge $src/ -> $dst/ (no-clobber)"
}

echo "=== mydotfiles_v2 install ==="
echo "src : $MYDOT"
echo "backup ke: $BACKUP_DIR"
echo "install-deps: $INSTALL_DEPS"
echo "(ly-dm di-SKIP, pakai: sudo bash system/restore-ly.sh secara manual)"
mkdir -p "$BACKUP_DIR"

# folder wajib (termasuk target wallpaper biar selector langsung jalan)
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share/fonts" \
  "$HOME/hakuspace-control" \
  "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots" \
  "$HOME/Videos/Wallpapers/Preview"

# 1. common/config/* -> ~/.config/* (hanya direktori, file dotfiles di-handle di bawah)
if [[ -d "$MYDOT/common/config" ]]; then
  for srcdir in "$MYDOT"/common/config/*/; do
    [[ -d "$srcdir" ]] || continue
    app="$(basename "$srcdir")"
    copy_dir "$srcdir" "$HOME/.config/$app"
  done
fi

# 2. file khusus
[[ -f "$MYDOT/common/config/gtk.css" ]] && copy_file "$MYDOT/common/config/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"
[[ -f "$MYDOT/common/config/.zshrc" ]] && copy_file "$MYDOT/common/config/.zshrc" "$HOME/.zshrc"
[[ -f "$MYDOT/common/config/.nanorc" ]] && copy_file "$MYDOT/common/config/.nanorc" "$HOME/.nanorc"
[[ -f "$MYDOT/common/once-config/mimeapps.list" ]] && copy_file "$MYDOT/common/once-config/mimeapps.list" "$HOME/.config/mimeapps.list"
[[ -d "$MYDOT/common/once-config/mpv" ]] && copy_dir "$MYDOT/common/once-config/mpv" "$HOME/.config/mpv"

# 3. niri
[[ -d "$MYDOT/niri/config/niri" ]] && copy_dir "$MYDOT/niri/config/niri" "$HOME/.config/niri"

# 4. local/bin
if [[ -d "$MYDOT/common/local/bin" ]]; then
  copy_dir "$MYDOT/common/local/bin" "$HOME/.local/bin"
  chmod +x "$HOME/.local/bin/"*.sh "$HOME/.local/bin/"*.py 2>/dev/null || true
  # buang symlink 'dockbar' kalau ikut ke-copy (itu symlink ke /usr/bin/waybar di mesin lama)
  [[ -L "$HOME/.local/bin/dockbar" ]] && rm -f "$HOME/.local/bin/dockbar" && warn "hapus symlink dockbar bawaan backup"
fi

# 5. hakuspace-control
if [[ -d "$MYDOT/hakuspace-control" ]]; then
  for f in niri-custom.kdl main_setting.sh dockbar_pin_apps hakumenu-general-custom.sh; do
    [[ -f "$MYDOT/hakuspace-control/$f" ]] && copy_file "$MYDOT/hakuspace-control/$f" "$HOME/hakuspace-control/$f"
  done
  [[ -d "$MYDOT/hakuspace-control/waybar" ]] && copy_dir "$MYDOT/hakuspace-control/waybar" "$HOME/hakuspace-control/waybar"
  [[ -d "$MYDOT/hakuspace-control/rofi" ]] && copy_dir "$MYDOT/hakuspace-control/rofi" "$HOME/hakuspace-control/rofi"
  chmod +x "$HOME/hakuspace-control/main_setting.sh" 2>/dev/null || true
fi

# 6. fonts Xanh_Mono -> ~/.local/share/fonts (biar waybar/rofi langsung dapat font)
if [[ -d "$MYDOT/Xanh_Mono" ]]; then
  mkdir -p "$HOME/.local/share/fonts/Xanh_Mono"
  cp -f "$MYDOT"/Xanh_Mono/*.ttf "$HOME/.local/share/fonts/Xanh_Mono/" 2>/dev/null || true
  [[ -f "$MYDOT/Xanh_Mono/OFL.txt" ]] && cp -f "$MYDOT/Xanh_Mono/OFL.txt" "$HOME/.local/share/fonts/Xanh_Mono/" || true
  if command -v fc-cache >/dev/null 2>&1; then
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null 2>&1 || true
    log "fc-cache refreshed"
  fi
  ok "fonts Xanh_Mono installed"
fi

# 7. wallpapers (target folder wallpaper selector)
#  wallpaper_select.sh & random_wallpaper.sh -> $HOME/Pictures/Wallpapers (*.jpg/png/gif)
#  wallpaper_video_select.sh               -> $HOME/Videos/Wallpapers (*.mp4) + Preview/
[[ -d "$MYDOT/assets/wallpapers" ]] && merge_dir_noclobber "$MYDOT/assets/wallpapers" "$HOME/Pictures/Wallpapers"
[[ -d "$MYDOT/assets/videos-wallpapers" ]] && merge_dir_noclobber "$MYDOT/assets/videos-wallpapers" "$HOME/Videos/Wallpapers"
mkdir -p "$HOME/Videos/Wallpapers/Preview"

# 8. gen style (generate ~/.local/state/haku_theme/*)
if [[ -x "$HOME/.local/bin/gen_style.sh" ]]; then
  "$HOME/.local/bin/gen_style.sh" && ok "gen_style.sh executed" || warn "gen_style.sh gagal, cek manual"
fi

# 9. cek dependensi biar wallpaper & semua script jalan
echo ""
echo "=== dependency check ==="
# cmd -> paket arch (dipakai untuk hint + --install-deps)
declare -A DEPS=(
  [rofi]=rofi [waybar]=waybar [niri]=niri [kitty]=kitty [cava]=cava
  [btop]=btop [fastfetch]=fastfetch [swaync]=swaynotificationcenter
  [hyprlock]=hyprlock [hypridle]=hypridle [awww]=awww [mpvpaper]=mpvpaper
  [wlr-randr]=wlr-randr [magick]=imagemagick [wl-screenrec]=wl-screenrec
  [grim]=grim [slurp]=slurp [wl-copy]=wl-clipboard [notify-send]=libnotify
  [gammastep]=gammastep [hyprsunset]=hyprsunset [lavat]=lavat [tty-clock]=tty-clock
  [hyprpicker]=hyprpicker [jq]=jq [brightnessctl]=brightnessctl [mpv]=mpv
  [python3]=python [fc-cache]=fontconfig
)
MISSING_PKGS=()
for cmd in "${!DEPS[@]}"; do
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "$cmd ada"
  else
    warn "$cmd HILANG (paket: ${DEPS[$cmd]})"
    MISSING_PKGS+=("${DEPS[$cmd]}")
  fi
done
# python module untuk accent color
if python3 -c "import colorthief" 2>/dev/null; then
  ok "python colorthief ada"
else
  warn "python colorthief HILANG (pip install colorthief)"
  MISSING_PKGS+=("python-colorthief(pip: colorthief)")
fi

if [[ "${#MISSING_PKGS[@]}" -gt 0 ]] && [[ "$INSTALL_DEPS" == true ]]; then
  # dedup
  mapfile -t MISSING_PKGS < <(printf "%s\n" "${MISSING_PKGS[@]}" | sort -u)
  echo ""
  log "coba install yang hilang: ${MISSING_PKGS[*]}"
  if command -v xbps-install >/dev/null 2>&1; then
    # Void Linux (xbps). Perhatian: nama paket case-sensitive!
    # Waybar (W besar), SwayNotificationCenter, ImageMagick.
    # hypr* (hyprlock/hypridle/hyprpicker/hyprsunset) TIDAK ada di repo resmi
    # -> pakai repo pihak ke-3 void-land (https://github.com/void-land/hyprland-void-packages)
    #      atau build manual. Script ini hanya install yang ada di repo resmi.
    VOID_PKGS=()
    VOID_SKIP=()
    for p in "${MISSING_PKGS[@]}"; do
      case "$p" in
        waybar) VOID_PKGS+=("Waybar") ;;
        swaynotificationcenter) VOID_PKGS+=("SwayNotificationCenter") ;;
        imagemagick) VOID_PKGS+=("ImageMagick") ;;
        wl-clipboard) VOID_PKGS+=("wl-clipboard") ;;
        libnotify) VOID_PKGS+=("libnotify") ;;
        fontconfig) VOID_PKGS+=("fontconfig") ;;
        python) VOID_PKGS+=("python3") ;;
        hyprlock|hypridle|hyprpicker|hyprsunset)
          VOID_SKIP+=("$p (void-land repo / build manual, lihat bawah)")
          ;;
        lavat)
          VOID_SKIP+=("$p (cargo install lavat)")
          ;;
        "python-colorthief(pip: colorthief)") ;;
        *) VOID_PKGS+=("$p") ;;
      esac
    done
    if [[ "${#VOID_PKGS[@]}" -gt 0 ]]; then
      log "xbps: sudo xbps-install -Sy ${VOID_PKGS[*]}"
      sudo xbps-install -Sy "${VOID_PKGS[@]}" || warn "xbps gagal sebagian, install manual"
    fi
    if [[ "${#VOID_SKIP[@]}" -gt 0 ]]; then
      warn "SKIP xbps (tidak di repo resmi Void):"
      for s in "${VOID_SKIP[@]}"; do warn "  - $s"; done
      echo "  hyprland-void-packages: https://github.com/void-land/hyprland-void-packages"
    fi
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm "${MISSING_PKGS[@]}" || warn "pacman gagal sebagian, install manual"
  elif command -v apt >/dev/null 2>&1; then
    sudo apt update && sudo apt install -y "${MISSING_PKGS[@]}" || warn "apt gagal sebagian"
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y "${MISSING_PKGS[@]}" || warn "dnf gagal sebagian"
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y "${MISSING_PKGS[@]}" || warn "zypper gagal sebagian"
  else
    err "package manager tidak dikenal, install manual: ${MISSING_PKGS[*]}"
  fi
  # pip fallback untuk colorthief
  python3 -c "import colorthief" 2>/dev/null || pip install --user colorthief || warn "pip install colorthief gagal"
fi

# 10. verifikasi wallpaper selector
echo ""
echo "=== verify wallpaper ==="
WALL_DIR="$HOME/Pictures/Wallpapers"
WALL_MPV_DIR="$HOME/Videos/Wallpapers"
IMG_COUNT=$(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) 2>/dev/null | wc -l)
VID_COUNT=$(find "$WALL_MPV_DIR" -maxdepth 1 -type f -iname "*.mp4" 2>/dev/null | wc -l)
[[ "$IMG_COUNT" -gt 0 ]] && ok "wallpaper gambar: $IMG_COUNT file di $WALL_DIR" || warn "tidak ada gambar di $WALL_DIR"
log "wallpaper video: $VID_COUNT file di $WALL_MPV_DIR (boleh 0)"
[[ -x "$HOME/.local/bin/wallpaper_select.sh" ]] && ok "wallpaper_select.sh siap" || err "wallpaper_select.sh hilang!"
[[ -x "$HOME/.local/bin/wallpaper_set.sh" ]] && ok "wallpaper_set.sh siap" || err "wallpaper_set.sh hilang!"
fc-list 2>/dev/null | grep -qi "xanh" && ok "font Xanh Mono terdeteksi" || warn "font Xanh Mono belum terdeteksi (relogin / fc-cache -fv)"

echo ""
ok "Selesai! Backup lama ada di: $BACKUP_DIR"
echo "ly-dm TIDAK diinstall otomatis. Manual: sudo bash $MYDOT/system/restore-ly.sh"
echo "Relogin/reboot biar niri + waybar + awww jalan penuh."
