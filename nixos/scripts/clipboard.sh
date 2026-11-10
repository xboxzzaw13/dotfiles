# Cancellation leaves the clipboard unchanged. Decode completely before replacing it.
selection=$(cliphist list | rofi -dmenu -display-columns 2 -p Clipboard) || exit 0
[[ -n "$selection" ]] || exit 0
decoded=$(mktemp)
trap 'rm -f "$decoded"' EXIT
printf '%s\n' "$selection" | cliphist decode > "$decoded"
wl-copy < "$decoded"
