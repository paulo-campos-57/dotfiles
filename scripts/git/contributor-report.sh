#!/usr/bin/env bash

set -euo pipefail

#region Config
REPO="${1:-.}"
OUTPUT="${2:-./contributor-report}"

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

TMP_DIR=""

cleanup() {
    if [[ -n "$TMP_DIR" && -d "$TMP_DIR" ]]; then
        rm -rf -- "$TMP_DIR"
    fi
}

trap cleanup EXIT

validate_date() {
    local input="$1"

    if ! [[ "$input" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        error "Invalid date format! Expected YYYY-MM-DD."
    fi

    if [[ "$(date -d "$input" +%F 2>/dev/null || true)" != "$input" ]]; then
        error "Invalid date!"
    fi
}
#endregion

#region Requirement check
echo "=========================================="
echo "       Git Contributor Report Generator   "
echo "=========================================="
echo

echo "--- Checking Requirements ---"

for dependency in git awk sort date mktemp; do
    if ! command -v "$dependency" &>/dev/null; then
        error "$dependency is not installed!"
    fi

    success "$dependency found."
done

if ! git -C "$REPO" rev-parse --is-inside-work-tree &>/dev/null; then
    error "Directory '$REPO' is not a valid Git repository!"
fi

REPO="$(git -C "$REPO" rev-parse --show-toplevel)"

success "Git repository found."

if command -v gnuplot &>/dev/null; then
    HAS_GNUPLOT=true
    success "Gnuplot found."
else
    HAS_GNUPLOT=false
    warning "Gnuplot not found. Charts will be skipped."
fi
#endregion

#region Period selection
echo
echo "--- Select Analysis Period ---"
echo
echo "  1) Daily    - Specific day"
echo "  2) Monthly  - Specific month"
echo "  3) Yearly   - Specific year"
echo "  4) Custom   - Date range"
echo "  5) All Time - Entire repository history"
echo

read -r -p "Select an option [1-5]: " PERIOD_OPTION

SINCE=""
UNTIL=""
PERIOD_LABEL=""
PERIOD_SLUG=""

case "$PERIOD_OPTION" in
    1)
        read -r -p "Enter date (YYYY-MM-DD): " INPUT_DATE

        validate_date "$INPUT_DATE"

        SINCE="$INPUT_DATE 00:00:00"
        UNTIL="$(date -d "$INPUT_DATE + 1 day" +%F) 00:00:00"

        PERIOD_LABEL="Daily ($INPUT_DATE)"
        PERIOD_SLUG="$INPUT_DATE"
        ;;

    2)
        read -r -p "Enter month (YYYY-MM): " INPUT_MONTH

        if ! [[ "$INPUT_MONTH" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
            error "Invalid month format! Expected YYYY-MM."
        fi

        validate_date "$INPUT_MONTH-01"

        SINCE="$INPUT_MONTH-01 00:00:00"
        UNTIL="$(date -d "$INPUT_MONTH-01 + 1 month" +%F) 00:00:00"

        PERIOD_LABEL="Monthly ($INPUT_MONTH)"
        PERIOD_SLUG="$INPUT_MONTH"
        ;;

    3)
        read -r -p "Enter year (YYYY): " INPUT_YEAR

        if ! [[ "$INPUT_YEAR" =~ ^[0-9]{4}$ ]] || [[ "$INPUT_YEAR" == "0000" ]]; then
            error "Invalid year! Expected YYYY."
        fi

        NEXT_YEAR="$(printf "%04d" "$((10#$INPUT_YEAR + 1))")"

        SINCE="$INPUT_YEAR-01-01 00:00:00"
        UNTIL="$NEXT_YEAR-01-01 00:00:00"

        PERIOD_LABEL="Yearly ($INPUT_YEAR)"
        PERIOD_SLUG="$INPUT_YEAR"
        ;;

    4)
        read -r -p "Start date (YYYY-MM-DD): " START_DATE
        read -r -p "End date (YYYY-MM-DD): " END_DATE

        validate_date "$START_DATE"
        validate_date "$END_DATE"

        if [[ "$START_DATE" > "$END_DATE" ]]; then
            error "Start date cannot be after end date."
        fi

        SINCE="$START_DATE 00:00:00"
        UNTIL="$(date -d "$END_DATE + 1 day" +%F) 00:00:00"

        PERIOD_LABEL="Custom ($START_DATE to $END_DATE)"
        PERIOD_SLUG="${START_DATE}_to_${END_DATE}"
        ;;

    5)
        PERIOD_LABEL="All Time"
        PERIOD_SLUG="all-time"
        ;;

    *)
        error "Invalid option! Select a number between 1 and 5."
        ;;
esac

success "Period selected: $PERIOD_LABEL"
#endregion

#region Analysis options
echo
echo "--- Select Commit Scope ---"
echo
echo "  1) All branches (default)"
echo "  2) Current branch"
echo

