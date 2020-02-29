set -euxo pipefail

pipenv run isort --apply
pipenv run black .
