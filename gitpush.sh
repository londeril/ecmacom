#!/bin/sh
# git commit script to automate the most common usecase 

# make sure we are in the right directory
cd ~/ecmacom

# make sure we are at the latest version of main
git pull

# add everything since the last git commit
git add ./*

# display status
git status

# ask the user for a sensible git commit
read -p "what are you commiting? " commitstatement

# commiting changes using user input as comment
git commit -m "$commitstatement"

# push changes to repo
git push