read -r -p "Select an option [1-2] (default: 1): " SCOPE_OPTION

case "${SCOPE_OPTION:-1}" in
    1)
        SCOPE_LABEL="All Branches"
        SCOPE_SLUG="all-branches"
        GIT_SCOPE=(--all)
        ;;

    2)
        SCOPE_LABEL="Current Branch"
        SCOPE_SLUG="current-branch"
        GIT_SCOPE=(HEAD)
        ;;

    *)
        error "Invalid scope option."
        ;;
esac

echo
echo "--- Merge Commits ---"
echo
echo "  1) Exclude merge commits (default)"
echo "  2) Include merge commits"
echo

read -r -p "Select an option [1-2] (default: 1): " MERGE_OPTION

case "${MERGE_OPTION:-1}" in
    1)
        MERGE_LABEL="Excluded"
        GIT_MERGES=(--no-merges)
        ;;

    2)
        MERGE_LABEL="Included"
        GIT_MERGES=()
        ;;

    *)
        error "Invalid merge option."
        ;;
esac

success "Commit scope: $SCOPE_LABEL"
success "Merge commits: $MERGE_LABEL"
#endregion

#region Output configuration
OUTPUT="$OUTPUT/$PERIOD_SLUG/$SCOPE_SLUG"

mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"

TMP_DIR="$(mktemp -d)"

RAW="$OUTPUT/commits_raw.tsv"
SUMMARY="$OUTPUT/contributors.csv"
RANKING="$OUTPUT/ranking.dat"
ACTIVITY="$OUTPUT/activity.dat"
AUTHOR_MAP="$OUTPUT/authors.dat"

success "Output directory configured."
#endregion

#region Commit extraction
echo
echo "--- Extracting Git History ---"

info "Repository: $REPO"
info "Period: $PERIOD_LABEL"
info "Scope: $SCOPE_LABEL"
info "Output directory: $OUTPUT"

GIT_ARGS=(
    -C "$REPO"
    log
    "${GIT_SCOPE[@]}"
    "${GIT_MERGES[@]}"
    --use-mailmap
    --numstat
    --format="@@COMMIT@@%x09%aN%x09%aE%x09%ad"
    --date=format-local:%Y-%m-%d
)

if [[ -n "$SINCE" ]]; then
    GIT_ARGS+=("--since=$SINCE")
fi

if [[ -n "$UNTIL" ]]; then
    GIT_ARGS+=("--before=$UNTIL")
fi

git "${GIT_ARGS[@]}" > "$RAW"

if [[ ! -s "$RAW" ]]; then
    warning "No commits found for the selected period."
    exit 0
fi

success "Git history extracted successfully."
#endregion

#region Contributor analysis
echo
echo "--- Processing Contributors ---"

info "Grouping commits by author email..."
info "Applying Git mailmap identities..."
info "Calculating added and deleted lines..."
info "Generating contributor statistics..."

awk -F '\t' \
    -v summary="$SUMMARY" \
    -v ranking="$RANKING" \
    -v activity="$ACTIVITY" \
    -v authorMap="$AUTHOR_MAP" '
BEGIN {
    OFS = "\t"
}
function csv(value) {
    gsub(/"/, "\"\"", value)
    return "\"" value "\""
}
function flush_commit() {
    if (!in_commit)
        return

    commits[email]++
    additions[email] += commit_additions
    deletions[email] += commit_deletions
    names[email] = name
    authors[email] = 1

    daily[date, email]++
    dates[date] = 1

    total_commits++
    total_additions += commit_additions
    total_deletions += commit_deletions
}
/^@@COMMIT@@\t/ {
    flush_commit()

    in_commit = 1
    name = $2
    email = $3
    date = $4

    if (name == "")
        name = "Unknown"

    if (email == "")
        email = "unknown"

    commit_additions = 0
    commit_deletions = 0

    next
}
in_commit && NF >= 3 {
    if ($1 ~ /^[0-9]+$/)
        commit_additions += $1

    if ($2 ~ /^[0-9]+$/)
        commit_deletions += $2
}
END {
    flush_commit()

    print "author,email,commits,percentage,added,deleted,changed" > summary

    for (email in authors) {
        percentage = commits[email] * 100 / total_commits
        changed = additions[email] + deletions[email]

        print csv(names[email]) "," \
              csv(email) "," \
              commits[email] "," \
              sprintf("%.2f", percentage) "," \
              additions[email] "," \
              deletions[email] "," \
              changed >> summary

        print commits[email], email > ranking
        print email, names[email] > authorMap
    }

    for (key in daily) {
        split(key, parts, SUBSEP)
        print parts[1], parts[2], daily[key] > activity
    }

    printf "%d %d %d %d\n",
        total_commits,
        total_additions,
        total_deletions,
        length(authors) > "/dev/stderr"
}
' "$RAW" 2>"$TMP_DIR/totals"

