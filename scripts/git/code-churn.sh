
#!/usr/bin/env bash

set -euo pipefail

#region Config
REPO="${1:-.}"
OUTPUT="${2:-./code-churn-report}"

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
echo "         Git Code Churn Generator         "
echo "=========================================="
echo

echo "--- Checking Requirements ---"

for dependency in git awk sort date mktemp head; do
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
echo "--- Select Ranking Metric ---"
echo
echo "  1) Number of commits (default)"
echo "  2) Lines changed (added + deleted)"
echo

read -r -p "Select an option [1-2] (default: 1): " METRIC_OPTION

case "${METRIC_OPTION:-1}" in
    1)
        METRIC_LABEL="Commits"
        METRIC_SLUG="commits"
        SORT_COLUMN=2
        ;;

    2)
        METRIC_LABEL="Lines Changed"
        METRIC_SLUG="lines-changed"
        SORT_COLUMN=5
        ;;

    *)
        error "Invalid ranking metric."
        ;;
esac

echo
echo "--- Ranking Size ---"

read -r -p "How many files should appear in the ranking? [10]: " TOP_N

TOP_N="${TOP_N:-10}"

if ! [[ "$TOP_N" =~ ^[1-9][0-9]*$ ]]; then
    error "Ranking size must be a positive integer."
fi

success "Commit scope: $SCOPE_LABEL"
success "Ranking metric: $METRIC_LABEL"
success "Ranking size: $TOP_N"
#endregion

#region Output configuration
OUTPUT="$OUTPUT/$PERIOD_SLUG/$SCOPE_SLUG"

mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"

TMP_DIR="$(mktemp -d)"

RAW="$OUTPUT/commits_raw.tsv"
SUMMARY="$OUTPUT/code-churn.csv"
RANKING="$OUTPUT/ranking.dat"
CHART_DATA="$OUTPUT/top-files.dat"

success "Output directory configured."
#endregion

#region Commit extraction
echo
echo "--- Extracting Git History ---"

info "Repository: $REPO"
info "Period: $PERIOD_LABEL"
info "Scope: $SCOPE_LABEL"
info "Ranking metric: $METRIC_LABEL"
info "Output directory: $OUTPUT"

