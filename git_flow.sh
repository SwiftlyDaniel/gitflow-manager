#!/bin/bash

# Step 1: List repositories in the Developer folder
REPO_DIR=~/Developer
cd "$REPO_DIR" || exit
REPOS=(*)

# Step 2: Select a repository using fzf
SELECTED_REPO=$(printf '%s\n' "${REPOS[@]}" | fzf --height 40% --reverse --border)

# Check if a repository was selected
if [ -z "$SELECTED_REPO" ]; then
    echo "No repository selected. Exiting."
    exit 1
fi

cd "$SELECTED_REPO" || exit

# Step 3: Checkout develop branch and pull changes
git checkout develop
git pull

# Step 4: Checkout main or master branch and pull changes
if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
else
    git checkout master
fi
git pull

# Step 5: Ask for feature or hotfix
read -p "Do you want to create a new feature or a hotfix? (f/h): " TYPE

# Step 6: Provide ticket number
read -p "Enter the ticket number: " TICKET_NUMBER

# Step 7: Provide branch name and convert to git-style format
read -p "Enter the branch name: " BRANCH_NAME
BRANCH_NAME=$(echo "$BRANCH_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')

# Step 8 & 9: Create the new branch
if [[ "$TYPE" == "f" ]]; then
    git checkout -b "feature/${TICKET_NUMBER}-${BRANCH_NAME}" develop
elif [[ "$TYPE" == "h" ]]; then
    if git show-ref --verify --quiet refs/heads/main; then
        git checkout -b "hotfix/${TICKET_NUMBER}-${BRANCH_NAME}" main
    else
        git checkout -b "hotfix/${TICKET_NUMBER}-${BRANCH_NAME}" master
    fi
else
    echo "Invalid option. Exiting."
    exit 1
fi

# Step 10: Open the project folder in VSCode Insiders
code-insiders "$(pwd)"