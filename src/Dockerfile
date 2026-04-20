FROM ruby:1.9.3-p551

WORKDIR /app
CMD passenger start -p 8080

COPY Gemfile .
RUN bundle install

COPY . .
