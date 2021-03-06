set -euxo pipefail

poetry run isort . --check --diff
poetry run black . --diff
poetry run flake8
docker-compose run --rm app ./manage.py makemigrations --check --dry-run
