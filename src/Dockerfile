FROM ruby:1.9.3-p551

WORKDIR /app
CMD passenger start -p 8080

COPY Gemfile Gemfile.lock .
RUN bundle install

# Stub for a helper file ActionView::TestCase auto-loads but which does not
# exist in Rails 2.3.18 — without it, requiring 'test_help' fails on Ruby 1.9.
RUN mkdir -p /usr/local/bundle/gems/actionpack-2.3.18/lib/action_view/test_case \
    && touch /usr/local/bundle/gems/actionpack-2.3.18/lib/action_view/test_case/test_helper.rb

COPY . .
