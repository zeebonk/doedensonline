set -euxo pipefail

pipenv run flake8
docker-compose run --rm app pipenv run ./manage.py makemigrations --check --dry-run
