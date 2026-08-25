alias cls='clear'
alias gsts='git status'
alias gbranch='git branch --show-current'
alias gph='git push origin HEAD'
alias glog='git shortlog -s -n --all'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ========================
# GIT SHORTCUTS
# =======================

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
                echo: "Usage: grs <file>"
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
        printf " %-8s %s\n" "gsts" "Shows repo status"
        printf " %-8s %s\n" "gbranch" "Shows current branch"
        printf " %-8s %s\n" "gph" "Pushes to HEAD branch"
        printf " %-8s %s\n" "gnb" "Creates a new branch from the current one"
        printf " %-8s %s\n" "gco" "Switches to existing branch"
        printf " %-8s %s\n" "grs" "Retores file to git state"
        printf " %-8s %s\n" "glog" "Shows commit count per author"
        printf " %-8s %s\n" "gdb" "Deletes specific branch"
        echo
}
