FROM ruby:1.9.3-p551

WORKDIR /app
CMD passenger start -p 8080

# Install nodejs for the asset pipeline's JavaScript runtime (uglifier/execjs).
# The base image ships with Debian jessie sources that now 404; point apt at the archive.
RUN printf 'deb http://archive.debian.org/debian jessie main\n' > /etc/apt/sources.list \
    && apt-get -o Acquire::Check-Valid-Until=false -o Acquire::AllowInsecureRepositories=true update \
    && apt-get -o APT::Get::AllowUnauthenticated=true install -y --force-yes --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
# Install precompiled binaries for gems whose C extensions segfault when built
# from source against Ruby 1.9.3 with the base image's modern toolchain.
RUN gem install json -v '1.8.6' \
    && gem install sqlite3 -v '1.3.13' \
    && gem install rack -v '1.4.7' \
    && gem install passenger -v '5.3.7'
RUN bundle install

COPY . .

RUN bundle exec rake assets:precompile RAILS_ENV=production
