require 'test_helper'

class NewsItemTest < ActiveSupport::TestCase
  test "requires a user" do
    news_item = NewsItem.new(message: 'Hi')
    assert_not news_item.valid?
    assert_includes news_item.errors[:user], I18n.t('errors.messages.required')
  end

  test "preview returns the message as plain text" do
    news_item = NewsItem.new(message: '<p>Hallo&nbsp;&euml;</p><p>Tom &amp; Jerry<br>&lt;b&gt;</p>')
    assert_equal 'Hallo ë Tom & Jerry <b>', news_item.preview(140)
    assert_not news_item.preview(140).html_safe?
  end

  test "preview drops script and style contents" do
    news_item = NewsItem.new(message: 'a<script>alert(1)</script><style>p {}</style>b')
    assert_equal 'ab', news_item.preview(140)
  end

  test "preview drops an unclosed tag" do
    news_item = NewsItem.new(message: 'Hello <img src=x onerror=alert(1)')
    assert_equal 'Hello', news_item.preview(140)
  end

  test "preview truncates long messages" do
    news_item = NewsItem.new(message: '<p>abc def ghi</p>')
    assert_equal 'abc def...', news_item.preview(8)
    assert_equal 'abc def ghi', news_item.preview(11)
  end
end
