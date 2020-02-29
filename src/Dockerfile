FROM python:3.8.1-slim-buster

WORKDIR /app

RUN apt-get update -yqq \
 && apt-get install curl -yqq

ENV PIPENV_NOSPIN=1
ENV PIPENV_HIDE_EMOJIS=1
ENV PIPENV_COLORBLIND=1

RUN pip install --upgrade pip
RUN pip install pipenv

COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy --system

COPY manage.py ./
COPY doedensonline ./doedensonline
