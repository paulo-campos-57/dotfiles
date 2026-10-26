#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/aliases.sh"
TARGET_FILE="$HOME/.bash_aliases"
BASHRC="$HOME/.bashrc"

if [ ! -f "$SOURCE_FILE" ]; then
    echo -e "\033[31m[ERROR]\033[0m File $SOURCE_FILE not found!"
fi

if [ -f "$BASHRC" ]; then
    source "$BASHRC" 2>/dev/null
fi

echo "=========================================="
echo "    Aliases & Functions Installer         "
echo "=========================================="
echo

TEMP_FILE=$(mktemp)

check_and_register() {
    local type="$1"
    local name="$2"
    local install_item=true

    if type "$name" &>/dev/null; then
        local existing_type
        existing_type=$(type -t "$name")
        echo -e "\033[33m[COLLISION]\033[0m '$name' already exists on your system (Type: $existing_type)."
        read -p "Do you want to overwrite it with the repo version? (y/N): " choice
        [[ "$choice" =~ ^[yY]$ ]] || install_item=false
    fi

    if [ "$install_item" = true ]; then
        echo -e "\033[32m[OK]\033[0m '$name' kept."
        return 0
    else
        echo -e "\033[34m[SKIPPED]\033[0m '$name' ignored."
        return 1
    fi
}

echo "--- Checking Aliases and Functions ---"

ALIASES=$(grep -E '^\s*alias ' "$SOURCE_FILE" | sed -E 's/^\s*alias ([^=]+)=.*/\1/')

FUNCTIONS=$(grep -E '^\s*([a-zA-Z0-9_-]+)\s*\(\)\s*\{' "$SOURCE_FILE" | sed -E 's/^\s*([a-zA-Z0-9_-]+).*/\1/')

grep -E '^\s*#|^\s*$' "$SOURCE_FILE" > "$TEMP_FILE"

for a in $ALIASES; do
    if check_and_register "alias" "$a"; then
        grep -E "^\s*alias $a=" "$SOURCE_FILE" >> "$TEMP_FILE"
    fi
done

for f in $FUNCTIONS; do
    if check_and_register "function" "$f"; then
        sed -n "/^\s*$f()/,/^\s*}/p" "$SOURCE_FILE" >> "$TEMP_FILE"
    fi
done

mv "$TEMP_FILE" "$TARGET_FILE"
echo -e "\n\033[32mSuccess!\033[0m Settings saved to \033[1m$TARGET_FILE\033[0m."

SOURCE_CMD="[ -f ~/.bash_aliases ] && . ~/.bash_aliases"

if ! grep -Fq ".bash_aliases" "$BASHRC" 2>/dev/null; then
    echo -e "\n$SOURCE_CMD" >> "$BASHRC"
    echo -e "\033[32mLink added to your .bashrc!\033[0m"
fi

echo -e "\nDone! Run \033[1msource ~/.bashrc\033[0m to apply changes to the current terminal."