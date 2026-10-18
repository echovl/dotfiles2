source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
function fish_greeting
   # smth smth
end

bind ctrl-space accept-autosuggestion

alias miseup='eval "$(mise activate fish)"'

set -x EDITOR "nvim"

starship init fish | source

fish_add_path -a "/home/echo/.foundry/bin"

fish_add_path "/home/echo/.bun/bin"

# set -g fish_key_bindings fish_vi_key_bindings


# >>> railway initialize >>>
test -f "$HOME/.railway/env.fish" && source "$HOME/.railway/env.fish"
# <<< railway initialize <<<
