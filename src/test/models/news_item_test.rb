require 'test_helper'

class NewsItemTest < ActiveSupport::TestCase
  test "requires a user" do
    news_item = NewsItem.new(message: 'Hi')
    refute news_item.valid?
    assert news_item.errors.added?(:user, :required)
  end
end
