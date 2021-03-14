FROM python:3.9-slim

ARG PROJECT=doedensonline
ENV POETRY_VIRTUALENVS_IN_PROJECT=true

RUN groupadd -r $PROJECT \
    && useradd -m --no-log-init -r -g $PROJECT $PROJECT
WORKDIR /$PROJECT
RUN chown -R $PROJECT:$PROJECT /$PROJECT

RUN apt-get update -yqq && apt-get install -yqq \
        # Used by Heroku in the release phase for capturing logs
        curl \
        # For building uWSGI
        build-essential \
    && pip install poetry

USER $PROJECT

COPY pyproject.toml poetry.lock ./
ARG POETRY_INSTALL_ARGS=--no-dev
RUN poetry install $POETRY_INSTALL_ARGS

COPY $PROJECT ./$PROJECT
