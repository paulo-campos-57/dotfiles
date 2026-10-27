#!/usr/bin/env bash

set -euo pipefail

#region Config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="$SCRIPT_DIR/aliases.sh"
TARGET_FILE="$HOME/.bash_aliases"
BASHRC="$HOME/.bashrc"

MANAGED_START="# BEGIN DOTFILES MANAGED"
MANAGED_END="# END DOTFILES MANAGED"

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
BOLD='\033[1m'
RESET='\033[0m'

info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $1"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $1" >&2
    exit 1
}

TEMP_DIR=""

cleanup() {
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR"
    fi
}

trap cleanup EXIT
#endregion

#region Requirement check
echo "=========================================="
echo "       Aliases & Functions Installer      "
echo "=========================================="
echo

echo "--- Checking Requirements ---"

for dependency in bash grep sed find chmod mktemp awk sort cp mv; do
    if ! command -v "$dependency" &>/dev/null; then
        error "$dependency is not installed!"
    fi

    success "$dependency found."
done

if [[ ! -f "$SOURCE_FILE" ]]; then
    error "File '$SOURCE_FILE' not found!"
fi

success "Aliases source file found."

if [[ ! -f "$BASHRC" ]]; then
    warning ".bashrc not found. Creating a new one."
    touch "$BASHRC"
fi

if [[ -f "$TARGET_FILE" ]]; then
    success "Existing .bash_aliases found."
else
    info "No existing .bash_aliases found."
fi
#endregion

#region Source syntax validation
echo
echo "--- Validating Source Syntax ---"

if ! bash -n "$SOURCE_FILE"; then
    error "Source aliases file contains Bash syntax errors!"
fi

success "Source aliases syntax validated."
#endregion

#region Temporary files
TEMP_DIR="$(mktemp -d)"

TEMP_FILE="$TEMP_DIR/bash_aliases"
MANAGED_FILE="$TEMP_DIR/managed"
EXISTING_COMMANDS="$TEMP_DIR/existing-commands"
MANAGED_COMMANDS="$TEMP_DIR/managed-commands"
FUNCTION_NAMES="$TEMP_DIR/function-names"
ALIAS_NAMES="$TEMP_DIR/alias-names"
ALIAS_DEFINITIONS="$TEMP_DIR/alias-definitions"
FUNCTION_DEFINITIONS="$TEMP_DIR/function-definitions"
BASE_FILE="$TEMP_DIR/base"

touch "$EXISTING_COMMANDS"
touch "$MANAGED_COMMANDS"
touch "$ALIAS_NAMES"
touch "$FUNCTION_NAMES"
#endregion

#region Existing managed commands
echo
echo "--- Checking Previous Installation ---"

if [[ -f "$TARGET_FILE" ]]; then
    awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
        $0 == start {
            inside = 1
            next
        }

        $0 == end {
            inside = 0
            next
        }

        inside {
            if ($0 ~ /^[[:space:]]*alias[[:space:]]+/) {
                line = $0
                sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
                sub(/=.*/, "", line)
                print line
            }

            if ($0 ~ /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/) {
                line = $0
                sub(/^[[:space:]]*/, "", line)
                sub(/[[:space:]]*\(\).*/, "", line)
                print line
            }
        }
    ' "$TARGET_FILE" | sort -u > "$MANAGED_COMMANDS"

    success "Previously managed commands identified."
else
    info "No previous managed installation found."
fi
#endregion

#region Existing commands
echo
echo "--- Loading Existing Commands ---"

# Read commands from a clean Bash environment.
# Existing managed definitions are filtered separately.
bash --noprofile --norc -c '
    compgen -A builtin
    compgen -A keyword
    compgen -A function
    compgen -c
' 2>/dev/null | sort -u > "$EXISTING_COMMANDS" || true

# Include aliases and functions defined in the user's Bash environment.
# Do not execute the potentially broken .bash_aliases file.
if [[ -f "$TARGET_FILE" ]]; then
    awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
        $0 == start {
            inside = 1
            next
        }

        $0 == end {
            inside = 0
            next
        }

        !inside {
            if ($0 ~ /^[[:space:]]*alias[[:space:]]+/) {
                line = $0
                sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
                sub(/=.*/, "", line)
                print line
            }

            if ($0 ~ /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/) {
                line = $0
                sub(/^[[:space:]]*/, "", line)
                sub(/[[:space:]]*\(\).*/, "", line)
                print line
            }
        }
    ' "$TARGET_FILE" >> "$EXISTING_COMMANDS"
fi

