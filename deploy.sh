#!/bin/sh

# If a command fails then the deploy stops
set -e

printf "\033[0;32mDeploying updates to GitHub...\033[0m\n"

# Build the project.
hugo --minify # if using a theme, replace with `hugo -t <YOURTHEME>`

# Go To Public folder
cd public

# checkout master
git checkout master

# copy README.md to current directory
cp ../README.md ./

# Add changes to git.
git add .

# Commit changes.
msg="rebuilding site $(date)"
if [ -n "$*" ]; then
	msg="$*"
fi
git commit -m "$msg" || exit 0

# Push source and build repos.
git push origin master