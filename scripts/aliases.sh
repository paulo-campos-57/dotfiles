
#!/usr/bin/env bash

#region System utilities
alias cls='clear'

alias path='printf "%s\n" "${PATH//:/$'\''\n'\''}"'
alias ff='find . -type f -name'

mcd() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: mcd <dir-name>"
        return 1
    fi

    mkdir -p -- "$1" && cd -- "$1"
}

gohome() {
    cd -- "$HOME" || return 1
    echo "You are here: $(pwd)"
}
#endregion

#region Navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
#endregion

#region File and network operations
alias myip='curl -fsS https://ifconfig.me; echo'
alias ports='ss -tulnp'
alias diskh='df -h'
alias fmem='free -h'

extract() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: extract <file>"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "[ERROR] '$1' is not a valid file." >&2
        return 1
    fi

    case "$1" in
        *.tar.bz2|*.tbz2)
            tar -xjf "$1"
            ;;
        *.tar.gz|*.tgz)
            tar -xzf "$1"
            ;;
        *.tar)
            tar -xvf "$1"
            ;;
        *.bz2)
            bunzip2 -- "$1"
            ;;
        *.gz)
            gunzip -- "$1"
            ;;
        *.zip)
            unzip -- "$1"
            ;;
        *.rar)
            unrar x "$1"
            ;;
        *.7z)
            7z x "$1"
            ;;
        *.Z)
            uncompress -- "$1"
            ;;
        *)
            echo "[ERROR] Unsupported archive format: '$1'." >&2
            return 1
            ;;
    esac
}

bak() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: bak <file|directory>"
        return 1
    fi

    if [[ ! -e "$1" ]]; then
        echo "[ERROR] File or directory not found: '$1'." >&2
        return 1
    fi

    local backup="${1}.bak"

    if [[ -e "$backup" ]]; then
        echo "[ERROR] Backup already exists: '$backup'." >&2
        return 1
    fi

    cp -a -- "$1" "$backup" || return 1
    echo "[OK] Backup created: $backup"
}

psg() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: psg <process-name>"
        return 1
    fi

    ps aux | awk -v pattern="$1" '
        BEGIN {
            IGNORECASE = 1
        }
        NR == 1 {
            print
            next
        }
        {
            line = tolower($0)
            search = tolower(pattern)

            if (index(line, search) > 0)
                print
        }
    '
}
#endregion

#region Git shortcuts and aliases
alias gsts='git status'
alias gbranch='git branch --show-current'
alias gph='git push origin HEAD'
alias glog='git shortlog -s -n --all'
alias glogg='git log --graph --oneline --decorate --all'
alias gprune='git fetch --prune'
alias gfo='git fetch origin'

gnb() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: gnb <branch-name>"
        return 1
    fi

    git switch -c "$1"
}

gco() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: gco <branch-name>"
        return 1
    fi

    git switch "$1"
}

grs() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: grs <file>"
        return 1
    fi

    git restore -- "$1"
}

gdb() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: gdb <branch-name>"
        return 1
    fi

    local branch="$1"
    local current_branch
    local confirm

    current_branch="$(git branch --show-current)" || return 1

    if [[ "$branch" == "$current_branch" ]]; then
        echo "[ERROR] You are currently on branch '$branch'." >&2
        echo "Switch to another branch before deleting it."
        return 1
    fi

    echo "[WARNING] Force deleting branch: $branch"

    read -r -p "Are you sure? (y/N): " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        git branch -D -- "$branch"
    else
        echo "[INFO] Operation aborted."
    fi
}
#endregion

#region Git report configuration
_git_reports_dir() {
    if [[ -z "${DOTFILES_SCRIPTS_DIR:-}" ]]; then
        echo "[ERROR] DOTFILES_SCRIPTS_DIR is not configured!" >&2
        echo "Run the dotfiles installer again." >&2
        return 1
    fi

    local scripts_dir="$DOTFILES_SCRIPTS_DIR"

    if [[ ! -d "$scripts_dir/git" ]]; then
        echo "[ERROR] Git scripts directory not found: $scripts_dir/git" >&2
        return 1
    fi

    printf '%s\n' "$scripts_dir/git"
}

