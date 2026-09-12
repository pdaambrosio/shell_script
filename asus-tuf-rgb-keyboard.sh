#!/usr/bin/env zsh

set -euo pipefail

LED=""
for p in /sys/class/leds/asus::kbd_backlight \
         /sys/devices/platform/asus-nb-wmi/leds/asus::kbd_backlight \
         /sys/devices/platform/asus-nb-wmi; do
    [ -e "$p/kbd_rgb_mode" ] && LED="$p" && break
done
[ -n "$LED" ] || { echo "kbd_rgb_mode not found (asus_wmi loaded?)" >&2; exit 1; }

[ "$(id -u)" -eq 0 ] || exec sudo -- "$(readlink -f "$0")" "$@"

usage() {
cat <<'EOF'
usage: tuf-rgb <command> [args]
  static <colour> [speed]    solid colour
  breathe <colour> [speed]   breathing
  cycle [speed]              rainbow
  pulse <colour> [speed]     pulse
  bright <0-3>               backlight level (0 = off)
  status                     show current values
colour: name (red green blue white yellow cyan magenta orange purple pink)
        or ff6600 / #ff6600 / 255,102,0     speed: 0 slow, 1 med, 2 fast
EOF
}

rgb() {
    case "${1,,}" in
        red) h=ff0000;; green) h=00ff00;; blue) h=0000ff;;
        white) h=ffffff;; yellow) h=ffff00;; cyan) h=00ffff;;
        magenta) h=ff00ff;; orange) h=ff6600;; purple) h=8000ff;; pink) h=ff3399;;
        \#*) h="${1#\#}";;
        *,*,*) IFS=, read -r R G B <<<"$1"; return;;
        *) h="$1";;
    esac
    [[ "$h" =~ ^[0-9a-fA-F]{6}$ ]] || { echo "bad colour: $1" >&2; exit 1; }
    R=$((16#${h:0:2})); G=$((16#${h:2:2})); B=$((16#${h:4:2}))
}

# format: save mode red green blue speed
set_mode() {  # $1=mode $2=speed
    echo "1 $1 $R $G $B ${2:-0}" > "$LED/kbd_rgb_mode"
    [ "$(cat "$LED/brightness")" = 0 ] && echo 3 > "$LED/brightness"
    echo "ok: mode=$1 rgb=($R,$G,$B) speed=${2:-0}"
}

case "${1:-}" in
    static)  rgb "$2"; set_mode 0  "${3:-0}" ;;
    breathe) rgb "$2"; set_mode 1  "${3:-0}" ;;
    pulse)   rgb "$2"; set_mode 10 "${3:-0}" ;;
    cycle)   R=0 G=0 B=0; set_mode 2 "${2:-0}" ;;
    bright)  echo "$2" > "$LED/brightness" ;;
    status)  echo "path: $LED"; echo "brightness: $(cat "$LED/brightness")" ;;
    *)       usage; exit 1 ;;
esac
