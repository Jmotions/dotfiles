#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

# Added by wallselect installer
export PATH="/home/jahmad/.local/bin:$PATH"
  
(cat ~/.cache/wal/sequences &)
source ~/.cache/wal/colors-tty.sh
#source ~/.cache/ohmyposh_init.sh
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=24
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
fastfetch 
export DZR_CBC=g4el58wc0zvf9na1
export PATH=$PATH:$HOME/Desktop/zen
export PATH=$PATH:$HOME/.cargo/bin
export QT_QPA_PLATFORMTHEME=qt5ct
export EDITOR=helix

export PATH=$PATH:$HOME/.spicetify
export PATH=$PATH:$HOME/home/jahmad/spotifyd-linux-x86_64-full
export PATH=$PATH:$HOME/home/jahmad/wlx-overlay-s/target/release
alias gparted-root='xhost +SI:localuser:root && sudo QT_QPA_PLATFORM=xcb gparted && xhost -SI:localuser:root'

export PATH="$PATH:$HOME/wlx-overlay-s/target/release"

export PATH=$PATH:/home/jahmad/.spicetify
export PATH="/home/jahmad/cclip/build:$PATH"
export PATH="$HOME/bin:$PATH"
. "$HOME/.cargo/env"
#eval "$(oh-my-posh init bash --config ~/.poshthemes/catppuccin_frappe.omp.json)"
#eval "$(oh-my-posh init bash --config ~/.poshthemes/tokyonight_storm.omp.json)"

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
#[ -f /home/jahmad/Downloads/batch-beatmap-downloader-1.3.0 (2)/client/electron-forge/src/forge-5.2.4/node_modules/tabtab/.completions/electron-forge.bash ] && . /home/jahmad/Downloads/batch-beatmap-downloader-1.3.0 (2)/client/electron-forge/src/forge-5.2.4/node_modules/tabtab/.completions/electron-forge.bash
