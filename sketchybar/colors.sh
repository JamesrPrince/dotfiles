#!/bin/bash
# Colour themes. The active one is named in ~/.config/sketchybar/.theme
# (git-ignored). Switch with plugins/theme.sh (next | set <name> | list), alt-shift-t,
# the Theme row in the control centre, or the Alfred "om" menu.
# GENERATED for every theme except macchiato: python3 ~/dotfiles/themes/gen-colors.py
# (reads themes/<id>/colors.toml, which are Omarchy's own files). Every theme exports
# the same variable names; WHITE is the text colour (dark on a light theme).
# THEME_GHOSTTY: bundled Ghostty theme, or "palette" to write themes/<id>/colors.toml.

THEMES="macchiato tokyonight catppuccin everforest gruvbox kanagawa nord rosepine matteblack osakajade ristretto catppuccinlatte ethereal flexokilight hackerman jadehorse lasthorizon lumon lupine miasma retro82 solitude starship vantablack white"
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
  catppuccinlatte)
    export THEME_NAME="Catppuccin Latte" THEME_MODE=light THEME_GHOSTTY="Catppuccin Latte"
    export BLACK=0xffd7d8dc  WHITE=0xff4c4f69  RED=0xffd20f39    GREEN=0xff40a02b
    export BLUE=0xff1e66f5   YELLOW=0xffdf8e1d ORANGE=0xffd84e2b MAGENTA=0xffea76cb
    export GREY=0xff7b7e92
    export BAR_COLOR=0xa0eff1f5 BACKGROUND_1=0x90ccd0da BACKGROUND_2=0x90acb0be
    export POPUP_BACKGROUND_COLOR=0xffeff1f5
    export ACCENT=0xff1e66f5
    ;;
  ethereal)
    export THEME_NAME="Ethereal" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff030610  WHITE=0xffffcead  RED=0xffed5b5a    GREEN=0xff92a593
    export BLUE=0xff7d82d9   YELLOW=0xffe9bb4f ORANGE=0xffeb8b54 MAGENTA=0xffc89dc1
    export GREY=0xffa08477
    export BAR_COLOR=0xa0060b1e BACKGROUND_1=0x90252e56 BACKGROUND_2=0x906d7db6
    export POPUP_BACKGROUND_COLOR=0xff060b1e
    export ACCENT=0xff7d82d9
    ;;
  flexokilight)
    export THEME_NAME="Flexoki Light" THEME_MODE=light THEME_GHOSTTY="Flexoki Light"
    export BLACK=0xffe5e2d8  WHITE=0xff100f0f  RED=0xffd14d41    GREEN=0xff879a39
    export BLUE=0xff205ea6   YELLOW=0xffd0a215 ORANGE=0xffd0772b MAGENTA=0xffce5d97
    export GREY=0xff6b6964
    export BAR_COLOR=0xa0fffcf0 BACKGROUND_1=0x90cecdc3 BACKGROUND_2=0x90b7b5ac
    export POPUP_BACKGROUND_COLOR=0xfffffcf0
    export ACCENT=0xff205ea6
    ;;
  hackerman)
    export THEME_NAME="Hackerman" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff06060c  WHITE=0xffddf7ff  RED=0xff50f872    GREEN=0xff4fe88f
    export BLUE=0xff829dd4   YELLOW=0xff50f7d4 ORANGE=0xff50f7a3 MAGENTA=0xff86a7df
    export GREY=0xff8d9ea6
    export BAR_COLOR=0xa00b0c16 BACKGROUND_1=0x901f253a BACKGROUND_2=0x902d3450
    export POPUP_BACKGROUND_COLOR=0xff0b0c16
    export ACCENT=0xff82fb9c
    ;;
  jadehorse)
    export THEME_NAME="Jade Horse" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff0a1713  WHITE=0xfff0faf4  RED=0xffd88d91    GREEN=0xff8bcbb1
    export BLUE=0xff96b7d0   YELLOW=0xffc5cc91 ORANGE=0xffd2ab8d MAGENTA=0xffb7a1c8
    export GREY=0xff92a19a
    export BAR_COLOR=0xa0142620 BACKGROUND_1=0x902b5147 BACKGROUND_2=0x9064887b
    export POPUP_BACKGROUND_COLOR=0xff142620
    export ACCENT=0xff8bcbb1
    ;;
  lasthorizon)
    export THEME_NAME="Last Horizon" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff060606  WHITE=0xffe2dddc  RED=0xffc38b7b    GREEN=0xff87a9b0
    export BLUE=0xffb59790   YELLOW=0xff6b5e73 ORANGE=0xff6b5e73 MAGENTA=0xffc4d8e2
    export GREY=0xffa0a0a0
    export BAR_COLOR=0xa00c0b0c BACKGROUND_1=0x90584e51 BACKGROUND_2=0x90584e51
    export POPUP_BACKGROUND_COLOR=0xff0c0b0c
    export ACCENT=0xffb59790
    ;;
  lumon)
    export THEME_NAME="Lumon" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff0b1216  WHITE=0xfff2fcff  RED=0xff4d86b0    GREEN=0xff5e95bc
    export BLUE=0xff6fb8e3   YELLOW=0xff6fa4c9 ORANGE=0xff8bc9eb MAGENTA=0xff8bc9eb
    export GREY=0xff8d9aa5
    export BAR_COLOR=0xa016242d BACKGROUND_1=0x90243d56 BACKGROUND_2=0x90304860
    export POPUP_BACKGROUND_COLOR=0xff16242d
    export ACCENT=0xff8bc9eb
    ;;
  lupine)
    export THEME_NAME="Lupine" THEME_MODE=light THEME_GHOSTTY="palette"
    export BLACK=0xffdedede  WHITE=0xff000000  RED=0xffc900c4    GREEN=0xff4a2fd0
    export BLUE=0xff3264eb   YELLOW=0xff026fde ORANGE=0xff026fde MAGENTA=0xff8a4ad7
    export GREY=0xff737373
    export BAR_COLOR=0xa0fafafa BACKGROUND_1=0x90d0d0d0 BACKGROUND_2=0x909e9e9e
    export POPUP_BACKGROUND_COLOR=0xfffafafa
    export ACCENT=0xff3264eb
    ;;
  miasma)
    export THEME_NAME="Miasma" THEME_MODE=dark THEME_GHOSTTY="Miasma"
    export BLACK=0xff121212  WHITE=0xffc2c2b0  RED=0xff685742    GREEN=0xff5f875f
    export BLUE=0xff78824b   YELLOW=0xffb36d43 ORANGE=0xff8d6242 MAGENTA=0xffbb7744
    export GREY=0xff85857a
    export BAR_COLOR=0xa0222222 BACKGROUND_1=0x90383838 BACKGROUND_2=0x90666666
    export POPUP_BACKGROUND_COLOR=0xff222222
    export ACCENT=0xff78824b
    ;;
  retro82)
    export THEME_NAME="Retro 82" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff020c17  WHITE=0xfff6dcac  RED=0xfff85525    GREEN=0xff028391
    export BLUE=0xff3f8f8a   YELLOW=0xffe97b3c ORANGE=0xfffaa968 MAGENTA=0xff3f8f8a
    export GREY=0xff9a927c
    export BAR_COLOR=0xa005182e BACKGROUND_1=0x90134e5a BACKGROUND_2=0x902a6b78
    export POPUP_BACKGROUND_COLOR=0xff05182e
    export ACCENT=0xfffaa968
    ;;
  solitude)
    export THEME_NAME="Solitude" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff080a0b  WHITE=0xffa5aeb4  RED=0xff565d60    GREEN=0xff9fa5a9
    export BLUE=0xff798186   YELLOW=0xffd9dbdc ORANGE=0xffd9dbdc MAGENTA=0xffaeaeae
    export GREY=0xff838686
    export BAR_COLOR=0xa0101315 BACKGROUND_1=0x90343d41 BACKGROUND_2=0x904b4e55
    export POPUP_BACKGROUND_COLOR=0xff101315
    export ACCENT=0xff798186
    ;;
  starship)
    export THEME_NAME="Starship" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff0e0e10  WHITE=0xffffffff  RED=0xffff5f4a    GREEN=0xffff9f0a
    export BLUE=0xff8fb8de   YELLOW=0xffffc27a ORANGE=0xffff6a3d MAGENTA=0xffff8fa3
    export GREY=0xffa3a3a5
    export BAR_COLOR=0xa01c1c1e BACKGROUND_1=0x903a3a3c BACKGROUND_2=0x908e8e93
    export POPUP_BACKGROUND_COLOR=0xff1c1c1e
    export ACCENT=0xffff9f0a
    ;;
  vantablack)
    export THEME_NAME="Vantablack" THEME_MODE=dark THEME_GHOSTTY="palette"
    export BLACK=0xff070707  WHITE=0xffffffff  RED=0xffa4a4a4    GREEN=0xffb6b6b6
    export BLUE=0xff8d8d8d   YELLOW=0xffcecece ORANGE=0xffb9b9b9 MAGENTA=0xff9b9b9b
    export GREY=0xff9e9e9e
    export BAR_COLOR=0xa0000000 BACKGROUND_1=0x901a1a1a BACKGROUND_2=0x907a7a7a
    export POPUP_BACKGROUND_COLOR=0xff000000
    export ACCENT=0xff8d8d8d
    ;;
  white)
    export THEME_NAME="White" THEME_MODE=light THEME_GHOSTTY="palette"
    export BLACK=0xffe8e8e8  WHITE=0xff000000  RED=0xff2a2a2a    GREEN=0xff3a3a3a
    export BLUE=0xff1a1a1a   YELLOW=0xff4a4a4a ORANGE=0xff4a4a4a MAGENTA=0xff2e2e2e
    export GREY=0xff616161
    export BAR_COLOR=0xa0ffffff BACKGROUND_1=0x90c0c0c0 BACKGROUND_2=0x90808080
    export POPUP_BACKGROUND_COLOR=0xffffffff
    export ACCENT=0xff6e6e6e
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
