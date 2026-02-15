#!/bin/bash

set -e
set -x

# Log everything to logger
script_name=$(basename "$0")
exec 1> >(logger -s -t "$script_name") 2>&1

startOrEnd="$1"               # "start" | "end"
disableScaling="$2"           # "no-scaling"
virtual_display_width="1920"  # Default
virtual_display_height="1080" # Default
virtual_display_refresh="60"  # Default

# Display connectors
GNOME_primary_display="DP-1"
GNOME_secondary_display="HDMI-1"
GNOME_virtual_display="DP-3" # virtual-display
# GNOME_service_monitor="Meta-0"    # Virtual gnome monitor

KDE_primary_display="DP-1"
KDE_secondary_display="HDMI-A-1"
KDE_virtual_display="DP-3" # virtual-display

if [ "$XDG_SESSION_TYPE" = "x11" ]; then
  echo "X11 is no longer supported"
  exit 1
fi

if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
  primary_display="$GNOME_primary_display"
  secondary_display="$GNOME_secondary_display"
  virtual_display="$GNOME_virtual_display"

elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
  primary_display="$KDE_primary_display"
  secondary_display="$KDE_secondary_display"
  virtual_display="$KDE_virtual_display"
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

  # Enable virtual-display
  virtual-display enable --connector "$virtual_display"

  if [ "$XDG_CURRENT_DESKTOP" = "GNOME" ]; then
    gdctl set --logical-monitor --primary --scale $displayScaleFactor --monitor "$virtual_display" --mode "${virtual_display_width}"x"${virtual_display_height}"@"${virtual_display_refresh}".000
  elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    kscreen-doctor output."${primary_display}".disable output."${secondary_display}".disable output."${virtual_display}".enable output."${virtual_display}".mode."${virtual_display_width}"x"${virtual_display_height}"@"${virtual_display_refresh}" output."${virtual_display}".scale.${displayScaleFactor}
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
    gdctl set --logical-monitor --primary --monitor "$primary_display" --mode 1920x1080@60.000+vrr --logical-monitor --monitor "$secondary_display" --right-of "$primary_display"
  elif [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    kscreen-doctor output."${primary_display}".enable output."${secondary_display}".enable output."${virtual_display}".disable
  fi

  # Disable virtual-display
  virtual-display disable

fi
