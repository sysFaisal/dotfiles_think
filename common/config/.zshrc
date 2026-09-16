# Zsh Wiki: https://github.com/ohmyzsh/ohmyzsh/wiki

export ZSH="$HOME/.oh-my-zsh"

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="agnoster"

# Make completion case-sensitive (A ≠ a)
CASE_SENSITIVE="true"

# Treat hyphens and underscores as equivalent in completion ( - ~= _ )
HYPHEN_INSENSITIVE="true"

# Keep colors enabled for ls output
DISABLE_LS_COLORS="false"

# Prevent Oh My Zsh from auto-changing terminal window title
DISABLE_AUTO_TITLE="true"

# Enable command auto-correction for mistyped commands
ENABLE_CORRECTION="true"

# Keep magic functions enabled (URL/paste smart handling remains active)
DISABLE_MAGIC_FUNCTIONS="false"

# Show visual dots while waiting for completion results
COMPLETION_WAITING_DOTS="true"

# Keep checking untracked files for Git dirty status (more accurate, can be slower)
DISABLE_UNTRACKED_FILES_DIRTY="false"

# Set the format of timestamps in the history file (default: "mm/dd/yyyy")
HIST_STAMPS="yyyy-mm-dd"

# Plugins to load
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Quickly use script in local bin folder
export PATH="$HOME/.local/bin:$PATH"

# Custom environment variables
export GTK_USE_PORTAL=1
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORMTHEME=qt6ct
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$HOME/.dotnet:$HOME/.dotnet/tools
export PATH=$PATH:$HOME/go/bin
export PATH=$PATH:$HOME/.cargo/bin

# Set alias for common commands
alias zshconfig="nano ~/.zshrc"
alias reload="source ~/.zshrc"
alias haku="~/.local/bin/haku.sh"
alias menu="~/.local/bin/hakumenu.sh"
alias openconfig="~/.local/bin/open_config.sh"
alias pacsize='expac -H M "%m\t%n" $(\pacman -Qeq) | sort -h -r'
alias pacsizefull='expac -H M "%m\t%n" | sort -h -r'

# Lavat wrapper function
lavat() {
    local saved_cmd="$HOME/.local/state/haku_theme/lavat_command"
    if [ -f "$saved_cmd" ] && [ $# -eq 0 ]; then
        # Tidak ada parameter, jalankan command tersimpan
        eval "$(cat "$saved_cmd")"
    else
        # Ada parameter, jalankan lavat asli dengan parameter
        command lavat "$@"
    fi
}

# History quality-of-life
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

source $ZSH/oh-my-zsh.sh

# Override color for theme agnoster (oh-my-zsh)
export AGNOSTER_DIR_BG="white"
export AGNOSTER_GIT_DIRTY_BG="black"
export AGNOSTER_GIT_DIRTY_FG="white"
export AGNOSTER_CONTEXT_BG="#010101"
export AGNOSTER_CONTEXT_FG="blue"
export AGNOSTER_DIR_FG="#010101"
export AGNOSTER_DIR_BG="blue"

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

test -f "$HOME/.config/opencode/.env" && set -a && source "$HOME/.config/opencode/.env" && set +a

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# bun completions
[ -s "/home/sahaduka/.bun/_bun" ] && source "/home/sahaduka/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
