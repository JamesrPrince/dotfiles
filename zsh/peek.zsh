# peek <file>: show an image, PDF, deck or document inline in Ghostty (kitty graphics protocol).
# Images are converted to PNG by sips; anything else is rendered to a page thumbnail by
# Quick Look first; if that fails, Quick Look opens it in a window. No Homebrew tools needed.
peek() {
  local f="$1"; [ -f "$f" ] || { echo "peek: no such file: $f"; return 1; }
  local tmp img; tmp=$(mktemp -d)
  case "${f:l}" in
    *.png|*.jpg|*.jpeg|*.gif|*.webp|*.bmp|*.tif|*.tiff|*.heic)
      img="$tmp/peek.png"; sips -s format png -Z 1600 "$f" --out "$img" >/dev/null 2>&1 ;;
    *)
      qlmanage -t -s 1600 -o "$tmp" "$f" >/dev/null 2>&1
      img=$(print -l "$tmp"/*.png(N) | head -1) ;;
  esac
  if [ -n "$img" ] && [ -s "$img" ]; then
    /usr/bin/python3 ~/.config/zsh/peek-kitty.py "$img" "$(( COLUMNS > 120 ? 120 : COLUMNS ))"
  else
    qlmanage -p "$f" >/dev/null 2>&1
  fi
  rm -rf "$tmp"
}
