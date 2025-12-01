#!/bin/bash

# --- Configuration ---
ORG_NAME="nhsbsa-data-analytics"
SECRET_NAME="GITLEAKS_LICENSE"

# --- Safety Check ---
if [ -z "$GITLEAKS_LICENSE_VALUE" ]; then
    echo "Error: GITLEAKS_LICENSE_VALUE environment variable is not set."
    echo "Usage: GITLEAKS_LICENSE_VALUE=\"your-key\" ./set_gitleaks_secrets.sh"
    exit 1
fi

echo "Fetching repository list for organization: $ORG_NAME..."

# Get all repositories with name and visibility.
# --source ensures we don't try to set secrets on forks.
# --limit 4000 ensures we get everything.
REPO_DATA=$(gh repo list "$ORG_NAME" --limit 4000 --source --json name,visibility --jq '.[] | "\(.name)|\(.visibility)"')

if [ -z "$REPO_DATA" ]; then
    echo "No repositories found or error fetching list."
    exit 1
fi

# Count lines for progress tracking
TOTAL_REPOS=$(echo "$REPO_DATA" | wc -l)
CURRENT_COUNT=0
UPDATED_COUNT=0
SKIPPED_PUBLIC_COUNT=0
SKIPPED_EXISTING_COUNT=0

echo "Processing $TOTAL_REPOS repositories..."

# Loop through each line of the repository data
while IFS="|" read -r REPO_NAME VISIBILITY; do
    ((CURRENT_COUNT++))
    FULL_REPO="$ORG_NAME/$REPO_NAME"
    
    # 1. VISIBILITY CHECK: Only proceed if the repo is PRIVATE
    # Note: 'gh' returns visibility in lowercase (public/private/internal)
    if [[ "$VISIBILITY" != "private" ]]; then
        ((SKIPPED_PUBLIC_COUNT++))
        # Clear line and print skip message transiently
        printf "\r\033[K[%d/%d] Skipping %s (%s)..." "$CURRENT_COUNT" "$TOTAL_REPOS" "$REPO_NAME" "$VISIBILITY"
        continue
    fi

    # 2. EXISTENCE CHECK: Check if secret already exists
    # We use grep -q for a silent check
    if gh secret list --repo "$FULL_REPO" --json name --jq '.[].name' 2>/dev/null | grep -q "^${SECRET_NAME}$"; then
        ((SKIPPED_EXISTING_COUNT++))
        printf "\r\033[K[%d/%d] Skipping %s (Secret already exists)..." "$CURRENT_COUNT" "$TOTAL_REPOS" "$REPO_NAME"
    else
        # 3. ACTION: Set the secret
        printf "\r\033[K[%d/%d] Setting secret for %s..." "$CURRENT_COUNT" "$TOTAL_REPOS" "$REPO_NAME"
        
        # We pipe the env var into gh secret set
        echo "$GITLEAKS_LICENSE_VALUE" | gh secret set "$SECRET_NAME" --repo "$FULL_REPO"
        
        if [ $? -eq 0 ]; then
            ((UPDATED_COUNT++))
            echo "" # New line to confirm success permanently on screen
            echo "   -> Successfully set secret for $REPO_NAME"
        else
            echo ""
            echo "   -> Error: Failed to set secret for $REPO_NAME"
        fi
    fi

done <<< "$REPO_DATA"

echo -e "\n------------------------------------------------"
echo "Process complete."
echo "Total Repos Scanned: $TOTAL_REPOS"
echo "Secrets Set:         $UPDATED_COUNT"
echo "Skipped (Public):    $SKIPPED_PUBLIC_COUNT"
echo "Skipped (Exists):    $SKIPPED_EXISTING_COUNT"

