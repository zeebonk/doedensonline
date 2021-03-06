set -euxo pipefail

poetry run isort --apply
poetry run black .
