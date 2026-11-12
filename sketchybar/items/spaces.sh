#!/bin/bash
# One item per AeroSpace workspace. Click to focus it, right-click for a popup
# of its windows. The label lists the
# apps on that workspace (sketchybar-app-font). The focused one sits in an
# accent pill, empty ones fade to grey, and hovering highlights the rest.

sketchybar --add event aerospace_workspace_change \
           --add event aerospace_focus_change

# Names and the hidden scratchpad workspace live in workspaces.conf
source "$HOME/.config/sketchybar/workspaces.conf"

# The workspace list is fixed at load; spaces.sh reads it from here instead of
# asking AeroSpace on every refresh. Hidden workspaces (the scratchpad) are left out.
SPACE_IDS=$(visible_workspaces)
echo $SPACE_IDS > "${TMPDIR:-/tmp}/sketchybar_spaces"

for sid in $SPACE_IDS; do
  space=(
    icon="$(workspace_label $sid)"
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
    popup.align=left
    popup.height=28
    click_script="$PLUGIN_DIR/space_click.sh $sid"
    script="$PLUGIN_DIR/space_item.sh"
  )

  sketchybar --add item space.$sid center  \
             --set space.$sid "${space[@]}" \
             --subscribe space.$sid mouse.entered mouse.exited mouse.exited.global
done

# Hidden item that refreshes every workspace in one pass
sketchybar --add item aerospace center                            \
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

sketchybar --add bracket spaces '/space\..*/' \
           --set spaces "${spaces[@]}"
