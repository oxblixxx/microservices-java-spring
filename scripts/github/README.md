USE THIS TO MANAGE THE GITHUB ENVIRONMENT VARIABLES AND SECRETS


run python3 -m venv .venv
source .venv/bin/activate
pip install requirements.txt
cp .env.example .env
cp .env.github.example .env.github
python3 add_secrets.py

