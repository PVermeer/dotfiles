#!/bin/bash

set -e
set -x

# Log everything to logger
script_name=$(basename $0)
exec 1> >(logger -s -t $script_name) 2>&1

startOrEnd="$1"               # "start" | "end"
disableScaling="$2"           # "no-scaling"
virtual_display_width="1920"  # Default
virtual_display_height="1080" # Default
virtual_display_refresh="60"  # Default

# Display connectors
GNOMEwDisplay1="DP-1"
GNOMEwDisplay2="HDMI-1"
GNOMEwDisplay3="DP-3"   # Virtual kernel monitor
GNOMEwDisplay4="Meta-0" # Virtual gnome monitor

GNOMExDisplay1="DisplayPort-0"
GNOMExDisplay2="HDMI-A-0"
GNOMExDisplay3="DisplayPort-2"   # Virtual kernel monitor

KDEwDisplay1="DP-1"
KDEwDisplay2="HDMI-A-1"
KDEwDisplay3="DP-3" # Virtual kernel monitor

if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] && [ "$XDG_SESSION_TYPE" = "x11" ]; then
  display1="$GNOMExDisplay1"
  display2="$GNOMExDisplay2"
  display3="$GNOMExDisplay3"

elif [ "$XDG_CURRENT_DESKTOP" = "GNOME" ] && [ "$XDG_SESSION_TYPE" = "wayland" ]; then
  display1="$GNOMEwDisplay1"
  display2="$GNOMEwDisplay2"
  display3="$GNOMEwDisplay3"
  
elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
  display1="$KDEwDisplay1"
  display2="$KDEwDisplay2"
  display3="$KDEwDisplay3"
fi

if [ -n "$SUNSHINE_CLIENT_WIDTH" ] && [ -n "$SUNSHINE_CLIENT_HEIGHT" ] && [ -n "$SUNSHINE_CLIENT_FPS" ]; then
  virtual_display_width="$SUNSHINE_CLIENT_WIDTH"
  virtual_display_height="$SUNSHINE_CLIENT_HEIGHT"
  virtual_display_refresh="$SUNSHINE_CLIENT_FPS"
fi

if [[ $startOrEnd == 'start' ]]; then

  # Disable vpn
  # mullvad disconnect

  # Disable real monitors and enable virtual monitor
  displayScaleFactor="1"

  # Scaling still buggy with steam
  if [ "$disableScaling" = "no-scaling" ]; then
    displayScaleFactor="1"
  else
    if [ "$SUNSHINE_CLIENT_HEIGHT" = "2160" ]; then
      displayScaleFactor="2.5"
    elif [ "$SUNSHINE_CLIENT_HEIGHT" = "1080" ]; then
      displayScaleFactor="1.25"
    fi
  fi

  if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    gdctl set --logical-monitor --primary --scale $displayScaleFactor --monitor $display3 --mode ${virtual_display_width}x${virtual_display_height}@${virtual_display_refresh}.000
  elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    kscreen-doctor output.${KDEwDisplay1}.disable output.${KDEwDisplay2}.disable output.${display3}.enable output.${display3}.mode.${virtual_display_width}x${virtual_display_height}@${virtual_display_refresh} output.${display3}.scale.${displayScaleFactor}
  fi

  # Do not disturb
  sleep 1 # Short delay to allow messages from previous commands
  gsettings set org.gnome.desktop.notifications show-banners false

elif [[ $startOrEnd == 'end' ]]; then

  # Be disturbed again
  gsettings set org.gnome.desktop.notifications show-banners true

  # Enable vpn
  # mullvad connect

  # Enable real monitors again
  if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    gdctl set --logical-monitor --primary --monitor $display1 --mode 1920x1080@60.000+vrr --logical-monitor --monitor $display2 --right-of $display1
  elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    kscreen-doctor output.${display1}.enable output.${display2}.enable output.${display3}.disable
  fi

fi