sort -u "$EXISTING_COMMANDS" -o "$EXISTING_COMMANDS"

success "Existing command names collected."
#endregion

#region Collision detection
check_and_register() {
    local item_type="$1"
    local name="$2"
    local choice

    # Commands installed by this installer are updated automatically,
    # unless another external command with the same name exists.
    if grep -Fxq -- "$name" "$MANAGED_COMMANDS" &&
       ! grep -Fxq -- "$name" "$EXISTING_COMMANDS"; then
        info "Updating previously installed $item_type '$name'."
        return 0
    fi

    if grep -Fxq -- "$name" "$EXISTING_COMMANDS"; then
        warning "Command '$name' already exists on your system."
        info "Type: $item_type"

        read -r -p \
            "Do you want to overwrite it with the repo version? (y/N): " \
            choice

        if [[ ! "${choice:-N}" =~ ^[yY]$ ]]; then
            info "'$name' skipped."
            return 1
        fi
    fi

    success "'$name' selected."
    return 0
}
#endregion

#region Source definition extraction
echo
echo "--- Extracting Source Definitions ---"

# Extract alias names and complete definitions using Bash itself.
# Bash parses the source file instead of relying on regular expressions
# to reconstruct alias values.

bash --noprofile --norc -c '
    source "$1"
    alias -p
' _ "$SOURCE_FILE" > "$ALIAS_DEFINITIONS"

sed -nE \
    's/^alias ([^=]+)=.*/\1/p' \
    "$ALIAS_DEFINITIONS" | sort -u > "$ALIAS_NAMES"

