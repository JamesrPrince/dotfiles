#!/bin/bash
# One item per AeroSpace workspace. Click to focus it. The label lists the
# apps on that workspace (sketchybar-app-font). The focused one sits in an
# accent pill, empty ones fade to grey, and hovering highlights the rest.

sketchybar --add event aerospace_workspace_change \
           --add event aerospace_focus_change

# The workspace list is fixed at load; spaces.sh reads it from here instead of
# asking AeroSpace on every refresh
SPACE_IDS=$(aerospace list-workspaces --all)
echo $SPACE_IDS > "${TMPDIR:-/tmp}/sketchybar_spaces"

for sid in $SPACE_IDS; do
  space=(
    icon="$sid"
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    label.padding_right=20
    icon.highlight_color=$ACCENT
    icon.font="$TEXT_FONT:ExtraBold:14.0"
    background.height=26
    background.corner_radius=8
    background.color=$TRANSPARENT
    background.border_width=0
    background.drawing=on
    label.font="sketchybar-app-font:Regular:16.0"
    label.background.height=26
    label.background.drawing=on
    label.background.color=$BACKGROUND_2
    label.background.corner_radius=8
    label.drawing=off
    click_script="/usr/local/bin/aerospace workspace $sid"
    script="$PLUGIN_DIR/hover.sh"
  )

  sketchybar --add item space.$sid left    \
             --set space.$sid "${space[@]}" \
             --subscribe space.$sid mouse.entered mouse.exited
done

# Hidden item that refreshes every workspace in one pass
sketchybar --add item aerospace left                              \
           --set aerospace drawing=off updates=on                 \
                           script="$PLUGIN_DIR/spaces.sh"         \
           --subscribe aerospace aerospace_workspace_change       \
                                 aerospace_focus_change           \
                                 space_windows_change system_woke

spaces=(
  background.color=$BACKGROUND_1
  background.border_color=$BACKGROUND_2
  background.border_width=2
  background.drawing=on
)

separator=(
  icon=$SEPARATOR
  icon.font="$FONT:Heavy:16.0"
  padding_left=15
  padding_right=15
  label.drawing=off
  associated_display=active
  icon.color=$WHITE
)

sketchybar --add bracket spaces '/space\..*/' \
           --set spaces "${spaces[@]}"        \
                                              \
           --add item separator left          \
           --set separator "${separator[@]}"
