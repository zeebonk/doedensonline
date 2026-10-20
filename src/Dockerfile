FROM ruby:4.0.7-alpine

WORKDIR /app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# build-base: compile native gem extensions (json, nio4r, pg, puma, sqlite3,
# ...). libpq-dev and sqlite-dev provide their database client libraries.
# imagemagick: runtime dependency of the mini_magick gem.
# imagemagick-jpeg: Alpine ships ImageMagick's JPEG coder separately. Uploads
#   are resized to JPEG; PNG, GIF and BMP are built into imagemagick itself.
RUN apk add --no-cache \
        build-base \
        imagemagick \
        imagemagick-jpeg \
        libpq-dev \
        sqlite-dev \
        tzdata

COPY Gemfile Gemfile.lock ./
RUN bundle config set force_ruby_platform true && \
    bundle config set build.sqlite3 --with-system-libraries
RUN bundle install

COPY . .

RUN bundle exec rails assets:precompile RAILS_ENV=production
