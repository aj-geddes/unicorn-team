#!/usr/bin/env bash
set -euo pipefail

# Colors for better UX
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Parse command line arguments
OUTPUT_FILE=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            echo "Usage: estimate.sh [--output <filename>]"
            exit 1
            ;;
    esac
done

# Helper function for input validation
validate_number() {
    local input="$1"
    if [[ ! "$input" =~ ^[0-9]+\.?[0-9]*$ ]]; then
        return 1
    fi
    return 0
}

# Header
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}"
echo -e "${BOLD}${BLUE}     📊 Task Estimation Helper (PERT Method)      ${RESET}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}"
echo ""

# Task Description
echo -e "${CYAN}${BOLD}Task Description:${RESET}"
read -p "→ " TASK
echo ""

# Subtasks Collection
echo -e "${CYAN}${BOLD}📋 Subtasks Breakdown:${RESET}"
echo -e "${YELLOW}(Enter subtasks one per line. Empty line to finish)${RESET}"
echo ""

declare -a SUBTASKS
declare -a OPTIMISTIC
declare -a REALISTIC
declare -a PESSIMISTIC
declare -a PERT_VALUES

SUBTASK_NUM=1
while true; do
    echo -e "${GREEN}Subtask #$SUBTASK_NUM:${RESET}"
    read -p "  Description: " SUBTASK
    [[ -z "$SUBTASK" ]] && break

    # Get O/R/P estimates with validation
    while true; do
        read -p "  Optimistic (hours): " OPT
        if validate_number "$OPT"; then
            break
        else
            echo -e "${RED}  ⚠️  Please enter a valid number${RESET}"
        fi
    done

    while true; do
        read -p "  Realistic (hours): " REAL
        if validate_number "$REAL"; then
            break
        else
            echo -e "${RED}  ⚠️  Please enter a valid number${RESET}"
        fi
    done

    while true; do
        read -p "  Pessimistic (hours): " PESS
        if validate_number "$PESS"; then
            break
        else
            echo -e "${RED}  ⚠️  Please enter a valid number${RESET}"
        fi
    done

    # Calculate PERT for this subtask
    PERT=$(echo "scale=2; ($OPT + 4*$REAL + $PESS) / 6" | bc)

    SUBTASKS+=("$SUBTASK")
    OPTIMISTIC+=("$OPT")
    REALISTIC+=("$REAL")
    PESSIMISTIC+=("$PESS")
    PERT_VALUES+=("$PERT")

    echo -e "${BLUE}  → PERT estimate: ${PERT}h${RESET}"
    echo ""

    SUBTASK_NUM=$((SUBTASK_NUM + 1))
done

