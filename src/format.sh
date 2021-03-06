set -euxo pipefail

poetry run isort .
poetry run black .
