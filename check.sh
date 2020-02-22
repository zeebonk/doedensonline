set -euxo pipefail

pipenv run isort --check-only --diff
pipenv run black --diff .
pipenv run flake8
pipenv run python manage.py makemigrations --check --dry-run
