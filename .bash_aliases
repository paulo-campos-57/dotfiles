# utils
alias cls='clear'

alias path='echo -e ${PATH//:/\\n}'
alias ff='find . -type f -name'

mcd() {
    [[ -z "$1" ]] && { echo "Usage: mcd <dir-name>"; return 1; }
    mkdir -p "$1" && cd "$1"
}

gohome() {
    cd "$HOME" && echo "You are here: $(pwd)"
}

# navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# file and net operation
alias myip='curl ifconfig.me; echo'
alias ports='netstat -tulanp'
alias diskh='df -h'
alias fmem='free -m -h'

# extract from any extension
extract() {
        if [ -f "$1" ]; then
                case "$1" in
                        *.tar.bz2)   tar xjf "$1"     ;;
                        *.tar.gz)    tar xzf "$1"     ;;
                        *.bz2)       bunzip2 "$1"     ;;
                        *.rar)       unrar x "$1"     ;;
                        *.gz)        gunzip "$1"      ;;
                        *.tar)       tar xvf "$1"     ;;
                        *.tbz2)      tar xjf "$1"     ;;
                        *.tgz)       tar xzf "$1"     ;;
                        *.zip)       unzip "$1"       ;;
                        *.Z)         uncompress "$1"  ;;
                        *.7z)        7z x "$1"        ;;
                        *)           echo "'$1' cannot be extracted via extract()" ;;
                esac
        else
                echo "'$1' is not a valid file"
        fi
}

# creates a backup file of any file
bak() {
        [[ -z "$1" ]] && { echo "Usage: bak <file>"; return 1; }
        cp -r "$1" "${1}.bak" && echo "Backup created: ${1}.bak"
}

# searches a process by name
psg() {
        [[ -z "$1"]] && { echo "Usage: psg <process-name>"; return 1; }
        ps aux | grep -v grep | grep -i --color=auto "$1"
}

# ========================
# GIT SHORTCUTS AND ALIASES
# =======================

alias gsts='git status'
alias gbranch='git branch --show-current'
alias gph='git push origin HEAD'
alias glog='git shortlog -s -n --all'
alias glogg='git log --graph --oneline --decorate --all'
alias gprune='git fetch --prune'
alias gfo='git fetch origin'

# create new branch
gnb() {
        if  [[ -z "$1" ]]; then
                echo "Usage: gnb <branch-name>"
                return 1
        fi

        git switch -c "$1"
}


# switch to existing branch
gco() {
        local branch="$1"

        [[ -z "$branch" ]] && {
                echo "Usage: gco <branch-name>"
                return 1
        }

        git switch "$branch"
}

# restore file
grs() {
        local file="$1"

        [[ -z "$file" ]] && {
                echo "Usage: grs <file>"
                return 1
        }

        git restore "$file"
}

# delete branch
gdb(){
        if [ -z "$1" ]; then
                echo "Usage: gdb <branch-name>"
                return 1
        fi

        current_branch=$(git branch --show-current)

        if [ "$1" = "$current_branch" ]; then
                echo "Error: you are currently on branch '$1'."
                echo "Checkout to another branch before deleting it."
                return 1
        fi

        echo "Deleting branch: $1"
        read -p "Are you sure? (y/N): " confirm

        if [[ "$confirm" =~ ^[yY]$ ]]; then
                git branch -D "$1"
        else
                echo "Aborted"
        fi
}

# list all git commands
ghelp() {
        echo "GIT SHORTCUTS:"
        echo
        # Info and status
        printf " %-8s %s\n" "gsts" "Shows repo status"
        printf " %-8s %s\n" "gbranch" "Shows current branch"
        printf " %-8s %s\n" "glog" "Shows commit count per author"
        printf " %-8s %s\n" "glogg" "Shows visual commit tree"
        echo
        # Branches flow
        printf " %-8s %s\n" "gco" "Switches to existing branch"
        printf " %-8s %s\n" "gnb" "Creates a new branch from current"
        printf " %-8s %s\n" "gph" "Pushes to HEAD branch"
        printf " %-8s %s\n" "gfo" "Fetches remote updates safely without merging"
        echo
        # Changes and maintenance
        printf " %-8s %s\n" "grs" "Restores file to git state"
        printf " %-8s %s\n" "gdb" "Deletes specific branch"
        printf " %-8s %s\n" "gprune" "Clears local refs of deleted branches"
        echo
}

# ========================
# DOCKER SHORTCUTS AND ALIASES
# =======================

alias dps='docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"'
alias dstopall='docker stop $(docker ps -a -q)'

# enters the bash/sh of an executing container
dexec() {
        [[ -z "$1" ]] && { echo "Usage: dexec <container-name|id>"; return 1; }
        local shell="${2:-bash}"
        docker exec -it "$1" "$shell"
}

# clears unused containers images and volumes
dclean() {
        echo "Cleaning unused docker resources..."
        docker system prune -a --volumes -f
}