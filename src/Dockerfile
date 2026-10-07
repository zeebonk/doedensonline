FROM ruby:3.3.12-alpine

WORKDIR /app
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

# build-base + sqlite-dev: compile native gem extensions (sqlite3).
# imagemagick: runtime dependency of the mini_magick gem.
# imagemagick-jpeg: Alpine ships ImageMagick's JPEG coder separately. Uploads
#   are resized to JPEG; PNG, GIF and BMP are built into imagemagick itself.
# nodejs: JavaScript runtime for the asset pipeline (terser/execjs).
RUN apk add --no-cache \
        build-base \
        imagemagick \
        imagemagick-jpeg \
        sqlite-dev \
        nodejs \
        tzdata

RUN gem update --system 4.0.22 --no-document \
    && bundle config set --global build.sqlite3 --enable-system-libraries

COPY Gemfile Gemfile.lock ./
RUN BUNDLE_FROZEN=true bundle _4.0.22_ install

COPY . .

RUN bundle exec rails assets:precompile RAILS_ENV=production
