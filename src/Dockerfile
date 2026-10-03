FROM ruby:2.7.8-alpine

WORKDIR /app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# build-base + sqlite-dev: compile native gem extensions (sqlite3, nokogiri).
# imagemagick: runtime dependency of the mini_magick gem.
# nodejs: JavaScript runtime for the asset pipeline (uglifier/execjs).
RUN apk add --no-cache \
        build-base \
        imagemagick \
        sqlite-dev \
        nodejs \
        tzdata

RUN gem update --system 3.4.22 --no-document \
    && gem install bundler -v 2.4.22 --no-document \
    && bundle config set --global force_ruby_platform true \
    && bundle config set --global build.sqlite3 --enable-system-libraries

COPY Gemfile Gemfile.lock ./
RUN BUNDLE_FROZEN=true bundle _2.4.22_ install

COPY . .

RUN bundle exec rails assets:precompile RAILS_ENV=production
