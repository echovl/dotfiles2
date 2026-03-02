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
