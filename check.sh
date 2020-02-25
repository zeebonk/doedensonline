set -euxo pipefail

pipenv run isort --check-only --diff
pipenv run black --diff .
pipenv run flake8
docker-compose run --rm app pipenv run ./manage.py makemigrations --check --dry-run
