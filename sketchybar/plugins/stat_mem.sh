#!/bin/bash
# Memory popup (anchor mem): pressure, memory used, swap, compressed memory, top 5 apps.
#   stat_mem.sh reset   fill the rows with "…"
#   stat_mem.sh loop    gather and draw every 2 s until the popup closes

source "$HOME/.config/sketchybar/plugins/stat_lib.sh"
source "$HOME/.config/sketchybar/plugins/icon_map.sh"

ANCHOR=mem

if [ "$1" = reset ]; then
  args=()
  for r in mp.pressure mp.used mp.swap mp.comp; do args+=(--set $r label="…"); done
  for n in 1 2 3 4 5; do args+=(--set mp.app.$n drawing=off); done
  sketchybar "${args[@]}"
  exit 0
fi
[ "$1" = loop ] || exit 0
single_instance mem

TOTAL=$(sysctl -n hw.memsize)

while popup_open $ANCHOR; do
  # pressure: the kernel's level (1 normal, 2 warning, 4 critical) and the free percentage
  case $(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null) in
    4) PL="Critical"; PC=$RED ;;
    2) PL="Warning"; PC=$ORANGE ;;
    *) PL="Normal"; PC=$GREEN ;;
  esac
  FREE=$(memory_pressure -Q 2>/dev/null | awk -F': ' '/free percentage/{gsub("%","",$2); print $2}')

  # used = app memory + wired + compressed, as Activity Monitor adds it up
  VM=$(vm_stat)
  PAGE=$(awk '/page size of/{gsub(/[^0-9]/,"",$8); print $8}' <<< "$VM"); PAGE=${PAGE:-4096}
  pages() { awk -v k="$1" -F: '$1 == k { gsub(/[^0-9]/, "", $2); print $2 }' <<< "$VM"; }
  ANON=$(pages "Anonymous pages"); PURG=$(pages "Pages purgeable")
  WIRED=$(pages "Pages wired down"); COMP=$(pages "Pages occupied by compressor")
  USED=$(( ( ${ANON:-0} - ${PURG:-0} + ${WIRED:-0} + ${COMP:-0} ) * PAGE ))
  COMPB=$(( ${COMP:-0} * PAGE ))

  # swap: "total = 5120.00M  used = 4047.75M  free = ..."
  read -r SW_USED SW_TOTAL <<< "$(sysctl -n vm.swapusage | awk '{gsub("M","",$3); gsub("M","",$6); print $6, $3}')"
  SWC=$LABEL_COLOR
  [ "${SW_USED%.*}" -gt 2048 ] 2>/dev/null && SWC=$ORANGE

  args=(--set mp.pressure label="Pressure   $PL · ${FREE:-?}% free" icon.color=$PC
        --set mp.used label="Used   $(human_bytes $USED) of $(human_bytes $TOTAL)"
        --set mp.swap label="Swap   $(awk -v u="${SW_USED:-0}" -v t="${SW_TOTAL:-0}" 'BEGIN{printf "%.1f GB of %.1f GB", u/1024, t/1024}') in use" label.color=$SWC
        --set mp.comp label="Compressed   $(human_bytes $COMPB)")

  n=0
  while IFS='|' read -r kb name; do
    [ -n "$name" ] || continue
    n=$((n+1))
    __icon_map "$name"
    args+=(--set mp.app.$n drawing=on icon="$icon_result" label="$name   $(human_bytes $((kb * 1024)))")
  done < <(ps -Ao rss=,comm= | awk '
      { m = $1; $1 = ""; sub(/^ +/, ""); n = $0
        if (sub(/\.app\/.*/, "", n) == 0) sub(/^.*\//, "", n); else sub(/^.*\//, "", n)
        sub(/^-/, "", n); c[n] += m }
      END { for (n in c) printf "%d|%s\n", c[n], n }' | sort -t'|' -k1,1nr | head -5)
  for ((k = n + 1; k <= 5; k++)); do args+=(--set mp.app.$k drawing=off); done

  sketchybar "${args[@]}" 2>/dev/null
  nap 2 $ANCHOR || break
done
