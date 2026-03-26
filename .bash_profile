#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc
export GBM_BACKEND=nvidia-drm
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER_ALLOW_SOFTWARE=1
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=24

export PATH=$PATH:/home/jahmad/.spicetify
. "$HOME/.cargo/env"