if [[ ${#SUBTASKS[@]} -eq 0 ]]; then
    echo -e "${RED}❌ No subtasks entered. Exiting.${RESET}"
    exit 1
fi

echo ""

# Unknowns/Risks Collection
echo -e "${CYAN}${BOLD}⚠️  Unknowns & Risks:${RESET}"
echo -e "${YELLOW}(Enter risks one per line. Empty line to finish)${RESET}"
echo ""

declare -a RISKS
RISK_NUM=1
while true; do
    read -p "  Risk #$RISK_NUM: " RISK
    [[ -z "$RISK" ]] && break
    RISKS+=("$RISK")
    RISK_NUM=$((RISK_NUM + 1))
done

echo ""

# Calculations
echo -e "${CYAN}${BOLD}🔢 Calculating Estimates...${RESET}"
echo ""

# Sum all PERT values
TOTAL_PERT=0
for pert in "${PERT_VALUES[@]}"; do
    TOTAL_PERT=$(echo "scale=2; $TOTAL_PERT + $pert" | bc)
done

# Calculate risk buffer (0.5h per risk)
set +u  # Temporarily disable unbound variable check for empty array
RISK_COUNT=${#RISKS[@]}
set -u  # Re-enable unbound variable check
RISK_BUFFER=$(echo "scale=2; $RISK_COUNT * 0.5" | bc)

# Final estimate
FINAL_ESTIMATE=$(echo "scale=2; $TOTAL_PERT + $RISK_BUFFER" | bc)

# Calculate confidence interval (±15% of PERT)
UNCERTAINTY=$(echo "scale=1; $TOTAL_PERT * 0.15" | bc)

# Determine confidence level
if [[ $RISK_COUNT -eq 0 ]]; then
    CONFIDENCE="High (85-95%)"
    CONFIDENCE_COLOR="${GREEN}"
elif [[ $RISK_COUNT -le 2 ]]; then
    CONFIDENCE="Medium (60-80%)"
    CONFIDENCE_COLOR="${YELLOW}"
else
    CONFIDENCE="Low (40-60%)"
    CONFIDENCE_COLOR="${RED}"
fi

# Generate output
OUTPUT=$(cat <<EOF

${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}
${BOLD}${BLUE}              📊 ESTIMATION SUMMARY                ${RESET}
${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}

${CYAN}${BOLD}Task:${RESET} $TASK

${CYAN}${BOLD}Subtasks Breakdown:${RESET}
EOF
)

# Add subtask table
for i in "${!SUBTASKS[@]}"; do
    OUTPUT+=$(cat <<EOF

  ${GREEN}$((i+1)). ${SUBTASKS[$i]}${RESET}
     Optimistic:  ${OPTIMISTIC[$i]}h
     Realistic:   ${REALISTIC[$i]}h
     Pessimistic: ${PESSIMISTIC[$i]}h
     ${BLUE}PERT:        ${PERT_VALUES[$i]}h${RESET}
EOF
)
done

OUTPUT+=$(cat <<EOF


${CYAN}${BOLD}Identified Risks (${RISK_COUNT}):${RESET}
EOF
)

if [[ $RISK_COUNT -gt 0 ]]; then
    for i in "${!RISKS[@]}"; do
        OUTPUT+=$(cat <<EOF

  ${YELLOW}⚠️  $((i+1)). ${RISKS[$i]}${RESET}
EOF
)
    done
else
    OUTPUT+=$(cat <<EOF

  ${GREEN}✓ No explicit risks identified${RESET}
EOF
)
fi

OUTPUT+=$(cat <<EOF


${CYAN}${BOLD}Calculation Details:${RESET}
  Total PERT (sum):     ${TOTAL_PERT}h
  Risk Buffer:          ${RISK_BUFFER}h  (${RISK_COUNT} risks × 0.5h)
  ${BOLD}Final Estimate:       ${FINAL_ESTIMATE}h${RESET}

${CYAN}${BOLD}Confidence:${RESET} ${CONFIDENCE_COLOR}${CONFIDENCE}${RESET}

${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}
${BOLD}${GREEN}   📌 RECOMMENDED ESTIMATE                         ${RESET}
${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}

${BOLD}${GREEN}${FINAL_ESTIMATE} hours (±${UNCERTAINTY} hours)${RESET}

${CYAN}${BOLD}Communication Template:${RESET}
${BOLD}"${FINAL_ESTIMATE} hours (±${UNCERTAINTY} hours) assuming normal conditions.${RESET}
EOF
)

if [[ $RISK_COUNT -gt 0 ]]; then
    OUTPUT+=$(cat <<EOF

${BOLD}Risks:${RESET}
EOF
)
    for i in "${!RISKS[@]}"; do
        OUTPUT+=$(cat <<EOF
 ${RISKS[$i]}
EOF
)
        if [[ $i -lt $((RISK_COUNT - 1)) ]]; then
            OUTPUT+=","
        else
            OUTPUT+="."
        fi
    done
    OUTPUT+=$(cat <<EOF
${BOLD}"${RESET}
EOF
)
else
    OUTPUT+=$(cat <<EOF
${BOLD}No significant risks identified."${RESET}
EOF
)
fi

OUTPUT+=$(cat <<EOF


${CYAN}${BOLD}Assumptions:${RESET}
  • Estimates based on ${#SUBTASKS[@]} subtasks
  • Normal working conditions
  • Resources available as needed
  • No major blockers or dependencies

${YELLOW}${BOLD}⚠️  Remember to re-estimate if:${RESET}
  • Requirements change
  • New unknowns discovered
  • Overrun exceeds 20%
  • Team or resource changes

${BOLD}${BLUE}═══════════════════════════════════════════════════${RESET}
EOF
)

# Display output
echo -e "$OUTPUT"

# Save to file if requested
if [[ -n "$OUTPUT_FILE" ]]; then
    # Strip color codes for file output
    echo -e "$OUTPUT" | sed -r 's/\x1B\[[0-9;]*[mK]//g' | sed 's/\\033\[[0-9;]*m//g' > "$OUTPUT_FILE"
    echo ""
    echo -e "${GREEN}✓ Estimate saved to: ${OUTPUT_FILE}${RESET}"
fi

echo ""
echo -e "${BOLD}${GREEN}✅ Estimation complete!${RESET}"
echo ""
