FROM python:3.8-slim

WORKDIR /app

RUN apt-get update -yqq && apt-get install -yqq \
    # Used by Heroku in the release phase for capturing logs
    curl \
    # For building uWSGI
    build-essential

RUN pip install poetry

# Install packages in system as Heroku runs container with different user which
# will have a different place for storing virtualenvs
COPY pyproject.toml poetry.lock ./
RUN poetry install --no-dev

COPY manage.py ./
COPY doedensonline ./doedensonline
