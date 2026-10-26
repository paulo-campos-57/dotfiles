
#!/usr/bin/env bash

set -euo pipefail

#region Config
REPO="${1:-.}"
OUTPUT="${2:-./git-report}"

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
echo "        Git Commits Report Generator      "
echo "=========================================="
echo

echo "--- Checking Requirements ---"

for dependency in git awk gnuplot date sort; do
    if ! command -v "$dependency" &>/dev/null; then
        error "$dependency is not installed!"
    fi

    success "$dependency found."
done

if ! git -C "$REPO" rev-parse --is-inside-work-tree &>/dev/null; then
    error "Directory '$REPO' is not a valid Git repository!"
fi

success "Git repository found."
#endregion

#region Period selection
echo
echo "--- Select Analysis Period ---"
echo
echo "  1) Daily    - Specific day"
echo "  2) Monthly  - Specific month"
echo "  3) Yearly   - Specific year"
echo "  4) All Time - Entire repository history"
echo

read -r -p "Select an option [1-4]: " PERIOD_OPTION

SINCE=""
UNTIL=""
PERIOD_LABEL=""
PERIOD_SLUG=""
GRANULARITY=""
DATE_FORMAT=""
CHART_FORMAT=""
AXIS_LABEL=""

case "$PERIOD_OPTION" in
    1)
        read -r -p "Enter date (YYYY-MM-DD): " INPUT_DATE

        if ! [[ "$INPUT_DATE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            error "Invalid date format! Expected YYYY-MM-DD."
        fi

        if [[ "$(date -d "$INPUT_DATE" +%F 2>/dev/null || true)" != "$INPUT_DATE" ]]; then
            error "Invalid date!"
        fi

        SINCE="$INPUT_DATE 00:00:00"
        UNTIL="$(date -d "$INPUT_DATE + 1 day" +%F) 00:00:00"

        PERIOD_LABEL="Daily ($INPUT_DATE)"
        PERIOD_SLUG="$INPUT_DATE"
        GRANULARITY="Hourly"
        DATE_FORMAT="%Y-%m-%d %H"
        CHART_FORMAT="%H:00"
        AXIS_LABEL="Hour"
        ;;

    2)
        read -r -p "Enter month (YYYY-MM): " INPUT_MONTH

        if ! [[ "$INPUT_MONTH" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
            error "Invalid month format! Expected YYYY-MM."
        fi

        if [[ "$(date -d "$INPUT_MONTH-01" +%Y-%m 2>/dev/null || true)" != "$INPUT_MONTH" ]]; then
            error "Invalid month!"
        fi

        SINCE="$INPUT_MONTH-01 00:00:00"
        UNTIL="$(date -d "$INPUT_MONTH-01 + 1 month" +%F) 00:00:00"

        PERIOD_LABEL="Monthly ($INPUT_MONTH)"
        PERIOD_SLUG="$INPUT_MONTH"
        GRANULARITY="Daily"
        DATE_FORMAT="%Y-%m-%d"
        CHART_FORMAT="%d/%m"
        AXIS_LABEL="Day"
        ;;

    3)
        read -r -p "Enter year (YYYY): " INPUT_YEAR

        if ! [[ "$INPUT_YEAR" =~ ^[0-9]{4}$ ]] || [[ "$INPUT_YEAR" == "0000" ]]; then
            error "Invalid year! Expected YYYY."
        fi

        NEXT_YEAR=$(printf "%04d" "$((10#$INPUT_YEAR + 1))")

        SINCE="$INPUT_YEAR-01-01 00:00:00"
        UNTIL="$NEXT_YEAR-01-01 00:00:00"

        PERIOD_LABEL="Yearly ($INPUT_YEAR)"
        PERIOD_SLUG="$INPUT_YEAR"
        GRANULARITY="Monthly"
        DATE_FORMAT="%Y-%m"
        CHART_FORMAT="%m/%Y"
        AXIS_LABEL="Month"
        ;;

    4)
        PERIOD_LABEL="All Time"
        PERIOD_SLUG="all-time"
        GRANULARITY="Monthly"
        DATE_FORMAT="%Y-%m"
        CHART_FORMAT="%m/%Y"
        AXIS_LABEL="Month"
        ;;

    *)
        error "Invalid option! Select a number between 1 and 4."
        ;;
esac

success "Period selected: $PERIOD_LABEL"
info "Evolution chart granularity: $GRANULARITY"
#endregion

#region Output configuration
OUTPUT="$OUTPUT/$PERIOD_SLUG"

mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"

RAW="$OUTPUT/commits_raw.tsv"
SUMMARY="$OUTPUT/resumo.dat"
EVOLUTION="$OUTPUT/evolution.dat"

success "Output directory configured."
#endregion

#region Commit check
echo
echo "--- Analyzing Commits ---"

info "Repository: $(git -C "$REPO" rev-parse --show-toplevel)"
info "Output directory: $OUTPUT"
info "Reading commits from all branches..."

