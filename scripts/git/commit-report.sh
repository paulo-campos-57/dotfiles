#!/usr/bin/env bash

set -euo pipefail

#region Config
REPO="${1:-.}"
OUTPUT="${2:-./commit-report}"

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

for dependency in git awk sort date mkdir; do
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
    if gnuplot -e 'set terminal pngcairo' &>/dev/null; then
        HAS_GNUPLOT=true
        success "Gnuplot found with PNG support."
    else
        HAS_GNUPLOT=false
        warning "Gnuplot does not support pngcairo."
    fi
else
    HAS_GNUPLOT=false
    warning "Gnuplot not found. Data reports will still be generated."
fi
#endregion

#region Period selection
echo
echo "--- Select Analysis Period ---"
echo
echo "  1) Daily    - Specific day"
echo "  2) Monthly  - Specific month"
echo "  3) Yearly   - Specific year"
echo "  4) All Time - Entire repository history (default)"
echo

read -r -p "Select an option [1-4] (default: 4): " PERIOD_OPTION || true

PERIOD_OPTION="${PERIOD_OPTION:-4}"

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

        NEXT_YEAR="$(printf "%04d" "$((10#$INPUT_YEAR + 1))")"

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
        error "Invalid period option."
        ;;
esac

success "Period selected: $PERIOD_LABEL"
info "Evolution chart granularity: $GRANULARITY"
#endregion

#region Branch selection
echo
echo "--- Select Branch Scope ---"
echo
echo "  1) Current branch"
echo "  2) Specific branch"
echo "  3) All local branches"
echo "  4) All local and remote branches (default)"
echo

read -r -p "Select an option [1-4] (default: 4): " BRANCH_OPTION || true

BRANCH_OPTION="${BRANCH_OPTION:-4}"

BRANCH_LABEL=""
BRANCH_SLUG=""
GIT_REFS=()

case "$BRANCH_OPTION" in
    1)
        CURRENT_BRANCH="$(git -C "$REPO" branch --show-current)"

        if [[ -z "$CURRENT_BRANCH" ]]; then
            error "Detached HEAD. Select a specific branch instead."
        fi

        BRANCH_LABEL="Current branch: $CURRENT_BRANCH"
        BRANCH_SLUG="current"
        GIT_REFS=("HEAD")
        ;;

    2)
        echo
        echo "--- Available Branches ---"
        echo

        git -C "$REPO" branch -a

        echo
        read -r -p "Enter branch name: " SELECTED_BRANCH

        if [[ -z "$SELECTED_BRANCH" ]]; then
            error "Branch name cannot be empty."
        fi

        if git -C "$REPO" show-ref --verify --quiet "refs/heads/$SELECTED_BRANCH"; then
            SELECTED_REF="refs/heads/$SELECTED_BRANCH"

        elif git -C "$REPO" show-ref --verify --quiet "refs/remotes/$SELECTED_BRANCH"; then
            SELECTED_REF="refs/remotes/$SELECTED_BRANCH"

        else
            error "Branch '$SELECTED_BRANCH' was not found."
        fi

        BRANCH_LABEL="Specific branch: $SELECTED_BRANCH"
        BRANCH_SLUG="specific"
        GIT_REFS=("$SELECTED_REF")
        ;;

    3)
        BRANCH_LABEL="All local branches"
        BRANCH_SLUG="local"

        while IFS= read -r REF; do
            [[ -n "$REF" ]] || continue
            GIT_REFS+=("$REF")
        done < <(
            git -C "$REPO" for-each-ref \
                --format='%(refname)' refs/heads
        )
        ;;

    4)
        BRANCH_LABEL="All local and remote branches"
        BRANCH_SLUG="all-branches"

        while IFS= read -r REF; do
            [[ -n "$REF" ]] || continue
            [[ "$REF" == refs/remotes/*/HEAD ]] && continue

            GIT_REFS+=("$REF")
        done < <(
            git -C "$REPO" for-each-ref \
                --format='%(refname)' refs/heads refs/remotes
        )
        ;;

    *)
        error "Invalid branch scope option."
        ;;
esac

if [[ "${#GIT_REFS[@]}" -eq 0 ]]; then
    error "No branches found for the selected scope."
fi

success "Branch scope selected: $BRANCH_LABEL"
info "References selected: ${#GIT_REFS[@]}"
#endregion

#region Remote references
echo
echo "--- Remote References ---"

read -r -p "Fetch remote references first? (y/N): " FETCH || true

if [[ "${FETCH:-N}" =~ ^[yY]$ ]]; then
    info "Fetching remote references..."

    if git -C "$REPO" fetch --all --prune; then
        success "Remote references updated."

        # Refresh remote references after fetching.
        if [[ "$BRANCH_OPTION" == "4" ]]; then
            GIT_REFS=()

            while IFS= read -r REF; do
                [[ -n "$REF" ]] || continue
                [[ "$REF" == refs/remotes/*/HEAD ]] && continue

                GIT_REFS+=("$REF")
            done < <(
                git -C "$REPO" for-each-ref \
                    --format='%(refname)' refs/heads refs/remotes
            )
        fi

        if [[ "${#GIT_REFS[@]}" -eq 0 ]]; then
            error "No references remain after fetching."
        fi

        for REF in "${GIT_REFS[@]}"; do
            if ! git -C "$REPO" rev-parse --verify --quiet "${REF}^{commit}" &>/dev/null; then
                error "Selected branch is no longer available: $REF"
            fi
        done
    else
        warning "Fetch failed. Continuing with locally available references."
    fi
