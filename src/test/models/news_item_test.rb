require 'test_helper'

class NewsItemTest < ActiveSupport::TestCase
  test "requires a user" do
    news_item = NewsItem.new(message: 'Hi')
    refute news_item.valid?
    assert_includes news_item.errors[:user], I18n.t('errors.messages.required')
  end
end
