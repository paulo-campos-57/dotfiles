#!/usr/bin/env bash

set -euo pipefail

#region Config
REPO="${1:-.}"
OUTPUT="${2:-./branch-report}"

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
#endregion

#region Requirement check
echo "=========================================="
echo "        Git Branch Report Generator       "
echo "=========================================="
echo

echo "--- Checking Requirements ---"

for dependency in git awk sort date; do
    if ! command -v "$dependency" &>/dev/null; then
        error "$dependency is not installed!"
    fi

    success "$dependency found."
done

if ! git -C "$REPO" rev-parse --is-inside-work-tree &>/dev/null; then
    error "Directory '$REPO' is not a valid Git repository!"
fi

success "Git repository found."

REPO="$(git -C "$REPO" rev-parse --show-toplevel)"

if command -v gnuplot &>/dev/null; then
    HAS_GNUPLOT=true
    success "Gnuplot found."
else
    HAS_GNUPLOT=false
    warning "Gnuplot not found. CSV reports will still be generated."
fi
#endregion

#region Analysis options
echo
echo "--- Select Branch Scope ---"
echo
echo "  1) Local branches"
echo "  2) Remote-tracking branches"
echo "  3) Both (default)"
echo

read -r -p "Select an option [1-3] (default: 3): " SCOPE || true

case "${SCOPE:-3}" in
    1)
        REF_PREFIX="refs/heads"
        SCOPE_LABEL="Local"
        ;;

    2)
        REF_PREFIX="refs/remotes"
        SCOPE_LABEL="Remote-tracking"
        ;;

    3)
        REF_PREFIX=""
        SCOPE_LABEL="Both"
        ;;

    *)
        error "Invalid scope option."
        ;;
esac

success "Scope selected: $SCOPE_LABEL"

echo
echo "--- Select Base Branch ---"

DEFAULT_BASE="$(git -C "$REPO" symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true)"

if [[ -z "$DEFAULT_BASE" ]]; then
    for candidate in main master development; do
        if git -C "$REPO" show-ref --verify --quiet "refs/heads/$candidate"; then
            DEFAULT_BASE="$candidate"
            break
        fi
    done
fi

read -r -p "Base branch [${DEFAULT_BASE:-required}]: " BASE || true

BASE="${BASE:-$DEFAULT_BASE}"

if [[ -z "$BASE" ]]; then
    error "A base branch is required."
fi

BASE_REF="$(git -C "$REPO" rev-parse --verify --quiet "${BASE}^{commit}" 2>/dev/null || true)"

if [[ -z "$BASE_REF" ]]; then
    error "Base '$BASE' does not resolve to a commit."
fi

BASE_FULL_REF="$(git -C "$REPO" rev-parse --symbolic-full-name "$BASE" 2>/dev/null || true)"

success "Base branch selected: $BASE"

echo
echo "--- Inactivity Threshold ---"

read -r -p "Inactive after how many days? [30]: " STALE_DAYS || true

STALE_DAYS="${STALE_DAYS:-30}"

if ! [[ "$STALE_DAYS" =~ ^[0-9]+$ ]]; then
    error "Inactive threshold must be a nonnegative integer."
fi

success "Inactivity threshold: $STALE_DAYS days"

echo
echo "--- Remote References ---"

read -r -p "Fetch remote references first? (y/N): " FETCH || true

if [[ "${FETCH:-N}" =~ ^[yY]$ ]]; then
    info "Fetching remote references..."

    if git -C "$REPO" fetch --all --prune; then
        success "Remote references updated."

        BASE_REF="$(git -C "$REPO" rev-parse --verify --quiet "${BASE}^{commit}" 2>/dev/null || true)"

        if [[ -z "$BASE_REF" ]]; then
            error "Base '$BASE' is no longer available after fetch."
        fi
    else
        warning "Fetch failed. Continuing with locally available references."
    fi
fi
#endregion

#region Output configuration
mkdir -p "$OUTPUT"

OUTPUT="$(cd "$OUTPUT" && pwd)"

CSV="$OUTPUT/branches.csv"
SUMMARY="$OUTPUT/summary.dat"

printf 'scope,branch,last_commit,days_inactive,ahead,behind,merged,status\n' > "$CSV"

success "Output directory configured."
#endregion

#region Branch analysis
echo
echo "--- Analyzing Branches ---"

info "Repository: $REPO"
info "Base: $BASE"
info "Scope: $SCOPE_LABEL"
info "Inactive threshold: $STALE_DAYS days"
info "Output directory: $OUTPUT"
info "Reading branch references..."

NOW="$(date +%s)"

TOTAL=0
ACTIVE=0
STALE=0
MERGED=0
DIVERGED=0
UP_TO_DATE=0