fi
#endregion

#region Analysis options
echo
echo "--- Commit Analysis Options ---"

read -r -p "Include merge commits? (y/N): " INCLUDE_MERGES || true

GIT_FILTERS=()

if [[ "${INCLUDE_MERGES:-N}" =~ ^[yY]$ ]]; then
    MERGE_LABEL="Included"
else
    GIT_FILTERS+=(--no-merges)
    MERGE_LABEL="Excluded"
fi

success "Merge commits: $MERGE_LABEL"

if [[ -n "$SINCE" ]]; then
    GIT_FILTERS+=("--since=$SINCE")
fi

if [[ -n "$UNTIL" ]]; then
    GIT_FILTERS+=("--before=$UNTIL")
fi
#endregion

#region Output configuration
OUTPUT="$OUTPUT/$PERIOD_SLUG/$BRANCH_SLUG"

if ! mkdir -p -- "$OUTPUT"; then
    error "Cannot create output directory: $OUTPUT"
fi

OUTPUT="$(cd "$OUTPUT" && pwd)"

RAW="$OUTPUT/commits_raw.tsv"
CLASSIFIED="$OUTPUT/commits_classificados.tsv"
OTHER="$OUTPUT/commits_other.tsv"

BRANCH_REPORT="$OUTPUT/branches.csv"

SUMMARY="$OUTPUT/resumo.dat"
EVOLUTION="$OUTPUT/evolution.dat"

DISTRIBUTION_CHART="$OUTPUT/distribuicao.png"
EVOLUTION_CHART="$OUTPUT/evolucao.png"

TOTAL_FILE="$OUTPUT/.total"

rm -f -- \
    "$RAW" \
    "$CLASSIFIED" \
    "$OTHER" \
    "$BRANCH_REPORT" \
    "$SUMMARY" \
    "$EVOLUTION" \
    "$DISTRIBUTION_CHART" \
    "$EVOLUTION_CHART" \
    "$TOTAL_FILE"

success "Output directory configured."
#endregion

#region Commit extraction
echo
echo "--- Analyzing Commits ---"

info "Repository: $REPO"
info "Period: $PERIOD_LABEL"
info "Branch scope: $BRANCH_LABEL"
info "Merge commits: $MERGE_LABEL"
info "Output directory: $OUTPUT"

info "Extracting unique commits..."

GIT_ARGS=(
    -C "$REPO"
    log
    "${GIT_REFS[@]}"
    "${GIT_FILTERS[@]}"
    "--date=format-local:$DATE_FORMAT"
    "--format=%H%x09%ad%x09%s"
)

if ! git "${GIT_ARGS[@]}" > "$RAW"; then
    error "Failed to extract Git commits."
fi

if [[ ! -s "$RAW" ]]; then
    warning "No commits found for the selected options."
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

: > "$SUMMARY"
: > "$EVOLUTION"
: > "$CLASSIFIED"
: > "$OTHER"

if ! awk -F '\t' \
    -v summary="$SUMMARY" \
    -v evolution="$EVOLUTION" \
    -v classified="$CLASSIFIED" \
    -v other="$OTHER" \
    -v total_file="$TOTAL_FILE" '
BEGIN {
    OFS = "\t"

    n = split("FEAT/ADD FIX TEST REFACTOR DOCS CHORE STYLE OTHER", tags, " ")

    print "hash", "period", "category", "subject" > classified
    print "hash", "period", "subject" > other

    total = 0
}

