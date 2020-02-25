FROM python:3.8.1-slim-buster

WORKDIR /app

RUN pip install --upgrade pip
RUN pip install pipenv

COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy

COPY manage.py ./
COPY doedensonline ./doedensonline

