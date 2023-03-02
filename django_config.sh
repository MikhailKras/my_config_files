#!/bin/bash

set -e

# Get inputs
echo "Enter Django project name: "
read PROJECT_NAME

echo "Enter dir name for the project: "
read DIR_NAME

echo "Do you want to push project on github? (y/n): "
read REMOTE_STATE

if [ "$REMOTE_STATE" = "y" ]; then
	echo "Enter Github repository URL: "
	read REPO_URL
elif [ "$REMOTE_STATE" != "n" ]; then
	echo "Incorrect answer!"
	exit
fi

# Function for deleting a dir with a project if error
undo() {
  rm -r $ABS_DIR_PATH
  echo "Error occured, $ABS_DIR_PATH dir with project deleted"
}

# Make and choose file path dir
if [ -d $DIR_NAME ]; then
	echo "This directory already exist!"
	exit
else
	mkdir $DIR_NAME
	cd $DIR_NAME
	ABS_DIR_PATH=$(pwd)
fi

# Trap the exit signal and run the undo functions on exit
trap 'undo' EXIT

# Create virtual environment
python3.11 -m venv .venv
. .venv/bin/activate
echo "virtual env .venv created"

# Install Django and other python packages
pip install django
pip install python-dotenv

# Create Django project
django-admin startproject $PROJECT_NAME
cd $PROJECT_NAME
echo "Django project $PROJECT_NAME created"

# Create .gitignore, config.py, requirements.txt
cat /home/mikhail/config_files/django_gitignore > .gitignore
cat /home/mikhail/config_files/config.py > config.py
pip freeze > requirements.txt
echo ".gitignore, config.py, requirements.txt created"

#Create .env
SECRET_KEY_ROW=$(cat $PROJECT_NAME/settings.py | grep 'SECRET*')
echo "$SECRET_KEY_ROW" > .env
echo ".env created"

#Replace SECRET_KEY in settings.py
sed -i '14i from config import SECRET_KEY' $PROJECT_NAME/settings.py
# sed -i "s|$SECRET_KEY_ROW|SECRET_KEY = SECRET_KEY|g" $PROJECT_NAME/settings.py
sed -i 's/SECRET_KEY =.*/SECRET_KEY = SECRET_KEY/' $PROJECT_NAME/settings.py

# Remove the trap
trap - EXIT

#Initialize Git repo
git init
git add .
git commit -m "initial commit"

#Add remote repo and push to Github
if [ "$REMOTE_STATE" = "y" ]; then
	git remote add origin $REPO_URL
	git push -u origin master
fi
