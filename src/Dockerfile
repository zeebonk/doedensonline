FROM python:3.8-slim

WORKDIR /app

RUN apt-get update -yqq && apt-get install -yqq \
    # Used by Heroku in the release phase for capturing logs
    curl \
    # For building uWSGI
    build-essential

# Keep build logs clean
ENV PIPENV_NOSPIN=1
ENV PIPENV_HIDE_EMOJIS=1
ENV PIPENV_COLORBLIND=1

RUN pip install --upgrade pip
RUN pip install pipenv

# Install packages in system as Heroku runs container with different user which
# will have a different place for storing virtualenvs
COPY Pipfile Pipfile.lock ./
RUN pipenv install --deploy --system

COPY manage.py ./
COPY doedensonline ./doedensonline
