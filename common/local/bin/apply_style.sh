#!/usr/bin/env bash

STATE_DIR="$HOME/.local/state/haku_theme"

# ---------------------------------------------------
# 1) Apply GTK font (best-effort)
# ---------------------------------------------------
if command -v gsettings >/dev/null 2>&1 && [[ -f "$STATE_DIR/fonts.css" ]]; then
    # Parse from fonts.css:
    #   font-family: "JetBrainsMono Nerd Font";
    #   font-size: 16px;
    font_family="$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
    font_size="$(sed -nE 's/^\s*font-size:\s*([0-9]+)px.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
  
    if [[ -n "${font_family:-}" && -n "${font_size:-}" ]]; then
        gtk_font="${font_family} ${font_size}"
        gsettings set org.gnome.desktop.interface font-name "$gtk_font" || true
        gsettings set org.gnome.desktop.interface monospace-font-name "$gtk_font" || true
    fi
fi

# ---------------------------------------------------
# 2) Reload apps
# ---------------------------------------------------
# hyprland reload
if pgrep -x Hyprland >/dev/null; then
    hyprctl reload >/dev/null 2>&1 || true
fi

# Labwc reload
if pgrep -x labwc >/dev/null; then
    labwc --reconfigure
fi

# Niri reload (picks up niri-style.kdl accent)
if pgrep -x niri >/dev/null 2>&1 && command -v niri >/dev/null 2>&1; then
    if [[ -z "${NIRI_SOCKET:-}" || ! -S "${NIRI_SOCKET:-}" ]]; then
        # niri msg needs NIRI_SOCKET, which background jobs (e.g. the
        # wallpaper timer started from another session) may not have.
        # Discover a live socket instead of failing silently.
        _sock_dir="/run/user/${UID:-$(id -u)}"
        _niri_sock=""
        if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
            _niri_sock="$(ls -t "$_sock_dir"/niri."$WAYLAND_DISPLAY".*.sock 2>/dev/null | head -n1 || true)"
        fi
        if [[ -z "${_niri_sock:-}" ]]; then
            _niri_sock="$(ls -t "$_sock_dir"/niri.*.sock 2>/dev/null | head -n1 || true)"
        fi
        [[ -n "${_niri_sock:-}" ]] && export NIRI_SOCKET="$_niri_sock"
    fi
    niri msg action load-config-file >/dev/null 2>&1 || true
fi

# Desktop icons reload
if [[ -f "$HOME/.local/bin/desktop_icons_manager.sh" ]]; then
    "$HOME/.local/bin/desktop_icons_manager.sh" --reload >/dev/null 2>&1 || true
fi

# Dockbar reload
if [[ -f "$HOME/.local/bin/dockbar_manager.sh" ]]; then
    "$HOME/.local/bin/dockbar_manager.sh" --reload >/dev/null 2>&1 || true
fi

# Swaync reload
swaync-client --reload-config --reload-css >/dev/null 2>&1 || true

# Waybar reload (picks up waybar-fonts.css / colors.css)
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR2 -x waybar >/dev/null 2>&1 || true
fi

# Kitty reload
for s in /tmp/kitty-*; do
    [[ -S "$s" ]] || continue
    kitty @ --to "unix:$s" ls >/dev/null 2>&1 || continue
    kitty @ --to "unix:$s" load-config >/dev/null 2>&1 || true
done