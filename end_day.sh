#!/bin/bash

echo "Staging all changes..."
git add .

echo "Enter your commit message describing today's work:"
read commit_message

echo "Creating commit..."
git commit -m "$commit_message"

echo "Pushing to GitHub..."
git push origin main

echo "Great work today! Your changes are now on GitHub. 🎉" 