_run_git_report() {
    if [[ $# -lt 1 ]]; then
        echo "[ERROR] Report script name is required!" >&2
        return 1
    fi

    local script_name="$1"
    shift

    if [[ $# -gt 2 ]]; then
        echo "Usage: <report-command> [repository] [output-directory]" >&2
        return 1
    fi

    local scripts_dir
    local script_path
    local repo
    local output

    scripts_dir="$(_git_reports_dir)" || return 1
    script_path="$scripts_dir/$script_name"

    if [[ ! -f "$script_path" ]]; then
        echo "[ERROR] Script not found: $script_path" >&2
        return 1
    fi

    if ! command -v git &>/dev/null; then
        echo "[ERROR] Git is not installed!" >&2
        return 1
    fi

    repo="${1:-.}"

    if ! git -C "$repo" rev-parse --is-inside-work-tree &>/dev/null; then
        echo "[ERROR] Directory '$repo' is not a valid Git repository!" >&2
        return 1
    fi

    repo="$(git -C "$repo" rev-parse --show-toplevel)" || return 1

    if [[ $# -ge 2 ]]; then
        output="$2"
    else
        output="$repo/git-reports/${script_name%.sh}"
    fi

    bash "$script_path" "$repo" "$output"
}
#endregion

#region Git report commands
gcommits() {
    _run_git_report "commit-report.sh" "$@"
}

gbranches() {
    _run_git_report "branch-report.sh" "$@"
}

gcontributors() {
    _run_git_report "contributor-report.sh" "$@"
}

gchurn() {
    _run_git_report "code-churn.sh" "$@"
}
#endregion

#region Git help
ghelp() {
    echo "=========================================="
    echo "             Git Shortcuts                "
    echo "=========================================="
    echo

    printf " %-16s %s\n" "COMMAND" "DESCRIPTION"
    echo "------------------------------------------------------------"

    printf " %-16s %s\n" "gsts" "Shows repository status"
    printf " %-16s %s\n" "gbranch" "Shows current branch"
    printf " %-16s %s\n" "glog" "Shows commit count per author"
    printf " %-16s %s\n" "glogg" "Shows visual commit tree"

    echo
    echo "--- Branch Operations ---"
    echo

    printf " %-16s %s\n" "gco" "Switches to an existing branch"
    printf " %-16s %s\n" "gnb" "Creates a new branch"
    printf " %-16s %s\n" "gdb" "Force deletes a local branch"

    echo
    echo "--- Remote Operations ---"
    echo

    printf " %-16s %s\n" "gph" "Pushes current HEAD to origin"
    printf " %-16s %s\n" "gfo" "Fetches updates from origin"
    printf " %-16s %s\n" "gprune" "Fetches and prunes stale remote refs"

    echo
    echo "--- File Operations ---"
    echo

    printf " %-16s %s\n" "grs" "Restores a file from Git"

    echo
    echo "--- Reports ---"
    echo

    printf " %-16s %s\n" "gcommits" "Generates commit statistics"
    printf " %-16s %s\n" "gbranches" "Analyzes repository branches"
    printf " %-16s %s\n" "gcontributors" "Analyzes contributor activity"
    printf " %-16s %s\n" "gchurn" "Analyzes code churn"
    printf " %-16s %s\n" "greports" "Displays report commands"
}
#endregion

#region Git report help
greports() {
    echo "=========================================="
    echo "             Git Report Tools             "
    echo "=========================================="
    echo

    printf " %-16s %s\n" "COMMAND" "DESCRIPTION"
    echo "------------------------------------------------------------"

    printf " %-16s %s\n" "gcommits" "Generates commit statistics"
    printf " %-16s %s\n" "gbranches" "Analyzes repository branches"
    printf " %-16s %s\n" "gcontributors" "Analyzes contributor activity"
    printf " %-16s %s\n" "gchurn" "Analyzes file modification frequency"

    echo
    echo "Usage:"
    echo "  <command> [repository] [output-directory]"
    echo
    echo "Examples:"
    echo "  gcommits"
    echo "  gbranches /path/to/repository"
    echo "  gcontributors /path/to/repository"
    echo "  gchurn /path/to/repository /path/to/output"
}
#endregion

#region Docker shortcuts and aliases
alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'

dstopall() {
    if ! command -v docker &>/dev/null; then
        echo "[ERROR] Docker is not installed!" >&2
        return 1
    fi

    local containers

    containers="$(docker ps -q)" || return 1

    if [[ -z "$containers" ]]; then
        echo "[INFO] No running containers found."
        return 0
    fi

    echo "[WARNING] Stopping all running containers..."

    docker stop $containers
}

dexec() {
    if [[ -z "${1:-}" ]]; then
        echo "Usage: dexec <container-name|id> [shell]"
        return 1
    fi

    local container="$1"
    local shell="${2:-bash}"

    docker exec -it "$container" "$shell"
}

dclean() {
    local confirm

    echo "[WARNING] This will remove unused Docker resources,"
    echo "including unused images, containers, networks and volumes."
    echo

    read -r -p "Are you sure? (y/N): " confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        docker system prune -a --volumes -f
    else
        echo "[INFO] Operation aborted."
    fi
}
#endregion
