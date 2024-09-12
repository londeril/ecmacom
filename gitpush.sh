#!/bin/bash
# Automated Git Commit and Push Script

# Navigate to the project directory
cd ~/ecmacom

# Fetch and merge the latest changes from the remote main branch
git pull

# Stage all changes in the current directory and subdirectories
git add .

# Display the current status of the repository
git status

# Prompt the user for a commit message
read -p "Enter a descriptive commit message: " commit_message

# Commit the staged changes with the user-provided message
git commit -m "$commit_message"

# Push the committed changes to the remote repository
git push
