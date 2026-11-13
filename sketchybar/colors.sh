#!/bin/bash
# Colour themes. The active one is named in ~/.config/sketchybar/.theme
# (git-ignored). Switch with plugins/theme.sh (next | set <name> | list), alt-shift-t,
# the Theme row in the control centre, or the Alfred "om" menu.
# GENERATED for every theme except macchiato: python3 ~/dotfiles/themes/gen-colors.py
# (reads themes/<id>/colors.toml, which are Omarchy's own files). Every theme exports
# the same variable names; WHITE is the text colour (dark on a light theme).
# THEME_GHOSTTY: bundled Ghostty theme, or "palette" to write themes/<id>/colors.toml.

THEMES="macchiato tokyonight catppuccin everforest gruvbox kanagawa nord rosepine matteblack osakajade ristretto"
THEME=${THEME_OVERRIDE:-$(cat "$HOME/.config/sketchybar/.theme" 2>/dev/null)}   # THEME_OVERRIDE: preview/list without switching
case " $THEMES " in *" $THEME "*) ;; *) THEME=macchiato ;; esac
export THEME THEMES

case $THEME in
  tokyonight)
    export THEME_NAME="Tokyo Night" THEME_MODE=dark THEME_GHOSTTY="TokyoNight"
    export BLACK=0xff0e0e14  WHITE=0xffc0caf5  RED=0xfff7768e    GREEN=0xff9ece6a
    export BLUE=0xff7aa2f7   YELLOW=0xffe0af68 ORANGE=0xffeb927b MAGENTA=0xffad8ee6
    export GREY=0xff737893
    export BAR_COLOR=0xa01a1b26 BACKGROUND_1=0x90292e42 BACKGROUND_2=0x90414868
    export POPUP_BACKGROUND_COLOR=0xff1a1b26
    export ACCENT=0xff7aa2f7
    ;;
  catppuccin)
    export THEME_NAME="Catppuccin" THEME_MODE=dark THEME_GHOSTTY="Catppuccin Mocha"
    export BLACK=0xff101019  WHITE=0xffcdd6f4  RED=0xfff38ba8    GREEN=0xffa6e3a1
    export BLUE=0xff89b4fa   YELLOW=0xfff9e2af ORANGE=0xfff6b6ab MAGENTA=0xfff5c2e7
    export GREY=0xff8a90a9
    export BAR_COLOR=0xa01e1e2e BACKGROUND_1=0x9045475a BACKGROUND_2=0x90585b70
    export POPUP_BACKGROUND_COLOR=0xff1e1e2e
    export ACCENT=0xff89b4fa
    ;;
  everforest)
    export THEME_NAME="Everforest" THEME_MODE=dark THEME_GHOSTTY="Everforest Dark Soft"
    export BLACK=0xff181d20  WHITE=0xffd3c6aa  RED=0xffe67e80    GREEN=0xffa7c080
    export BLUE=0xff7fbbb3   YELLOW=0xffdbbc7f ORANGE=0xffe09d7f MAGENTA=0xffd699b6
    export GREY=0xff948f80
    export BAR_COLOR=0xa02d353b BACKGROUND_1=0x903d484d BACKGROUND_2=0x90475258
    export POPUP_BACKGROUND_COLOR=0xff2d353b
    export ACCENT=0xff7fbbb3
    ;;
  gruvbox)
    export THEME_NAME="Gruvbox" THEME_MODE=dark THEME_GHOSTTY="Gruvbox Dark"
    export BLACK=0xff161616  WHITE=0xffd4be98  RED=0xffea6962    GREEN=0xffa9b665
    export BLUE=0xff7daea3   YELLOW=0xffd8a657 ORANGE=0xffe1875c MAGENTA=0xffd3869b
    export GREY=0xff93856d
    export BAR_COLOR=0xa0282828 BACKGROUND_1=0x90504945 BACKGROUND_2=0x90665c54
    export POPUP_BACKGROUND_COLOR=0xff282828
    export ACCENT=0xff7daea3
    ;;
  kanagawa)
    export THEME_NAME="Kanagawa" THEME_MODE=dark THEME_GHOSTTY="Kanagawa Wave"
    export BLACK=0xff111116  WHITE=0xffdcd7ba  RED=0xffc34043    GREEN=0xff76946a
    export BLUE=0xff7e9cd8   YELLOW=0xffc0a36e ORANGE=0xffc17158 MAGENTA=0xff957fb8
    export GREY=0xff949183
    export BAR_COLOR=0xa01f1f28 BACKGROUND_1=0x90363646 BACKGROUND_2=0x9054546d
    export POPUP_BACKGROUND_COLOR=0xff1f1f28
    export ACCENT=0xffdcd7ba
    ;;
  nord)
    export THEME_NAME="Nord" THEME_MODE=dark THEME_GHOSTTY="Nord"
    export BLACK=0xff191c23  WHITE=0xffd8dee9  RED=0xffbf616a    GREEN=0xffa3be8c
    export BLUE=0xff81a1c1   YELLOW=0xffebcb8b ORANGE=0xffd5967a MAGENTA=0xffb48ead
    export GREY=0xff979da9
    export BAR_COLOR=0xa02e3440 BACKGROUND_1=0x90434c5e BACKGROUND_2=0x904c566a
    export POPUP_BACKGROUND_COLOR=0xff2e3440
    export ACCENT=0xff81a1c1
    ;;
  rosepine)
    export THEME_NAME="Rose Pine" THEME_MODE=light THEME_GHOSTTY="Rose Pine Dawn"
    export BLACK=0xffe1dbd5  WHITE=0xff575279  RED=0xffb4637a    GREEN=0xff286983
    export BLUE=0xff56949f   YELLOW=0xffea9d34 ORANGE=0xffcf8057 MAGENTA=0xff907aa9
    export GREY=0xff817c97
    export BAR_COLOR=0xa0faf4ed BACKGROUND_1=0x90dfdad9 BACKGROUND_2=0x90cecacd
    export POPUP_BACKGROUND_COLOR=0xfffaf4ed
    export ACCENT=0xff56949f
    ;;
  matteblack)
    export THEME_NAME="Matte Black" THEME_MODE=dark THEME_GHOSTTY="Matte Black"
    export BLACK=0xff090909  WHITE=0xffbebebe  RED=0xffd35f5f    GREEN=0xffffc107
    export BLUE=0xffe68e0d   YELLOW=0xffb91c1c ORANGE=0xffc63d3d MAGENTA=0xffd35f5f
    export GREY=0xff7d7d7d
    export BAR_COLOR=0xa0121212 BACKGROUND_1=0x902a2a2a BACKGROUND_2=0x90333333
    export POPUP_BACKGROUND_COLOR=0xff121212
    export ACCENT=0xffe68e0d
    ;;
  osakajade)
    export THEME_NAME="Osaka Jade" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff090f0d  WHITE=0xfff7e8b2  RED=0xffff5345    GREEN=0xff549e6a
    export BLUE=0xff509475   YELLOW=0xff459451 ORANGE=0xffa2734b MAGENTA=0xffd2689c
    export GREY=0xff7e8467
    export BAR_COLOR=0xa0111c18 BACKGROUND_1=0x9032473b BACKGROUND_2=0x9053685b
    export POPUP_BACKGROUND_COLOR=0xff111c18
    export ACCENT=0xff509475
    ;;
  ristretto)
    export THEME_NAME="Ristretto" THEME_MODE=dark THEME_GHOSTTY="Monokai Pro Ristretto"
    export BLACK=0xff181414  WHITE=0xffe6d9db  RED=0xfffd6883    GREEN=0xffadda78
    export BLUE=0xfff38d70   YELLOW=0xfff9cc6c ORANGE=0xfffb9a77 MAGENTA=0xffa8a9eb
    export GREY=0xff9f9596
    export BAR_COLOR=0xa02c2525 BACKGROUND_1=0x90403e41 BACKGROUND_2=0x9072696a
    export POPUP_BACKGROUND_COLOR=0xff2c2525
    export ACCENT=0xfff38d70
    ;;
  *)
    export THEME_NAME="Catppuccin Macchiato" THEME_MODE=dark THEME_GHOSTTY="Catppuccin Macchiato"
    export BLACK=0xff181926  WHITE=0xffcad3f5  RED=0xffed8796    GREEN=0xffa6da95
    export BLUE=0xff8aadf4   YELLOW=0xffeed49f ORANGE=0xfff5a97f MAGENTA=0xffc6a0f6
    export GREY=0xff939ab7
    export BAR_COLOR=0xa024273a BACKGROUND_1=0x903c3e4f BACKGROUND_2=0x90494d64
    export POPUP_BACKGROUND_COLOR=0xff24273a
    export ACCENT=0xff8aadf4
    ;;
esac

export TRANSPARENT=0x00000000
export ICON_COLOR=$WHITE
export LABEL_COLOR=$WHITE
export POPUP_BORDER_COLOR=$WHITE
export SHADOW_COLOR=$BLACK

# Accent: the focused workspace pill and the window border
export ACCENT_FILL="0x40${ACCENT:4}"    # accent at 25%
export HOVER_COLOR="0x26${WHITE:4}"     # text colour at 15%
