#!/bin/bash
# restore ly-dm untuk distro baru (butuh sudo)
# Cara pakai: sudo ./restore-ly.sh  (dari folder system/)
# atau: sudo bash system/restore-ly.sh
set -u
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/ly" &>/dev/null && pwd)"
DST="/etc/ly"

echo "=== restore ly ==="
echo "src : $SRC"
echo "dst : $DST"

[[ -d "$SRC" ]] || { echo "src tidak ketemu: $SRC"; exit 1; }
[[ "$(id -u)" -eq 0 ]] || { echo "harus root/sudo!"; exit 1; }

mkdir -p "$DST"
cp -v "$SRC/config.ini" "$DST/config.ini"
cp -v "$SRC/blackhole-smooth-240x67.dur" "$DST/"
cp -v "$SRC/setup.sh" "$SRC/startup.sh" "$DST/"
chmod +x "$DST/setup.sh" "$DST/startup.sh"
mkdir -p "$DST/lang" "$DST/custom-sessions"
[[ -f "$SRC/lang/en.ini" ]] && cp -v "$SRC/lang/en.ini" "$DST/lang/"
[[ -f "$SRC/custom-sessions/README" ]] && cp -v "$SRC/custom-sessions/README" "$DST/custom-sessions/" 2>/dev/null || true

echo ""
echo "Selesai. Theme aktif: blackhole-smooth-240x67.dur (animation=dur_file)"
echo "Pastikan paket ly terinstall, lalu aktifkan service:"
echo "  systemd (Arch/dll): systemctl enable ly.service"
echo "  runit (Void): sudo ln -s /etc/sv/ly /var/service/  (kalau paket void menyediakan service ly)"
