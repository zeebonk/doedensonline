FROM ruby:1.9.3-p551

WORKDIR /app
CMD passenger start -p 8080 --static-files-dir ./public

RUN gem install rake -v 10.1.1
COPY Gemfile Gemfile.lock .
RUN bundle install

COPY en.yml /usr/local/bundle/gems/activesupport-2.3.8/lib/active_support/locale
COPY * .