{
    hash = $1
    period = $2
    subject = $3
    normalized = toupper(subject)

    tag = "OTHER"

    # Bracket-style tags.
    if (normalized ~ /^\[[[:space:]]*(FEAT|ADD)[[:space:]]*\]/) {
        tag = "FEAT/ADD"
    }
    else if (normalized ~ /^\[[[:space:]]*FIX[[:space:]]*\]/) {
        tag = "FIX"
    }
    else if (normalized ~ /^\[[[:space:]]*TEST[[:space:]]*\]/) {
        tag = "TEST"
    }
    else if (normalized ~ /^\[[[:space:]]*REFACTOR[[:space:]]*\]/) {
        tag = "REFACTOR"
    }
    else if (normalized ~ /^\[[[:space:]]*DOCS[[:space:]]*\]/) {
        tag = "DOCS"
    }
    else if (normalized ~ /^\[[[:space:]]*CHORE[[:space:]]*\]/) {
        tag = "CHORE"
    }
    else if (normalized ~ /^\[[[:space:]]*STYLE[[:space:]]*\]/) {
        tag = "STYLE"
    }

    # Conventional Commits.
    else if (normalized ~ /^(FEAT|ADD)(\([^)]+\))?!?:/) {
        tag = "FEAT/ADD"
    }
    else if (normalized ~ /^FIX(\([^)]+\))?!?:/) {
        tag = "FIX"
    }
    else if (normalized ~ /^TEST(\([^)]+\))?!?:/) {
        tag = "TEST"
    }
    else if (normalized ~ /^REFACTOR(\([^)]+\))?!?:/) {
        tag = "REFACTOR"
    }
    else if (normalized ~ /^DOCS(\([^)]+\))?!?:/) {
        tag = "DOCS"
    }
    else if (normalized ~ /^CHORE(\([^)]+\))?!?:/) {
        tag = "CHORE"
    }
    else if (normalized ~ /^STYLE(\([^)]+\))?!?:/) {
        tag = "STYLE"
    }

    count[tag]++
    period_count[period, tag]++
    periods[period] = 1
    total++

    print hash, period, tag, subject >> classified

    if (tag == "OTHER") {
        print hash, period, subject >> other
    }
}

END {
    for (i = 1; i <= n; i++) {
        tag = tags[i]
        tag_count = count[tag] + 0

        percentage = 0

        if (total > 0) {
            percentage = tag_count * 100 / total
        }

        printf "%s %.2f %d\n", tag, percentage, tag_count >> summary
    }

    for (period in periods) {
        printf "%s", period >> evolution

        for (i = 1; i <= n; i++) {
            tag = tags[i]
            tag_count = period_count[period, tag] + 0

            printf " %d", tag_count >> evolution
        }

        printf "\n" >> evolution
    }

    print total > total_file

    close(summary)
    close(evolution)
    close(classified)
    close(other)
    close(total_file)
}
' "$RAW"; then
    error "AWK failed while processing commit statistics."
fi

if [[ ! -s "$TOTAL_FILE" ]]; then
    error "Commit analysis did not generate a total count."
fi

TOTAL="$(cat "$TOTAL_FILE")"

rm -f -- "$TOTAL_FILE"

if [[ "$TOTAL" -eq 0 ]]; then
    warning "No valid commits found."
    exit 0
fi

if [[ ! -s "$SUMMARY" || ! -s "$EVOLUTION" ]]; then
    error "Commit analysis did not generate the expected data files."
fi

LC_ALL=C sort -k1,1 "$EVOLUTION" -o "$EVOLUTION"

OTHER_COUNT="$(awk '$1 == "OTHER" {print $3}' "$SUMMARY")"

success "$TOTAL unique commits analyzed."
success "Commit tags normalized successfully."
success "Classification files generated."

if [[ "${OTHER_COUNT:-0}" -gt 0 ]]; then
    warning "$OTHER_COUNT commits classified as OTHER."
    info "Review unclassified commits in: $OTHER"
fi
#endregion

#region Branch analysis
echo
echo "--- Analyzing Branches ---"

info "Generating individual branch statistics..."

printf 'branch,commits\n' > "$BRANCH_REPORT"

BRANCH_TOTAL=0

