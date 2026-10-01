require 'test_helper'

class NewsCommentTest < ActiveSupport::TestCase
  test "requires a user" do
    comment = NewsComment.new(message: 'Hi', news_item: news_items(:one))
    refute comment.valid?
    assert_includes comment.errors[:user], I18n.t('errors.messages.required')
  end

  test "requires a news item" do
    comment = NewsComment.new(message: 'Hi', user: users(:one))
    refute comment.valid?
    assert_includes comment.errors[:news_item], I18n.t('errors.messages.required')
  end
end
