FROM ruby:1.9.3-p551

WORKDIR /app
CMD passenger start -p 8080 --static-files-dir ./public

RUN gem install rake -v 10.1.1
COPY Gemfile Gemfile.lock .
RUN bundle install

COPY en.yml /usr/local/bundle/gems/activesupport-2.3.8/lib/active_support/locale

# Stub for a helper file ActionView::TestCase auto-loads but which does not
# exist in Rails 2.3.8 — without it, requiring 'test_help' fails on Ruby 1.9.
RUN mkdir -p /usr/local/bundle/gems/actionpack-2.3.8/lib/action_view/test_case \
    && touch /usr/local/bundle/gems/actionpack-2.3.8/lib/action_view/test_case/test_helper.rb

COPY . .