# Extract function names from the original file.
# The names are then resolved with Bash declare -f.
awk '
    /^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*[[:space:]]*\(\)[[:space:]]*\{/ {
        line = $0
        sub(/^[[:space:]]*/, "", line)
        sub(/[[:space:]]*\(\).*/, "", line)
        print line
    }
' "$SOURCE_FILE" | sort -u > "$FUNCTION_NAMES"

# Generate all function definitions using Bash's own parser.
bash --noprofile --norc -c '
    source "$1"

    while IFS= read -r function_name; do
        [[ -n "$function_name" ]] || continue

        if ! declare -F "$function_name" >/dev/null; then
            printf "[ERROR] Function not found: %s\n" \
                "$function_name" >&2
            exit 1
        fi

        declare -f "$function_name"
        printf "\n"
    done < "$2"
' _ "$SOURCE_FILE" "$FUNCTION_NAMES" > "$FUNCTION_DEFINITIONS"

success "Source definitions extracted successfully."
#endregion

#region Prepare installation
echo
echo "--- Preparing Installation ---"

if [[ -f "$TARGET_FILE" ]]; then
    # Preserve everything outside the installer-managed section.
    awk -v start="$MANAGED_START" -v end="$MANAGED_END" '
        $0 == start {
            inside = 1
            next
        }

        $0 == end {
            inside = 0
            next
        }

        !inside {
            print
        }
    ' "$TARGET_FILE" > "$BASE_FILE"
else
    touch "$BASE_FILE"
fi

cp "$BASE_FILE" "$TEMP_FILE"

{
    echo
    echo "$MANAGED_START"
    echo "# Automatically generated by dotfiles/scripts/install.sh"
    echo
} > "$MANAGED_FILE"

printf -v QUOTED_SCRIPT_DIR '%q' "$SCRIPT_DIR"

printf 'DOTFILES_SCRIPTS_DIR=%s\n\n' \
    "$QUOTED_SCRIPT_DIR" >> "$MANAGED_FILE"

success "Installation files prepared."
#endregion

#region Alias installation
echo
echo "--- Checking Aliases ---"

ALIAS_COUNT=0

while IFS= read -r alias_name; do
    [[ -n "$alias_name" ]] || continue

    if check_and_register "alias" "$alias_name"; then
        grep -F -- "alias $alias_name=" \
            "$ALIAS_DEFINITIONS" >> "$MANAGED_FILE"

        ((ALIAS_COUNT+=1))
    fi
done < "$ALIAS_NAMES"

success "$ALIAS_COUNT aliases selected."
#endregion

#region Function installation
echo
echo "--- Checking Functions ---"

FUNCTION_COUNT=0

while IFS= read -r function_name; do
    [[ -n "$function_name" ]] || continue

    if check_and_register "function" "$function_name"; then
        # Extract the exact function definition from Bash.
        # No manual brace counting is performed.
        bash --noprofile --norc -c '
            source "$1"
            declare -f "$2"
        ' _ "$SOURCE_FILE" "$function_name" >> "$MANAGED_FILE"

        echo >> "$MANAGED_FILE"

        ((FUNCTION_COUNT+=1))
    fi
done < "$FUNCTION_NAMES"

success "$FUNCTION_COUNT functions selected."
#endregion

#region Generated file syntax validation
echo
echo "--- Validating Generated Bash Syntax ---"

echo "$MANAGED_END" >> "$MANAGED_FILE"

cat "$MANAGED_FILE" >> "$TEMP_FILE"

if ! bash -n "$MANAGED_FILE"; then
    error "Generated managed definitions contain syntax errors!"
fi

success "Managed definitions syntax validated."

if ! bash -n "$TEMP_FILE"; then
    error "Generated .bash_aliases contains syntax errors. Installation aborted!"
fi

success "Complete .bash_aliases syntax validated."
#endregion

#region Install aliases
echo
echo "--- Installing Aliases and Functions ---"

# Preserve the original file permissions when possible.
if [[ -f "$TARGET_FILE" ]]; then
    chmod --reference="$TARGET_FILE" "$TEMP_FILE"
else
    chmod 644 "$TEMP_FILE"
fi

# Both files were validated before replacing the user's configuration.
mv -f -- "$TEMP_FILE" "$TARGET_FILE"

success "Aliases and functions installed in $TARGET_FILE."
#endregion

#region Script discovery
echo
echo "--- Discovering Utility Scripts ---"

mapfile -d '' -t UTILITY_SCRIPTS < <(
    find "$SCRIPT_DIR" \
        -type f \
        -name "*.sh" \
        ! -name "install.sh" \
        ! -name "aliases.sh" \
        -print0
)

SCRIPT_COUNT="${#UTILITY_SCRIPTS[@]}"

if (( SCRIPT_COUNT == 0 )); then
    warning "No utility scripts found."
else
    success "$SCRIPT_COUNT utility scripts found."

    echo

    for script in "${UTILITY_SCRIPTS[@]}"; do
        relative_path="${script#"$SCRIPT_DIR"/}"

        if [[ -x "$script" ]]; then
            success "$relative_path (executable)"
        else
            warning "$relative_path (not executable)"
        fi
    done
fi
#endregion

#region Script permissions
if (( SCRIPT_COUNT > 0 )); then
    echo
    echo "--- Configure Script Permissions ---"
    echo

    info "The installer can grant execution permission to discovered scripts."
    info "Only files inside the dotfiles scripts directory will be affected."

    read -r -p \
        "Grant execution permission to all utility scripts? (y/N): " \
        PERMISSION_CHOICE

    if [[ "${PERMISSION_CHOICE:-N}" =~ ^[yY]$ ]]; then
        PERMISSION_SUCCESS=0
        PERMISSION_FAILED=0

        for script in "${UTILITY_SCRIPTS[@]}"; do
            relative_path="${script#"$SCRIPT_DIR"/}"

            if [[ -x "$script" ]]; then
                success "$relative_path already executable."
                continue
            fi

            if chmod u+x "$script"; then
                success "Execution permission granted: $relative_path"
                ((PERMISSION_SUCCESS+=1))
            else
                warning "Could not update permissions: $relative_path"
                ((PERMISSION_FAILED+=1))
            fi
        done

        success "$PERMISSION_SUCCESS scripts updated."

        if (( PERMISSION_FAILED > 0 )); then
            warning "$PERMISSION_FAILED scripts could not be updated."
        fi
    else
        info "Script permission changes skipped."
    fi
fi
#endregion

#region Bash configuration
echo
echo "--- Configuring Bash ---"

SOURCE_CMD='[ -f "$HOME/.bash_aliases" ] && . "$HOME/.bash_aliases"'

if ! grep -Fq '.bash_aliases' "$BASHRC"; then
    {
        echo
        echo "# Load custom aliases and functions"
        echo "$SOURCE_CMD"
    } >> "$BASHRC"

    success "Aliases loader added to .bashrc."
else
    success ".bashrc already references .bash_aliases."
fi
#endregion

#region Summary
echo
echo "=========================================="
echo "           Installation Summary           "
echo "=========================================="
echo

success "$ALIAS_COUNT aliases configured."
success "$FUNCTION_COUNT functions configured."
success "$SCRIPT_COUNT utility scripts discovered."

info "Scripts directory: $SCRIPT_DIR"
info "Aliases file: $TARGET_FILE"

echo
echo -e "${GREEN}Success!${RESET} Installation completed."
echo
echo -e "Run ${BOLD}source ~/.bashrc${RESET} to apply changes."
echo
#endregion
