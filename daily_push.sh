#!/bin/bash

# Pull latest changes
echo "Pulling latest changes..."
git pull origin main

# Add all changes
echo "Adding changes..."
git add .

# Get commit message from user
echo "Enter your commit message:"
read commit_message

# Commit changes
echo "Committing changes..."
git commit -m "$commit_message"

# Push changes
echo "Pushing to remote..."
git push origin main

echo "Daily push completed successfully!" 