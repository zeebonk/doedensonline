FROM python:3.8.1-slim-buster

WORKDIR /app

ENV PIPENV_NOSPIN=1
ENV PIPENV_HIDE_EMOJIS=1
ENV PIPENV_COLORBLIND=1

RUN pip install --upgrade pip
RUN pip install pipenv

COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy

COPY manage.py ./
COPY doedensonline ./doedensonline