for REF in "${GIT_REFS[@]}"; do
    if [[ "$REF" == "HEAD" ]]; then
        BRANCH_NAME="$(git -C "$REPO" branch --show-current)"
    else
        BRANCH_NAME="$(
            git -C "$REPO" for-each-ref \
                --format='%(refname:short)' "$REF"
        )"
    fi

    if [[ -z "$BRANCH_NAME" ]]; then
        BRANCH_NAME="$REF"
    fi

    BRANCH_COUNT="$(
        git -C "$REPO" rev-list \
            --count \
            "${GIT_FILTERS[@]}" \
            "$REF"
    )"

    BRANCH_NAME="${BRANCH_NAME//\"/\"\"}"

    printf '"%s",%d\n' \
        "$BRANCH_NAME" \
        "$BRANCH_COUNT" >> "$BRANCH_REPORT"

    ((BRANCH_TOTAL+=1))
done

success "$BRANCH_TOTAL branches analyzed."
success "Branch report generated."

info "Shared commits are counted once in the consolidated report."
info "Individual branch counts may overlap."
#endregion

#region Charts
echo
echo "--- Generating Charts ---"

if [[ "$HAS_GNUPLOT" == true ]]; then
    info "Generating commit distribution chart..."

    if gnuplot <<EOF
set terminal pngcairo size 1300,750 enhanced font "Sans,12"
set output "$DISTRIBUTION_CHART"

set title "Commit Distribution - $PERIOD_LABEL"
set xlabel "Percentage (%)"

set xrange [0:100]
set yrange [-1:8]

set grid xtics
set key off
set border 3
set tics nomirror

set style arrow 1 nohead lw 18 lc rgb "#DA291C"

plot "$SUMMARY" using (0):0:(\$2):(0):ytic(1) \
    with vectors arrowstyle 1 notitle

unset output
EOF
    then
        if [[ -s "$DISTRIBUTION_CHART" ]]; then
            success "Distribution chart generated."
        else
            warning "Distribution chart was not created."
        fi
    else
        warning "Failed to generate distribution chart."
    fi

    info "Generating commit evolution chart..."

    if gnuplot <<EOF
set terminal pngcairo size 1400,750 enhanced font "Sans,11"
set output "$EVOLUTION_CHART"

set title "Commit Evolution - $PERIOD_LABEL"
set xlabel "$AXIS_LABEL"
set ylabel "Number of Commits"

set xdata time
set timefmt "$DATE_FORMAT"
set format x "$CHART_FORMAT"

set xtics rotate by -45
set grid
set key outside right

set yrange [0:*]

plot \
"$EVOLUTION" using 1:2 with linespoints lw 2 title "FEAT/ADD", \
"" using 1:3 with linespoints lw 2 title "FIX", \
"" using 1:4 with linespoints lw 2 title "TEST", \
"" using 1:5 with linespoints lw 2 title "REFACTOR", \
"" using 1:6 with linespoints lw 2 title "DOCS", \
"" using 1:7 with linespoints lw 2 title "CHORE", \
"" using 1:8 with linespoints lw 2 title "STYLE", \
"" using 1:9 with linespoints lw 2 title "OTHER"

unset output
EOF
    then
        if [[ -s "$EVOLUTION_CHART" ]]; then
            success "Evolution chart generated."
        else
            warning "Evolution chart was not created."
        fi
    else
        warning "Failed to generate evolution chart."
    fi
else
    warning "Charts skipped (gnuplot unavailable)."
fi
#endregion

#region Summary
echo
echo "=========================================="
echo "             Commit Summary               "
echo "=========================================="
echo

info "Repository: $REPO"
info "Period: $PERIOD_LABEL"
info "Granularity: $GRANULARITY"
info "Branch scope: $BRANCH_LABEL"
info "Merge commits: $MERGE_LABEL"

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
info "Branches analyzed: $BRANCH_TOTAL"
info "Unclassified commits: ${OTHER_COUNT:-0}"

echo
echo "=========================================="
echo "             Generated Files              "
echo "=========================================="
echo

success "commits_raw.tsv"
success "commits_classificados.tsv"
success "commits_other.tsv"
success "branches.csv"
success "resumo.dat"
success "evolution.dat"

if [[ -s "$DISTRIBUTION_CHART" ]]; then
    success "distribuicao.png"
fi

if [[ -s "$EVOLUTION_CHART" ]]; then
    success "evolucao.png"
fi

echo
echo -e "${GREEN}Success!${RESET} Reports saved to ${BOLD}$OUTPUT${RESET}."
echo
echo "Done! Open the generated reports to view your commit analysis."

info "No branches or commits were modified or deleted."
#endregion
