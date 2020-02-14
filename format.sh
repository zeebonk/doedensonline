set -euxo pipefail

pipenv run isort --apply
pipenv run black .
pipenv run flake8
