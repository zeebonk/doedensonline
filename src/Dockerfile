FROM ruby:2.1.10

WORKDIR /app
CMD bundle exec puma -C config/puma.rb

# Install nodejs for the asset pipeline's JavaScript runtime (uglifier/execjs).
# The base image ships with Debian jessie sources that now 404; point apt at the archive.
RUN printf 'deb http://archive.debian.org/debian jessie main\n' > /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false -o Acquire::AllowInsecureRepositories=true update \
    && apt-get -o APT::Get::AllowUnauthenticated=true install -y --force-yes --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 1.17.3 --no-document

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN bundle exec rake assets:precompile RAILS_ENV=production
