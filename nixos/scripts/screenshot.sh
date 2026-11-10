# Packaged by writeShellApplication (bash, errexit, nounset, pipefail).
case "${1:-area}" in
  area)
    geometry=$(slurp) || exit 0
    [[ -n "$geometry" ]] || exit 0
    ;;
  all) geometry= ;;
  *) echo "Usage: desktop-screenshot [area|all]" >&2; exit 2 ;;
esac
image=$(mktemp --suffix=.png)
trap 'rm -f "$image"' EXIT
if [[ -n "$geometry" ]]; then
  grim -g "$geometry" "$image"
else
  grim "$image"
fi
wl-copy --type image/png < "$image"
notify-send "Screenshot" "Copied to clipboard"
