#!/bin/bash
# mydotfiles restore - copy config modif kamu ke laptop baru
# Cara pakai: ./restore.sh  (dari folder mydotfiles)
set -u

MYDOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BACKUP_TS="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_DIR="$HOME/Backup_restore_$BACKUP_TS"

log()  { echo -e "\e[34m[INFO]\e[0m $1"; }
ok()   { echo -e "\e[32m[OK]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }

backup_item() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  local rel="${target#$HOME/}"
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

echo "=== mydotfiles restore ==="
echo "src : $MYDOT"
echo "backup ke: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# folder wajib
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/hakuspace-control" "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"

# 1. common/config/* -> ~/.config/*
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
[[ -d "$MYDOT/common/local/bin" ]] && copy_dir "$MYDOT/common/local/bin" "$HOME/.local/bin" && chmod +x "$HOME/.local/bin/"*.sh "$HOME/.local/bin/"*.py 2>/dev/null || true

# 5. hakuspace-control (skip mango & hyprland custom)
if [[ -d "$MYDOT/hakuspace-control" ]]; then
  for f in niri-custom.kdl main_setting.sh dockbar_pin_apps hakumenu-general-custom.sh; do
    [[ -f "$MYDOT/hakuspace-control/$f" ]] && copy_file "$MYDOT/hakuspace-control/$f" "$HOME/hakuspace-control/$f"
  done
  [[ -d "$MYDOT/hakuspace-control/waybar" ]] && copy_dir "$MYDOT/hakuspace-control/waybar" "$HOME/hakuspace-control/waybar"
  [[ -d "$MYDOT/hakuspace-control/rofi" ]] && copy_dir "$MYDOT/hakuspace-control/rofi" "$HOME/hakuspace-control/rofi"
  chmod +x "$HOME/hakuspace-control/main_setting.sh" 2>/dev/null || true
fi

# 6. gen style kalau ada
if [[ -x "$HOME/.local/bin/gen_style.sh" ]]; then
  "$HOME/.local/bin/gen_style.sh" && ok "gen_style.sh executed"
fi

echo ""
ok "Selesai! Backup lama ada di: $BACKUP_DIR"
echo "Restart / relogin biar full apply."
