require 'test_helper'

# Posts HTML through each rich text field and checks what the pages render.
class RichTextRenderingTest < ActionDispatch::IntegrationTest
  PAYLOAD = '<p>Hello <strong>bold</strong> <a href="https://example.com/">link</a></p>' \
            '<ul><li>item</li></ul>' \
            '<script>alert("script")</script>' \
            '<img src="x" onerror="alert(\'img\')">' \
            '<a href="javascript:alert(\'href\')">bad link</a>'.freeze

  def setup
    NewsComment.delete_all
    NewsItem.delete_all
    PhotoAlbumComment.delete_all
    PhotoAlbumPicture.delete_all
    PhotoAlbum.delete_all
    User.delete_all

    @user = create_user!(
      first_name: 'Alice',
      last_name: 'Anderson',
      email: 'alice@example.com',
      password: 'secret',
      notify_news: false,
      notify_photo_album: false,
      isadmin: false
    )
    @news_item = NewsItem.create!(message: 'Existing news', user_id: @user.id)
    @photo_album = PhotoAlbum.create!(title: 'Trip', description: 'Summer trip', user_id: @user.id)

    sign_in_as @user
  end

  test "news item message on the news index" do
    post '/news', params: { news_item: { message: PAYLOAD } }
    get '/news'
    assert_sanitized
  end

  test "news item message on the news item page" do
    patch "/news/#{@news_item.id}", params: { news_item: { message: PAYLOAD } }
    get "/news/#{@news_item.id}"
    assert_sanitized
  end

  test "news comment message on the news item page" do
    post "/news/#{@news_item.id}/comments", params: { news_comment: { message: PAYLOAD } }
    get "/news/#{@news_item.id}"
    assert_sanitized
  end

  test "photo album description on the photo album page" do
    patch "/photo_albums/#{@photo_album.id}", params: { photo_album: { title: 'Trip', description: PAYLOAD } }
    get "/photo_albums/#{@photo_album.id}"
    assert_sanitized
  end

  test "photo album comment message on the photo album page" do
    post "/photo_albums/#{@photo_album.id}/comments", params: { photo_album_comment: { message: PAYLOAD } }
    get "/photo_albums/#{@photo_album.id}"
    assert_sanitized
  end

  test "news item preview on the home page is plain text" do
    patch "/news/#{@news_item.id}", params: { news_item: { message: PAYLOAD } }
    get '/'

    assert_response :success
    assert_select '.preview-balloon-content p', text: 'Hello bold link item bad link'
    assert_select '.preview-balloon-content strong', 0
    assert_no_payload
  end

  test "news item preview on the home page escapes decoded entities" do
    patch "/news/#{@news_item.id}", params: { news_item: { message: '<p>Tom &amp; Jerry &lt;img src=x onerror=alert(1)&gt;</p>' } }
    get '/'

    assert_response :success
    assert_includes response.body, 'Tom &amp; Jerry &lt;img src=x onerror=alert(1)&gt;'
    assert_select '[onerror]', 0
  end

  test "news item preview on the home page drops an unclosed tag" do
    patch "/news/#{@news_item.id}", params: { news_item: { message: 'Hello <img src=x onerror=alert(1)' } }
    get '/'

    assert_response :success
    assert_select '.preview-balloon-content p', text: 'Hello'
    assert_select '[onerror]', 0
  end

  private

  def assert_sanitized
    assert_response :success
    assert_select 'strong', text: 'bold'
    assert_select 'a[href="https://example.com/"]', text: 'link'
    assert_select 'li', text: 'item'
    assert_select 'a', text: 'bad link' do |links|
      links.each { |link| assert_nil link['href'] }
    end
    assert_no_payload
  end

  def assert_no_payload
    assert_empty(css_select('script').select { |script| script.text.include?('alert') })
    assert_select '[onerror]', 0
    assert_select '[href^="javascript"]', 0
    assert_not_includes response.body, '<script>alert'
  end
end
