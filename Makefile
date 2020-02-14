.PHONY: check
check:
	pipenv run isort --apply
	pipenv run black .
	pipenv run flake8
