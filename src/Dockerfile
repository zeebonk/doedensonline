FROM ruby:1.9.3-p551

WORKDIR /app
CMD passenger start -p 8080

COPY Gemfile Gemfile.lock ./
# Install precompiled binaries for gems whose C extensions segfault when built
# from source against Ruby 1.9.3 with the base image's modern toolchain.
RUN gem install json -v '1.8.6' && gem install sqlite3 -v '1.3.13'
RUN bundle install

COPY . .
