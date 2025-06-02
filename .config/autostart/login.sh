#!/bin/bash

script_dir=$(dirname "$0")
script_name=$(basename $0)

# Log everything to logger
exec 1> >(logger -s -t $script_name) 2>&1

function notify_error() {
  echo "'$1' failed to run"
  notify-send -a "$script_name" "Command in $script_name failed" "' $1 ' failed to run"
}

function run_command() {
  local app="$1"
  local clean_string=${app//[\/]/\\/}
  local clean_string2=$(echo $clean_string | awk -F "&& " '{ print $NF }')
  shift
  $@ 1> >(sed "s/^/[$clean_string2] /") 2>&1
}

# Get login commands if defined
login_commands_script="$script_dir/login_commands.sh"
login_commands=()
if [ -f $login_commands_script ]; then
  echo "Sourcing $login_commands_script"
  source $login_commands_script
else
  echo "No login commands found in $login_commands_script"
fi

# Define list of startup apps
start_apps=("${login_commands[@]}") # from login_commands.sh

# Run commands
echo "Running $script_name"
pids=""
for app in "${start_apps[@]}"; do
  echo "Running: '$app'"
  run_command "$app" eval $app || notify_error "$app" &
  pids="$pids $!"
done

# Wait for all commands to finish
if [ -n "$pids" ]; then sleep 1 && wait $pids; fi

echo "Exit $script_name"
exit 0
