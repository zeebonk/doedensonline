require 'test_helper'

class RichTextHelperTest < ActionView::TestCase
  test "keeps the markup the editor produces" do
    html = '<p>a<br><strong>b</strong> <b>c</b> <em>d</em> <i>e</i> <u>f</u> <s>g</s> <strike>h</strike> <del>i</del></p>' \
           '<ul><li>j</li></ul><ol><li>k</li></ol>'
    assert_equal html, rich_text(html)
  end

  test "keeps underline styling on spans" do
    assert_equal '<span style="text-decoration:underline;">a</span>',
                 rich_text('<span style="text-decoration: underline;">a</span>')
  end

  test "drops unsafe CSS" do
    assert_equal '<span style="">a</span>', rich_text('<span style="background: url(javascript:alert(1));">a</span>')
  end

  test "keeps http, https, mailto and relative links" do
    %w[http://example.com/ https://example.com/ mailto:a@example.com /news/1 #top].each do |href|
      html = %(<a href="#{href}">a</a>)
      assert_equal html, rich_text(html)
    end
  end

  test "drops script links" do
    ['javascript:alert(1)', ' JaVaScRiPt:alert(1)', "java\tscript:alert(1)", 'javascript&#58;alert(1)',
     'data:text/html,<script>alert(1)</script>'].each do |href|
      assert_equal '<a>a</a>', rich_text(%(<a href="#{href}">a</a>)), href
    end
  end

  test "keeps images from older posts" do
    html = '<img src="/images/smiley.gif" alt="smile" title="smile">'
    assert_equal html, rich_text(html)
  end

  test "drops event handlers and unsafe image sources" do
    assert_equal '<img src="x">', rich_text('<img src="x" onerror="alert(1)">')
    assert_equal '<img>', rich_text('<img src="javascript:alert(1)">')
  end

  test "strips other tags but keeps their text" do
    assert_equal 'a', rich_text('<div>a</div>')
    assert_equal 'b', rich_text('<iframe>b</iframe>')
    assert_equal '', rich_text('<!-- c -->')
  end

  test "drops scripts" do
    assert_not_includes rich_text('a<script>alert(1)</script>'), '<script'
  end

  test "returns nil for nil" do
    assert_nil rich_text(nil)
  end
end
