require 'test_helper'

class PhotoAlbumPicturesControllerTest < ActionDispatch::IntegrationTest
  def setup
    PhotoAlbumPicture.delete_all
    PhotoAlbum.delete_all
    User.delete_all

    # Clean up any image files leaked by prior tests in the suite.
    %w[small medium large].each do |size|
      Dir.glob(Rails.root.join('public', 'images', size, '*')).each do |path|
        next if %w[temp.bmp preview.jpg].include?(File.basename(path))

        File.delete(path)
      end
    end

    @user = create_user!(
      first_name: 'Alice',
      last_name: 'Anderson',
      email: 'alice@example.com',
      password: 'secret',
      notify_news: false,
      isadmin: false
    )
    @photo_album = PhotoAlbum.create!(
      title: 'Trip',
      description: 'Summer trip',
      user_id: @user.id
    )

    sign_in_as @user
  end

  def uploaded_jpeg_fixture
    fixture_file_upload(Rails.root.join('test', 'fixtures', 'files', 'sample.jpg').to_s,
                        'image/jpeg', :binary)
  end

  def uploaded_bad_extension_fixture
    upload = fixture_file_upload(Rails.root.join('test', 'fixtures', 'files', 'sample.jpg').to_s,
                                 'application/octet-stream', :binary)
    upload.instance_variable_set(:@original_filename, 'evil.exe')
    upload
  end

  # Authorization

  test "redirects to sign_in when not signed in" do
    reset!
    get "/photo_albums/#{@photo_album.id}/pictures"
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /photo_albums/:photo_album_id/pictures

  test "index renders the manage page for the album" do
    get "/photo_albums/#{@photo_album.id}/pictures"
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
  end

  test "index redirects when album does not exist" do
    get '/photo_albums/999999/pictures'
    assert_redirected_to '/photo_albums'
    assert_equal 'Opgegeven fotoalbum is niet gevonden!', flash[:error]
  end

  # POST /photo_albums/:photo_album_id/pictures (create)

  test "create flashes an error when no files were selected" do
    post "/photo_albums/#{@photo_album.id}/pictures"
    assert_response :success
    assert_template 'index'
    assert_equal "U heeft geen foto's geselecteerd om toe te voegen.", flash[:error]
  end

  test "create stores the uploaded image and creates resized variants" do
    assert_difference('PhotoAlbumPicture.count', 1) do
      post "/photo_albums/#{@photo_album.id}/pictures", file: [uploaded_jpeg_fixture]
    end

    picture = PhotoAlbumPicture.last
    assert_equal @photo_album.id, picture.photo_album_id
    %w[large medium small].each do |size|
      path = Rails.root.join('public', 'images', size, picture.filename)
      assert File.exist?(path), "expected #{size} variant at #{path}"
      File.delete(path)
    end
    assert_equal I18n.t('flash.photo_albums.pictures_added'), flash[:notice]
  end

  test "create stores multiple uploaded images" do
    assert_difference('PhotoAlbumPicture.count', 3) do
      post("/photo_albums/#{@photo_album.id}/pictures",
           file: [uploaded_jpeg_fixture, uploaded_jpeg_fixture, uploaded_jpeg_fixture])
    end

    PhotoAlbumPicture.last(3).each do |picture|
      %w[large medium small].each do |size|
        path = Rails.root.join('public', 'images', size, picture.filename)
        assert File.exist?(path), "expected #{size} variant at #{path}"
        File.delete(path)
      end
    end
  end

  test "create rolls back all writes when one upload fails" do
    bad_file = uploaded_bad_extension_fixture

    before = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size
    assert_no_difference('PhotoAlbumPicture.count') do
      post "/photo_albums/#{@photo_album.id}/pictures", file: [uploaded_jpeg_fixture, bad_file]
    end
    after = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size

    assert_equal before, after, "no files should be left on disk after partial failure"
    assert_equal I18n.t('flash.photo_albums.some_pictures_failed'), flash[:error]
  end

  # POST /photo_albums/:photo_album_id/pictures/destroy_many

  test "destroy_many deletes the selected pictures" do
    p1 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'one.jpg')
    p2 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'two.jpg')

    assert_difference('PhotoAlbumPicture.count', -1) do
      post "/photo_albums/#{@photo_album.id}/pictures/destroy_many", selected: [p1.id.to_s]
    end

    assert_response :success
    assert_template 'index'
    assert_nil PhotoAlbumPicture.find_by_id(p1.id)
    assert_not_nil PhotoAlbumPicture.find_by_id(p2.id)
  end

  test "destroy_many flashes an error when nothing is selected" do
    post "/photo_albums/#{@photo_album.id}/pictures/destroy_many"
    assert_response :success
    assert_template 'index'
    assert_equal "Geen foto's geselecteerd om te verwijderen.", flash[:error]
  end

  test "destroy_many refuses to delete the last picture of an album" do
    only = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'only.jpg')

    assert_no_difference('PhotoAlbumPicture.count') do
      post "/photo_albums/#{@photo_album.id}/pictures/destroy_many", selected: [only.id.to_s]
    end

    assert_response :success
    assert_template 'index'
    assert_not_nil PhotoAlbumPicture.find_by_id(only.id)
    assert_equal I18n.t('flash.photo_albums.cannot_destroy_last_picture'), flash[:error]
  end

  test "destroy_many refuses when selection would empty the album" do
    p1 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'one.jpg')
    p2 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'two.jpg')

    assert_no_difference('PhotoAlbumPicture.count') do
      post "/photo_albums/#{@photo_album.id}/pictures/destroy_many",
           selected: [p1.id.to_s, p2.id.to_s]
    end

    assert_not_nil PhotoAlbumPicture.find_by_id(p1.id)
    assert_not_nil PhotoAlbumPicture.find_by_id(p2.id)
    assert_equal I18n.t('flash.photo_albums.cannot_destroy_last_picture'), flash[:error]
  end
end