GIT_ARGS=(
    -C "$REPO"
    log
    --all
    --no-merges
    "--date=format-local:$DATE_FORMAT"
    "--format=%ad%x09%s"
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

success "Commits extracted successfully."
#endregion

#region Commit analysis
echo
echo "--- Processing Commit Tags ---"

info "Normalizing tags (case-insensitive)..."
info "Grouping FEAT and ADD into one category..."
info "Classifying unrecognized commits as OTHER..."

awk -F '\t' \
    -v summary="$SUMMARY" \
    -v evolution="$EVOLUTION" '
BEGIN {
    n = split(
        "FEAT/ADD FIX TEST REFACTOR DOCS CHORE STYLE OTHER",
        tags, " "
    )
}
{
    period = $1
    subject = toupper($2)
    tag = "OTHER"

    if (subject ~ /\[(FEAT|ADD)\]/)
        tag = "FEAT/ADD"
    else if (subject ~ /\[FIX\]/)
        tag = "FIX"
    else if (subject ~ /\[TEST\]/)
        tag = "TEST"
    else if (subject ~ /\[REFACTOR\]/)
        tag = "REFACTOR"
    else if (subject ~ /\[DOCS\]/)
        tag = "DOCS"
    else if (subject ~ /\[CHORE\]/)
        tag = "CHORE"
    else if (subject ~ /\[STYLE\]/)
        tag = "STYLE"

    count[tag]++
    periodCount[period, tag]++
    periods[period] = 1
    total++
}
END {
    if (total == 0) exit

    for (i = 1; i <= n; i++) {
        tag = tags[i]
        percentage = count[tag] * 100 / total

        printf "%s %.2f %d\n",
            tag, percentage, count[tag] > summary
    }

    for (period in periods) {
        printf "%s", period >> evolution

        for (i = 1; i <= n; i++) {
            tag = tags[i]
            printf " %d", periodCount[period, tag] >> evolution
        }

        printf "\n" >> evolution
    }

    printf "%d\n", total > "/dev/stderr"
}
' "$RAW" 2>"$OUTPUT/.total"

TOTAL=$(cat "$OUTPUT/.total")
rm -f "$OUTPUT/.total"

sort -o "$EVOLUTION" "$EVOLUTION"

success "$TOTAL commits analyzed."
success "Commit tags normalized successfully."

OTHER_COUNT=$(awk '$1 == "OTHER" {print $3}' "$SUMMARY")

if [[ "${OTHER_COUNT:-0}" -gt 0 ]]; then
    warning "$OTHER_COUNT commits classified as OTHER."
fi
#endregion

#region Charts
echo
echo "--- Generating Charts ---"

info "Generating commit distribution chart..."

gnuplot <<EOF
set terminal pngcairo size 1300,750 enhanced font "Arial,12"
set output "$OUTPUT/distribution.png"

set title "Commit Distribution - $PERIOD_LABEL"
set xlabel "Percentage (%)"
set xrange [0:100]
set yrange [-1:8]
set grid xtics
set key off

set style fill solid 0.8
set boxwidth 0.7

plot "$SUMMARY" using 2:0:ytic(1) \
    with boxes horizontal lc rgb "#DA291C" notitle
EOF

success "Distribution chart generated."

info "Generating commit evolution chart..."

gnuplot <<EOF
set terminal pngcairo size 1400,750 enhanced font "Arial,11"
set output "$OUTPUT/evolution.png"

set title "Commit Evolution - $PERIOD_LABEL"
set xlabel "$AXIS_LABEL"
set ylabel "Number of Commits"

set xdata time
set timefmt "$DATE_FORMAT"
set format x "$CHART_FORMAT"
set xtics rotate by -45
set grid
set key outside right

plot \
"$EVOLUTION" using 1:2 with linespoints lw 2 title "FEAT/ADD", \
"" using 1:3 with linespoints lw 2 title "FIX", \
"" using 1:4 with linespoints lw 2 title "TEST", \
"" using 1:5 with linespoints lw 2 title "REFACTOR", \
"" using 1:6 with linespoints lw 2 title "DOCS", \
"" using 1:7 with linespoints lw 2 title "CHORE", \
"" using 1:8 with linespoints lw 2 title "STYLE", \
"" using 1:9 with linespoints lw 2 title "OTHER"
EOF

success "Evolution chart generated."
#endregion

#region Summary
echo
echo "=========================================="
echo "             Commit Summary               "
echo "=========================================="
echo

info "Period: $PERIOD_LABEL"
info "Granularity: $GRANULARITY"

echo
printf "${BOLD}%-14s %12s %12s${RESET}\n" \
    "TAG" "COMMITS" "PERCENTAGE"

echo "------------------------------------------"

awk '{
    printf "%-14s %12d %11.2f%%\n", $1, $3, $2
}' "$SUMMARY"

echo "------------------------------------------"

printf "${BOLD}%-14s %12d %11s${RESET}\n" \
    "TOTAL" "$TOTAL" "100.00%"

echo
echo "=========================================="
echo "             Generated Files              "
echo "=========================================="
echo

success "distribution.png"
success "evolution.png"
success "resumo.dat"
success "evolution.dat"

echo
echo -e "${GREEN}Success!${RESET} Reports saved to ${BOLD}$OUTPUT${RESET}."
echo
echo "Done! Open the generated PNG files to view your charts."
#endregion
