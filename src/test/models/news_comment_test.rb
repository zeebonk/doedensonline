require 'test_helper'

class NewsCommentTest < ActiveSupport::TestCase
  test "requires a user" do
    comment = NewsComment.new(message: 'Hi', news_item: news_items(:one))
    refute comment.valid?
    assert comment.errors.added?(:user, :required)
  end

  test "requires a news item" do
    comment = NewsComment.new(message: 'Hi', user: users(:one))
    refute comment.valid?
    assert comment.errors.added?(:news_item, :required)
  end
end