GIT_ARGS=(
    -C "$REPO"
    log
    "${GIT_SCOPE[@]}"
    --no-merges
    --no-renames
    --numstat
    --format="@@COMMIT@@%x09%H"
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

#region Code churn analysis
echo
echo "--- Processing Code Churn ---"

info "Counting commits per file..."
info "Calculating added and deleted lines..."
info "Identifying binary file modifications..."
info "Generating file statistics..."

awk -F '\t' \
    -v output="$TMP_DIR/churn.tsv" \
    -v totals="$TMP_DIR/totals" '
BEGIN {
    OFS = "\t"
}
function flush_commit() {
    if (!in_commit)
        return

    total_commits++
}
function flush_file(path, added, deleted) {
    if (path == "")
        return

    commits[path]++
    files[path] = 1

    if (added ~ /^[0-9]+$/ && deleted ~ /^[0-9]+$/) {
        additions[path] += added
        deletions[path] += deleted
    } else {
        binary[path]++
    }
}
/^@@COMMIT@@\t/ {
    flush_commit()

    in_commit = 1
    next
}
in_commit && NF >= 3 {
    path = $3

    for (i = 4; i <= NF; i++)
        path = path FS $i

    flush_file(path, $1, $2)
}
END {
    flush_commit()

    for (path in files) {
        changed = additions[path] + deletions[path]

        print path,
              commits[path],
              additions[path],
              deletions[path],
              changed,
              binary[path] > output

        total_files++
        total_additions += additions[path]
        total_deletions += deletions[path]
        total_binary += binary[path]
    }

    printf "%d %d %d %d %d\n",
        total_commits,
        total_files,
        total_additions,
        total_deletions,
        total_binary > totals
}
' "$RAW"

read -r TOTAL_COMMITS TOTAL_FILES TOTAL_ADDED TOTAL_DELETED TOTAL_BINARY \
    < "$TMP_DIR/totals"

if (( TOTAL_FILES == 0 )); then
    warning "No file modifications found for the selected period."
    exit 0
fi

success "$TOTAL_COMMITS commits analyzed."
success "$TOTAL_FILES files identified."
success "Code churn statistics generated."
#endregion

#region Ranking
echo
echo "--- Generating File Ranking ---"

info "Sorting files by $METRIC_LABEL..."

sort -t $'\t' \
    -k"${SORT_COLUMN},${SORT_COLUMN}"nr \
    -k1,1 \
    "$TMP_DIR/churn.tsv" > "$RANKING"

{
    printf 'file,commits,added,deleted,changed,binary_changes\n'

    awk -F '\t' '
    function csv(value) {
        gsub(/"/, "\"\"", value)
        return "\"" value "\""
    }
    {
        printf "%s,%d,%d,%d,%d,%d\n",
            csv($1), $2, $3, $4, $5, $6
    }
    ' "$RANKING"
} > "$SUMMARY"

head -n "$TOP_N" "$RANKING" > "$TMP_DIR/top-ranking.tsv"

awk -F '\t' \
    -v metric="$SORT_COLUMN" '
{
    value = $metric

    printf "%d %d\n", NR, value
}
' "$TMP_DIR/top-ranking.tsv" > "$CHART_DATA"

TOP_COUNT="$(wc -l < "$CHART_DATA")"

success "Top $TOP_COUNT files prepared."
success "CSV report generated."
#endregion

#region Charts
echo
echo "--- Generating Charts ---"

if [[ "$HAS_GNUPLOT" == true && "$TOP_COUNT" -gt 0 ]]; then
    info "Generating code churn chart..."

    gnuplot <<EOF
set terminal pngcairo size 1400,750 enhanced font "Sans,12"
set output "$OUTPUT/code-churn.png"

set title "Code Churn - $PERIOD_LABEL"
set xlabel "File Rank"
set ylabel "$METRIC_LABEL"

set style fill solid 0.85
set boxwidth 0.65
set grid ytics
set key off
set yrange [0:*]

plot "$CHART_DATA" using 1:2 \
    with boxes lc rgb "#DA291C" notitle
EOF

    success "Code churn chart generated."
else
    warning "Chart skipped (gnuplot unavailable or no files found)."
fi
#endregion

#region Summary
echo
echo "=========================================="
echo "             Code Churn Summary           "
echo "=========================================="
echo

info "Repository: $REPO"
info "Period: $PERIOD_LABEL"
info "Scope: $SCOPE_LABEL"
info "Ranking metric: $METRIC_LABEL"

echo
printf "${BOLD}%-24s %12s${RESET}\n" \
    "METRIC" "VALUE"

echo "------------------------------------------"

printf "%-24s %12d\n" "Commits Analyzed" "$TOTAL_COMMITS"
printf "%-24s %12d\n" "Files Modified" "$TOTAL_FILES"
printf "%-24s %12d\n" "Lines Added" "$TOTAL_ADDED"
printf "%-24s %12d\n" "Lines Deleted" "$TOTAL_DELETED"
printf "%-24s %12d\n" "Lines Changed" "$((TOTAL_ADDED + TOTAL_DELETED))"
printf "%-24s %12d\n" "Binary Modifications" "$TOTAL_BINARY"

echo
echo "--- Top Files ---"
echo

printf "${BOLD}%-5s %-42s %10s %12s${RESET}\n" \
    "RANK" "FILE" "COMMITS" "CHANGED"

echo "------------------------------------------------------------------------"

awk -F '\t' '
{
    path = $1

    if (length(path) > 42)
        path = "..." substr(path, length(path) - 38)

    printf "%-5d %-42s %10d %12d\n",
        NR, path, $2, $5
}
' "$TMP_DIR/top-ranking.tsv"

echo
echo "=========================================="
echo "             Generated Files              "
echo "=========================================="
echo

success "commits_raw.tsv"
success "code-churn.csv"
success "ranking.dat"
success "top-files.dat"

if [[ "$HAS_GNUPLOT" == true && "$TOP_COUNT" -gt 0 ]]; then
    success "code-churn.png"
fi

echo
echo -e "${GREEN}Success!${RESET} Reports saved to ${BOLD}$OUTPUT${RESET}."
echo
echo "Done! Open the generated reports to view code churn statistics."
#endregion
