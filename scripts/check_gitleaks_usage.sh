#!/bin/bash

# --- Configuration ---
ORG_NAME="nhsbsa-data-analytics"
SECRET_NAME="GITLEAKS_LICENSE"
OUTPUT_FILE="outputs/repos_gitleaks_status.csv"

# --- Script ---

echo "Fetching repository list for organization: $ORG_NAME..."

# Initialize CSV file with headers
echo "repo_name,visibility,has_gitleaks_workflow,has_gitleaks_secret" > "$OUTPUT_FILE"

# Get all repositories with name and visibility.
# We format the output as "name|visibility" to easily split it later.
REPO_DATA=$(gh repo list "$ORG_NAME" --limit 4000 --source --json name,visibility --jq '.[] | "\(.name)|\(.visibility)"')

if [ -z "$REPO_DATA" ]; then
    echo "No repositories found or error fetching list."
    exit 1
fi

# Count lines for progress tracking
TOTAL_REPOS=$(echo "$REPO_DATA" | wc -l)
CURRENT_COUNT=0

echo "Scanning $TOTAL_REPOS repositories..."

# Loop through each line of the repository data
while IFS="|" read -r REPO_NAME VISIBILITY; do
    ((CURRENT_COUNT++))
    FULL_REPO="$ORG_NAME/$REPO_NAME"
    
    # Progress indicator
    # \r = Move to start of line
    # \033[K = Clear to end of line
    printf "\r\033[K[%d/%d] Checking %s..." "$CURRENT_COUNT" "$TOTAL_REPOS" "$REPO_NAME"

    # 1. Check for files containing "gitleaks" in .github/workflows
    if gh api "repos/$FULL_REPO/contents/.github/workflows" --jq '.[].name' 2>/dev/null | grep -iq "gitleaks"; then
        HAS_GITLEAKS_WORKFLOW="TRUE"
    else
        HAS_GITLEAKS_WORKFLOW="FALSE"
    fi

    # 2. Check if the specific Secret exists
    if gh secret list --repo "$FULL_REPO" --json name --jq '.[].name' 2>/dev/null | grep -q "^${SECRET_NAME}$"; then
        HAS_SECRET="TRUE"
    else
        HAS_SECRET="FALSE"
    fi

    # Append to CSV
    echo "$REPO_NAME,$VISIBILITY,$HAS_GITLEAKS_WORKFLOW,$HAS_SECRET" >> "$OUTPUT_FILE"

done <<< "$REPO_DATA"

echo -e "\n------------------------------------------------"
echo "Scan complete."
echo "Results saved to: $OUTPUT_FILE"
