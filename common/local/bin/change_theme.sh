#!/usr/bin/env bash

STATE_DIR="$HOME/.local/state/haku_theme"
GEN="$HOME/.local/bin/gen_style.sh"
APPLY="$HOME/.local/bin/apply_style.sh"

mkdir -p "$STATE_DIR"

get_current_accent() {
    local accent="#ffffff"
    if [[ -f "$STATE_DIR/colors.css" ]]; then
        local parsed
        parsed="$(sed -nE 's/^\s*@define-color\s+accent_color\s+(#[0-9a-fA-F]{6})\s*;.*$/\1/p' "$STATE_DIR/colors.css" | head -n1 || true)"
        [[ -n "${parsed:-}" ]] && accent="$parsed"
    fi
    printf '%s\n' "$accent"
}

get_current_size() {
    local size="14"
    if [[ -f "$STATE_DIR/fonts.css" ]]; then
        local parsed
        parsed="$(sed -nE 's/^\s*font-size:\s*([0-9]+)px\s*;.*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
        # fonts.css stores base+2, convert back to base size
        if [[ -n "${parsed:-}" ]]; then
            size=$((parsed - 2))
            [[ "$size" -lt 1 ]] && size="14"
        fi
    fi
    printf '%s\n' "$size"
}

get_current_font() {
    local font="monospace"
    if [[ -f "$STATE_DIR/fonts.css" ]]; then
        local parsed
        parsed="$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/fonts.css" | head -n1 || true)"
        [[ -n "${parsed:-}" ]] && font="$parsed"
    fi
    printf '%s\n' "$font"
}

get_current_waybar_font() {
    local font=""
    if [[ -f "$STATE_DIR/waybar-fonts.css" ]]; then
        font="$(sed -nE 's/^\s*font-family:\s*"([^"]+)".*$/\1/p' "$STATE_DIR/waybar-fonts.css" | head -n1 || true)"
    fi
    # default follow global if no dedicated file yet
    [[ -z "${font:-}" ]] && font="$(get_current_font)"
    printf '%s\n' "$font"
}

get_current_waybar_size() {
    local size=""
    if [[ -f "$STATE_DIR/waybar-fonts.css" ]]; then
        size="$(sed -nE 's/^\s*font-size:\s*([0-9]+)px\s*;.*$/\1/p' "$STATE_DIR/waybar-fonts.css" | head -n1 || true)"
    fi
    # default follow global + 2
    if [[ -z "${size:-}" ]]; then
        size=$(( $(get_current_size) + 2 ))
    fi
    printf '%s\n' "$size"
}

ACCENT="$(get_current_accent)"
FONT_FAMILY="$(get_current_font)"
FONT_SIZE="$(get_current_size)"
WAYBAR_FONT="$(get_current_waybar_font)"
WAYBAR_SIZE="$(get_current_waybar_size)"

prompt="Change Theme - Choose an option:"

choice="$(
    cat <<EOF | rofi -dmenu -p "$prompt" -i
  Change font
  Change font size
󰍜  Change waybar font
󰍜  Change waybar size
  Change color
EOF
)"
[[ -z "${choice:-}" ]] && exit 0

case "$choice" in
    "  Change font")
        fonts="$(fc-list : family 2>/dev/null | sed 's/,.*//' | sort -u || true)"
        [[ -z "$fonts" ]] && { echo "No fonts found via fc-list" >&2; exit 1; }
        new_font="$(printf '%s\n' "$fonts" | rofi -dmenu -p "  Current: ${FONT_FAMILY}" -i)"
        [[ -z "${new_font:-}" ]] && exit 0
        FONT_FAMILY="$new_font"
        # global changed -> waybar follows global by default
        WAYBAR_FONT="$FONT_FAMILY"
        WAYBAR_SIZE=$((FONT_SIZE + 2))
        ;;

    "  Change font size")
        new_size="$(printf '%s\n' "$FONT_SIZE" | rofi -dmenu -p "  Current: ${FONT_SIZE}px" -theme-str 'entry { placeholder: "Type font size here"; }' -i)"
        [[ -z "${new_size:-}" ]] && exit 0
        [[ "$new_size" =~ ^[0-9]+$ ]] || exit 0
        FONT_SIZE="$new_size"
        # global changed -> waybar follows global + 2
        WAYBAR_SIZE=$((FONT_SIZE + 2))
        ;;

    *"Change waybar font"*)
        fonts="$(fc-list : family 2>/dev/null | sed 's/,.*//' | sort -u || true)"
        [[ -z "$fonts" ]] && { echo "No fonts found via fc-list" >&2; exit 1; }
        new_wfont="$(printf '%s\n' "$fonts" | rofi -dmenu -p "󰍜  Waybar current: ${WAYBAR_FONT}" -i)"
        [[ -z "${new_wfont:-}" ]] && exit 0
        WAYBAR_FONT="$new_wfont"
        ;;

    *"Change waybar size"*)
        new_wsize="$(printf '%s\n' "$WAYBAR_SIZE" | rofi -dmenu -p "󰍜  Waybar current: ${WAYBAR_SIZE}px" -theme-str 'entry { placeholder: "Type waybar font size here"; }' -i)"
        [[ -z "${new_wsize:-}" ]] && exit 0
        [[ "$new_wsize" =~ ^[0-9]+$ ]] || exit 0
        WAYBAR_SIZE="$new_wsize"
        ;;

    "  Change color")
        accent_choice="$(
        cat <<'EOF' | rofi -dmenu -p "  Current: ${ACCENT}" -theme-str 'entry { placeholder: "Type hex color here #xxxxxx"; }' -i
Pick Color   [Press Enter]
Slate Blue   #7288AE
Green        #A2CB8B
Peach        #FFB399
Yellow       #EFBF04
Pink         #F9B2D7
White        #FFFFFF
Grey         #BFC9D1
EOF
    )"
    [[ -z "${accent_choice:-}" ]] && exit 0
    
    if [[ "$accent_choice" == "Pick Color   [Press Enter]" ]]; then
        ~/.local/bin/accent_color_picker.sh
        exit 0
    else
        picked_hex="$(printf '%s\n' "$accent_choice" | grep -oE '#[0-9a-fA-F]{6}' | head -n1 || true)"
        [[ -n "$picked_hex" ]] && ACCENT="$picked_hex"
    fi
    ;;
esac

"$GEN" "$ACCENT" "$FONT_FAMILY" "$FONT_SIZE" --waybar-font "$WAYBAR_FONT" --waybar-size "$WAYBAR_SIZE"
"$APPLY"