#!/bin/bash
# Colour themes. The active one is named in ~/.config/sketchybar/.theme
# (git-ignored); plugins/theme.sh next cycles it (alt-shift-t, or the
# Theme row in the control centre). Default: Catppuccin Macchiato.

THEMES="macchiato tokyonight gruvbox"
THEME=$(cat "$HOME/.config/sketchybar/.theme" 2>/dev/null)
case " $THEMES " in *" $THEME "*) ;; *) THEME=macchiato ;; esac
export THEME THEMES

case $THEME in
  tokyonight)
    export THEME_NAME="Tokyo Night"
    export BLACK=0xff16161e  WHITE=0xffc0caf5  RED=0xfff7768e    GREEN=0xff9ece6a
    export BLUE=0xff7aa2f7   YELLOW=0xffe0af68 ORANGE=0xffff9e64 MAGENTA=0xffbb9af7
    export GREY=0xff737aa2
    export BAR_COLOR=0xa01a1b26 BACKGROUND_1=0x90292e42 BACKGROUND_2=0x90414868
    export POPUP_BACKGROUND_COLOR=0xff1a1b26
    ;;
  gruvbox)
    export THEME_NAME="Gruvbox"
    export BLACK=0xff1d2021  WHITE=0xffebdbb2  RED=0xfffb4934    GREEN=0xffb8bb26
    export BLUE=0xff83a598   YELLOW=0xfffabd2f ORANGE=0xfffe8019 MAGENTA=0xffd3869b
    export GREY=0xffa89984
    export BAR_COLOR=0xa0282828 BACKGROUND_1=0x903c3836 BACKGROUND_2=0x90504945
    export POPUP_BACKGROUND_COLOR=0xff282828
    ;;
  *)
    export THEME_NAME="Catppuccin Macchiato"
    export BLACK=0xff181926  WHITE=0xffcad3f5  RED=0xffed8796    GREEN=0xffa6da95
    export BLUE=0xff8aadf4   YELLOW=0xffeed49f ORANGE=0xfff5a97f MAGENTA=0xffc6a0f6
    export GREY=0xff939ab7
    export BAR_COLOR=0xa024273a BACKGROUND_1=0x903c3e4f BACKGROUND_2=0x90494d64
    export POPUP_BACKGROUND_COLOR=0xff24273a
    ;;
esac

export TRANSPARENT=0x00000000
export ICON_COLOR=$WHITE
export LABEL_COLOR=$WHITE
export POPUP_BORDER_COLOR=$WHITE
export SHADOW_COLOR=$BLACK

# Accent: the focused workspace pill and the window border
export ACCENT=$BLUE
export ACCENT_FILL="0x40${BLUE:4}"      # accent at 25%
export HOVER_COLOR="0x26${WHITE:4}"     # white at 15%
