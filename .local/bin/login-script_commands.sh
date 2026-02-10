#!/bin/bash

export login_commands=(
  "sleep 5 && $HOME/.local/bin/performancerun default"
  "gsettings set org.gnome.desktop.notifications show-banners true"
  "sleep 5 && $HOME/.local/bin/update-proton-ge"
)
