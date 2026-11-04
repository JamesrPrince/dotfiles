#!/bin/bash
# One item per AeroSpace workspace. Click to focus it. The label lists the
# apps on that workspace (sketchybar-app-font); the focused one turns red.

sketchybar --add event aerospace_workspace_change

for sid in $(aerospace list-workspaces --all); do
  space=(
    icon="$sid"
    icon.padding_left=10
    icon.padding_right=15
    padding_left=2
    padding_right=2
    label.padding_right=20
    icon.highlight_color=$RED
    label.font="sketchybar-app-font:Regular:16.0"
    label.background.height=26
    label.background.drawing=on
    label.background.color=$BACKGROUND_2
    label.background.corner_radius=8
    label.drawing=off
    click_script="/usr/local/bin/aerospace workspace $sid"
  )

  sketchybar --add item space.$sid left    \
             --set space.$sid "${space[@]}"
done

# Hidden item that refreshes every workspace in one pass
sketchybar --add item aerospace left                              \
           --set aerospace drawing=off updates=on                 \
                           script="$PLUGIN_DIR/spaces.sh"         \
           --subscribe aerospace aerospace_workspace_change       \
                                 front_app_switched               \
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
