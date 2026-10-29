source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
   # smth smth
end

bind ctrl-space accept-autosuggestion

alias miseup='eval "$(mise activate fish)"'

set -x EDITOR "nvim"

# The full init in one process; the short form runs starship twice per shell.
starship init fish --print-full-init | source
# starship.toml has no right_format, so skip `starship prompt --right` at
# every prompt.
function fish_right_prompt; end

fish_add_path -a "/home/echo/.foundry/bin"

fish_add_path "/home/echo/.bun/bin"

# set -g fish_key_bindings fish_vi_key_bindings



# >>> railway initialize >>>
source "$HOME/.railway/env.fish"
# <<< railway initialize <<<