read -r TOTAL_COMMITS TOTAL_ADDED TOTAL_DELETED TOTAL_AUTHORS \
    < "$TMP_DIR/totals"

{
    head -n 1 "$SUMMARY"
    tail -n +2 "$SUMMARY" | sort -t ',' -k3,3nr
} > "$TMP_DIR/contributors.csv"

mv "$TMP_DIR/contributors.csv" "$SUMMARY"

sort -k1,1nr "$RANKING" -o "$RANKING"
sort -k1,1 -k2,2 "$ACTIVITY" -o "$ACTIVITY"

success "$TOTAL_COMMITS commits analyzed."
success "$TOTAL_AUTHORS contributors identified."
success "Contributor statistics generated."
#endregion

#region Chart preparation
echo
echo "--- Preparing Chart Data ---"

CHART_DATA="$OUTPUT/top-contributors.dat"

awk -F ',' '
NR == 1 {
    next
}
NR <= 11 {
    name = $1
    gsub(/^"|"$/, "", name)
    gsub(/""/, "\"", name)

    printf "%d %d %d\n", NR - 1, $3, $7
}
' "$SUMMARY" > "$CHART_DATA"

TOP_COUNT="$(wc -l < "$CHART_DATA")"

success "Top $TOP_COUNT contributors prepared."
#endregion

#region Charts
echo
echo "--- Generating Charts ---"

if [[ "$HAS_GNUPLOT" == true && "$TOTAL_AUTHORS" -gt 0 ]]; then
    info "Generating contributor commits chart..."

    gnuplot <<EOF
set terminal pngcairo size 1400,750 enhanced font "Sans,12"
set output "$OUTPUT/contributors-commits.png"

set title "Top Contributors by Commits - $PERIOD_LABEL"
set xlabel "Contributor Rank"
set ylabel "Number of Commits"

set style fill solid 0.85
set boxwidth 0.65
set grid ytics
set key off
set yrange [0:*]

plot "$CHART_DATA" using 1:2 \
    with boxes lc rgb "#DA291C" notitle
EOF

    success "Contributor commits chart generated."

    info "Generating code changes chart..."

    gnuplot <<EOF
set terminal pngcairo size 1400,750 enhanced font "Sans,12"
set output "$OUTPUT/contributors-changes.png"

set title "Code Changes by Contributor - $PERIOD_LABEL"
set xlabel "Contributor Rank"
set ylabel "Lines Added + Deleted"

set style fill solid 0.85
set boxwidth 0.65
set grid ytics
set key off
set yrange [0:*]

plot "$CHART_DATA" using 1:3 \
    with boxes lc rgb "#DA291C" notitle
EOF

    success "Code changes chart generated."
else
    warning "Charts skipped (gnuplot unavailable or no contributors found)."
fi
#endregion

#region Summary
echo
echo "=========================================="
echo "           Contributor Summary            "
echo "=========================================="
echo

info "Repository: $REPO"
info "Period: $PERIOD_LABEL"
info "Scope: $SCOPE_LABEL"
info "Merge commits: $MERGE_LABEL"

echo
printf "${BOLD}%-24s %12s${RESET}\n" \
    "METRIC" "VALUE"

echo "------------------------------------------"

printf "%-24s %12d\n" "Contributors" "$TOTAL_AUTHORS"
printf "%-24s %12d\n" "Commits" "$TOTAL_COMMITS"
printf "%-24s %12d\n" "Lines Added" "$TOTAL_ADDED"
printf "%-24s %12d\n" "Lines Deleted" "$TOTAL_DELETED"
printf "%-24s %12d\n" "Lines Changed" "$((TOTAL_ADDED + TOTAL_DELETED))"

echo
echo "--- Top Contributors ---"
echo

printf "${BOLD}%-5s %-30s %10s %10s${RESET}\n" \
    "RANK" "AUTHOR" "COMMITS" "SHARE"

echo "------------------------------------------------------------"

awk -F ',' '
NR > 1 && NR <= 11 {
    name = $1
    gsub(/^"|"$/, "", name)

    if (length(name) > 30)
        name = substr(name, 1, 27) "..."

    printf "%-5d %-30s %10d %9.2f%%\n",
        NR - 1, name, $3, $4
}
' "$SUMMARY"

echo
echo "=========================================="
echo "             Generated Files              "
echo "=========================================="
echo

success "commits_raw.tsv"
success "contributors.csv"
success "ranking.dat"
success "activity.dat"
success "authors.dat"
success "top-contributors.dat"

if [[ "$HAS_GNUPLOT" == true && "$TOTAL_AUTHORS" -gt 0 ]]; then
    success "contributors-commits.png"
    success "contributors-changes.png"
fi

echo
echo -e "${GREEN}Success!${RESET} Reports saved to ${BOLD}$OUTPUT${RESET}."
echo
echo "Done! Open the generated reports to view contributor statistics."
#endregion
