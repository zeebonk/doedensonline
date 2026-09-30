FROM ruby:2.6.10-slim

WORKDIR /app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# build-essential + libsqlite3-dev: compile native gem extensions (sqlite3, nokogiri).
# imagemagick: runtime dependency of the mini_magick gem.
# nodejs: JavaScript runtime for the asset pipeline (uglifier/execjs).
# Use the Debian snapshot that matches Ruby 2.6.10's final base image.
RUN printf 'deb http://snapshot.debian.org/archive/debian/20220418T000000Z bullseye main\n' > /etc/apt/sources.list \
    && printf 'deb http://snapshot.debian.org/archive/debian-security/20220418T000000Z bullseye-security main\n' >> /etc/apt/sources.list \
    && printf 'deb http://snapshot.debian.org/archive/debian/20220418T000000Z bullseye-updates main\n' >> /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        imagemagick \
        libsqlite3-dev \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem update --system 3.2.3 --no-document \
    && gem install bundler -v 2.4.22 --no-document \
    && bundle config set --global build.sqlite3 --with-sqlite3-dir=/usr

COPY Gemfile Gemfile.lock ./
RUN bundle _2.4.22_ install

COPY . .

RUN bundle exec rails assets:precompile RAILS_ENV=production
