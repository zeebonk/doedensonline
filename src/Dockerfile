FROM ruby:2.5.9-slim

WORKDIR /app
CMD bundle exec puma -C config/puma.rb

# build-essential + libsqlite3-dev: compile native gem extensions (sqlite3, nokogiri).
# imagemagick: runtime dependency of the mini_magick gem.
# nodejs: JavaScript runtime for the asset pipeline (uglifier/execjs).
# The base image ships with Debian buster sources that now 404; point apt at the archive.
RUN printf 'deb http://archive.debian.org/debian buster main\n' > /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        imagemagick \
        libsqlite3-dev \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 1.17.3 --no-document

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN bundle exec rake assets:precompile RAILS_ENV=production
