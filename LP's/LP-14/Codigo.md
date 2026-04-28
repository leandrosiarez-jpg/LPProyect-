
# --- Codigo ---

#!/bin/bash


PROYECTO="mi-proyecto-red"
USER_NAME="Mateo"
USER_EMAIL="tu-email@ejemplo.com"
REPO_URL="https://github.com/tu-usuario/mi-proyecto-red.git"

git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

mkdir $PROYECTO
cd $PROYECTO
git init

git add README.md
git commit -m "Primer commit: Estableciendo base del proyecto"

git remote add origin $REPO_URL