while IFS= read -r REF; do
    [[ -n "$REF" ]] || continue
    [[ "$REF" == refs/remotes/*/HEAD ]] && continue

    if [[ "$REF" == refs/heads/* ]]; then
        BRANCH="${REF#refs/heads/}"
    else
        BRANCH="${REF#refs/remotes/}"
    fi

    HASH="$(git -C "$REPO" rev-parse "$REF^{commit}")"

    if [[ "$REF" == "$BASE_FULL_REF" ]]; then
        continue
    fi

    LAST_TS="$(git -C "$REPO" log -1 --format=%ct "$REF")"
    LAST_DATE="$(git -C "$REPO" log -1 --format=%cs "$REF")"

    AGE=$(( (NOW - LAST_TS) / 86400 ))

    if (( AGE < 0 )); then
        AGE=0
    fi

    read -r BEHIND AHEAD < <(
        git -C "$REPO" rev-list --left-right --count "$BASE_REF...$HASH"
    )

    if git -C "$REPO" merge-base --is-ancestor "$HASH" "$BASE_REF"; then
        STATUS="MERGED"
        ((MERGED+=1))

    elif (( AHEAD > 0 && BEHIND > 0 )); then
        STATUS="DIVERGED"
        ((DIVERGED+=1))

    elif (( AGE >= STALE_DAYS )); then
        STATUS="STALE"
        ((STALE+=1))

    elif (( AHEAD > 0 )); then
        STATUS="ACTIVE"
        ((ACTIVE+=1))

    else
        STATUS="UP_TO_DATE"
        ((UP_TO_DATE+=1))
    fi

    ((TOTAL+=1))

    if [[ "$STATUS" == "MERGED" ]]; then
        MERGED_VALUE="yes"
    else
        MERGED_VALUE="no"
    fi

    printf '"%s","%s",%s,%d,%d,%d,%s,%s\n' \
        "$SCOPE_LABEL" \
        "$BRANCH" \
        "$LAST_DATE" \
        "$AGE" \
        "$AHEAD" \
        "$BEHIND" \
        "$MERGED_VALUE" \
        "$STATUS" >> "$CSV"

done < <(
    if [[ -n "$REF_PREFIX" ]]; then
        git -C "$REPO" for-each-ref \
            --format='%(refname)' "$REF_PREFIX"
    else
        git -C "$REPO" for-each-ref \
            --format='%(refname)' refs/heads refs/remotes
    fi | sort -u
)

printf 'MERGED %d\nDIVERGED %d\nSTALE %d\nACTIVE %d\nUP_TO_DATE %d\n' \
    "$MERGED" \
    "$DIVERGED" \
    "$STALE" \
    "$ACTIVE" \
    "$UP_TO_DATE" > "$SUMMARY"

success "$TOTAL branches analyzed."

if (( DIVERGED > 0 )); then
    warning "$DIVERGED branches diverged from the base."
fi

if (( STALE > 0 )); then
    warning "$STALE branches exceeded the inactivity threshold."
fi
#endregion

#region Charts
echo
echo "--- Generating Charts ---"

if [[ "$HAS_GNUPLOT" == true && "$TOTAL" -gt 0 ]]; then
    info "Generating branch status distribution chart..."

    gnuplot <<EOF
set terminal pngcairo size 1200,650 enhanced font "Sans,12"
set output "$OUTPUT/branch-status.png"

set title "Branch Status Distribution"
set ylabel "Number of Branches"

set style data histograms
set style histogram clustered gap 2
set style fill solid 0.85 border -1

set boxwidth 0.65
set grid ytics
set key off
set yrange [0:*]

plot "$SUMMARY" using 2:xtic(1) lc rgb "#DA291C" notitle
EOF

    success "Branch status chart generated."
else
    warning "Chart skipped (gnuplot unavailable or no branches found)."
fi
#endregion

#region Summary
echo
echo "=========================================="
echo "             Branch Summary               "
echo "=========================================="
echo

info "Base branch: $BASE"
info "Scope: $SCOPE_LABEL"
info "Inactivity threshold: $STALE_DAYS days"

echo
printf "${BOLD}%-16s %8s${RESET}\n" \
    "STATUS" "BRANCHES"

echo "--------------------------"

awk '{
    printf "%-16s %8d\n", $1, $2
}' "$SUMMARY"

echo "--------------------------"

printf "${BOLD}%-16s %8d${RESET}\n" \
    "TOTAL" "$TOTAL"

echo
echo "=========================================="
echo "             Generated Files              "
echo "=========================================="
echo

success "branches.csv"
success "summary.dat"

if [[ "$HAS_GNUPLOT" == true && "$TOTAL" -gt 0 ]]; then
    success "branch-status.png"
fi

echo
echo -e "${GREEN}Success!${RESET} Reports saved to ${BOLD}$OUTPUT${RESET}."
echo
echo "Done! Open the generated reports to view your branch analysis."

info "No branches were modified or deleted."
#endregion
