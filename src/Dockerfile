FROM ruby:2.7.8-alpine

WORKDIR /app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# build-base + sqlite-dev: compile native gem extensions (sqlite3).
# gcompat: glibc loader for nokogiri's precompiled aarch64-linux gem on musl.
# imagemagick: runtime dependency of the mini_magick gem.
# nodejs: JavaScript runtime for the asset pipeline (uglifier/execjs).
RUN apk add --no-cache \
        build-base \
        gcompat \
        imagemagick \
        sqlite-dev \
        nodejs \
        tzdata

# Installs RubyGems from a downloaded gem: `gem update --system` on Ruby 2.7's
# RubyGems spends ~1 min fetching and parsing rubygems.org's full gem index.
# RubyGems 3.4.22 ships Bundler 2.4.22 as its default bundler.
RUN cd /tmp \
    && wget -q https://rubygems.org/downloads/rubygems-update-3.4.22.gem \
    && echo "dedab68acfef164f6d29257bb8d01bd6df1430ce4c0c3cf5b198aa211881d849  rubygems-update-3.4.22.gem" | sha256sum -c - \
    && gem install --local --no-document rubygems-update-3.4.22.gem \
    && update_rubygems --no-document \
    && gem uninstall --executables rubygems-update \
    && rm rubygems-update-3.4.22.gem \
    && bundle config set --global build.sqlite3 --enable-system-libraries

COPY Gemfile Gemfile.lock ./
RUN BUNDLE_FROZEN=true bundle _2.4.22_ install

COPY . .

RUN bundle exec rails assets:precompile RAILS_ENV=production
