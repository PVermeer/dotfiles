# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# Aliases
alias dotfiles='/usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME"'

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Bash auto completion
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

cat >>~/.inputrc <<'EOF'
"\e[A": history-search-backward
"\e[B": history-search-forward
EOF

# bash theme - inspired by https://github.com/ohmyzsh/ohmyzsh/blob/master/themes/robbyrussell.zsh-theme
__bash_prompt() {

    local blue='\[\033[1;34m\]'
    local teal='\[\033[1;36m\]'
    local green='\[\033[1;32m\]'
    local yellow='\[\033[1;33m\]'
    local orange='\[\033[38:5:202m\]'
    local red='\[\033[1;31m\]'
    local pink='\[\033[38:5:205m\]'
    local purple='\[\033[1;35m\]'
    local slate='\[\033[38:5:67m\]'
    local removecolor='\[\033[0m\]'
    local arrow='➜'
    local themecolor=$purple

    local THEME=$(gsettings get org.gnome.desktop.interface accent-color || echo "'purple'")
    THEME=${THEME//\'/}

    case $THEME in
    "blue")
        themecolor=$blue
        ;;
    "green")
        themecolor=$green
        ;;
    "orange")
        themecolor=$orange
        ;;
    "pink")
        themecolor=$pink
        ;;
    "purple")
        themecolor=$purple
        ;;
    "red")
        themecolor=$red
        ;;
    "slate")
        themecolor=$slate
        ;;
    "teal")
        themecolor=$teal
        ;;
    "yellow")
        themecolor=$yellow
        ;;
    *)
        themecolor=$purple
        ;;
    esac

    local issubshell=false
    local hostname=""
    local os=""
    local osversion=""
    local hostpart=""
    local containertype=""
    local userpart="\u"
    local gitbranch=""
    local bashend="\$"

    # Check shell level (not reliable, but something)
    if [ $SHLVL -ne 1 ]; then
        issubshell=true
    fi

    # Check hostname; Don't show the hostname when not in a subshell

    # Container environment hostname
    if [ -f /run/.containerenv ]; then
        source /run/.containerenv
        hostname=$name
        issubshell=true

        source /etc/os-release
        os=$ID
        osversion=$VERSION_ID

        # Check for container provider
        if [ $(command -v distrobox-export) ]; then
            containertype="distrobox"
        elif [ -n "$(printenv | grep TOOLBOX)" ]; then
            containertype="toolbox"
        elif [ -n "$(printenv container)" ]; then
            containertype=$(printenv container)
        else
            containertype=$engine # From /run/.containerenv
        fi
    fi

    # Sandbox environment hostname
    if [ -f /.flatpak-info ]; then
        hostname=$(cat /.flatpak-info | grep name= | awk -F '=' '{print $2}' | awk -F '.' '{print $NF}')
        issubshell=true
        containertype="flatpak"
    elif [ "$SNAP" ]; then
        # Don't use snaps, so have no idea how to get the snap app name
        hostname="snap"
        containertype=""
        issubshell=true
    fi

    # Create hostname part for prompt only in subshell
    if [ "$issubshell" = true ]; then

        # Set container provider if found
        if [ "${containertype}" ]; then
            hostpart+=" ${removecolor}${arrow} ${red}${containertype}"
        fi

        hostpart+=" ${orange}"
        if [ "${hostname}" ]; then
            hostpart+="($hostname"
            if [ "${osversion}" ]; then
                hostpart+=" $osversion)"
            else
                hostpart+=")"
            fi
        elif [ "${os}" ] && [ "${osversion}" ]; then
            hostpart+="($os $osversion)"
        else
            hostpart+="(subshell)"
        fi
    fi

    # Check for a git brance
    gitbranch="\$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/(\1) /')"
    gitbranchcolor=$([ "$themecolor" = "$red" ] && echo $orange || echo $red)

    # Build prompt string
    PS1="\n${green}${userpart}${hostpart} ${removecolor}${arrow} ${themecolor}\w ${gitbranchcolor}${gitbranch}${blue}${bashend}${removecolor} "

    unset -f __bash_prompt
}
__bash_prompt

# Run flatpaks by name via flatrun <APP NAME>
function flatrun() {
    app_name="$1"
    shift
    app_id=$(flatpak list | grep -F -i "$app_name" | awk '{for(i=1;i<=NF;i++){ if($i ~ /\S+\.\S*/){print $i; break;} } }')
    flatpak run $app_id $@
}
