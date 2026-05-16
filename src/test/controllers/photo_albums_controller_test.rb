require 'test_helper'

class PhotoAlbumsControllerTest < ActionDispatch::IntegrationTest
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear

    PhotoAlbumComment.delete_all
    PhotoAlbumPicture.delete_all
    PhotoAlbum.delete_all
    User.delete_all

    # Clean up any image files leaked by prior tests in the suite.
    %w(small medium large).each do |size|
      Dir.glob(Rails.root.join('public', 'images', size, '*')).each do |path|
        next if %w(temp.bmp preview.jpg).include?(File.basename(path))
        File.delete(path)
      end
    end

    @user = create_user!(
      first_name: 'Alice',
      last_name: 'Anderson',
      email: 'alice@example.com',
      password: 'secret',
      notify_news: false,
      notify_photo_album: false,
      isadmin: false
    )
    @subscriber = create_user!(
      first_name: 'Bob',
      last_name: 'Brown',
      email: 'bob@example.com',
      password: 'secret',
      notify_news: false,
      notify_photo_album: true,
      isadmin: false
    )
    @photo_album = PhotoAlbum.create!(
      title: 'Trip',
      description: 'Summer trip',
      user_id: @user.id
    )
    PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'preview.jpg')

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
    get '/photo_albums'
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /photo_albums

  test "index renders paginated photo albums" do
    get '/photo_albums'
    assert_response :success
    assert assigns(:photo_albums).include?(@photo_album)
    assert_equal 1, assigns(:paginator).current_page
  end

  # GET /photo_albums/page/:page_number

  test "page renders index with requested page" do
    get '/photo_albums/page/2'
    assert_response :success
    assert_template 'index'
    assert_equal 2, assigns(:paginator).current_page
  end

  # GET /photo_albums/:id

  test "show renders the album with its comments" do
    PhotoAlbumComment.create!(message: 'Nice', photo_album_id: @photo_album.id, user_id: @user.id)

    get "/photo_albums/#{@photo_album.id}"

    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
    assert_equal 1, assigns(:photo_album_comments).size
  end

  # GET /photo_albums/new

  test "new renders the new album form" do
    get '/photo_albums/new'
    assert_response :success
    assert assigns(:photo_album).new_record?
  end

  # GET /photo_albums/:id/edit

  test "edit renders the edit form" do
    get "/photo_albums/#{@photo_album.id}/edit"
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
  end

  # GET /photo_albums/:id/remove

  test "remove renders the removal confirmation" do
    get "/photo_albums/#{@photo_album.id}/remove"
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
  end

  # POST /photo_albums (create)

  test "create re-renders new with validation errors when no pictures uploaded" do
    assert_no_difference('PhotoAlbum.count') do
      post '/photo_albums', photo_album: { title: 'Title', description: 'Desc' }
    end
    assert_response :success
    assert_template 'new'
    assert assigns(:photo_album).errors[:pictures].present?
  end

  test "create re-renders new with validation errors when title and description blank" do
    before = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size
    assert_no_difference('PhotoAlbum.count') do
      post '/photo_albums', photo_album: { title: '', description: '', pictures: [uploaded_jpeg_fixture] }
    end
    after = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size

    assert_response :success
    assert_template 'new'
    refute assigns(:photo_album).persisted?
    assert_equal before, after, "no files should orphan when validation fails"
  end

  test "create saves the album with multiple pictures" do
    assert_difference('PhotoAlbum.count', 1) do
      assert_difference('PhotoAlbumPicture.count', 2) do
        post '/photo_albums', photo_album: {
          title: 'New album',
          description: 'Holiday photos',
          pictures: [uploaded_jpeg_fixture, uploaded_jpeg_fixture]
        }
      end
    end

    album = PhotoAlbum.last
    assert_redirected_to album
    assert_equal @user.id, album.user_id
    assert_equal 2, album.photo_album_pictures.count

    album.photo_album_pictures.each do |picture|
      %w(large medium small).each do |size|
        path = Rails.root.join('public', 'images', size, picture.filename)
        assert File.exist?(path), "expected #{size} variant at #{path}"
        File.delete(path)
      end
    end
  end

  test "create notifies subscribers" do
    post '/photo_albums', photo_album: {
      title: 'New album',
      description: 'Holiday photos',
      pictures: [uploaded_jpeg_fixture]
    }

    album = PhotoAlbum.last
    assert_redirected_to album
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['bob@example.com'], ActionMailer::Base.deliveries.first.to

    PhotoAlbumPicture.where(photo_album_id: album.id).each do |picture|
      %w(large medium small).each do |size|
        path = Rails.root.join('public', 'images', size, picture.filename)
        File.delete(path) if File.exist?(path)
      end
    end
  end

  test "create does not email the author even when they have notify_photo_album" do
    @user.update_attribute(:notify_photo_album, true)

    post '/photo_albums', photo_album: {
      title: 'New album',
      description: 'Holiday photos',
      pictures: [uploaded_jpeg_fixture]
    }

    album = PhotoAlbum.last
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['bob@example.com'], ActionMailer::Base.deliveries.first.to

    PhotoAlbumPicture.where(photo_album_id: album.id).each do |picture|
      %w(large medium small).each do |size|
        path = Rails.root.join('public', 'images', size, picture.filename)
        File.delete(path) if File.exist?(path)
      end
    end
  end

  test "create sends no email when validation fails" do
    assert_no_difference('PhotoAlbum.count') do
      post '/photo_albums', photo_album: { title: 'Title', description: 'Desc' }
    end

    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  test "create rejects unsupported file types and writes no images" do
    bad_file = uploaded_bad_extension_fixture

    before = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size
    assert_no_difference('PhotoAlbum.count') do
      post '/photo_albums', photo_album: {
        title: 'New album',
        description: 'Holiday photos',
        pictures: [bad_file]
      }
    end
    after = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size

    assert_response :success
    assert_template 'new'
    assert assigns(:photo_album).errors[:pictures].present?
    assert_equal before, after, "no files should be left on disk"
  end

  # PATCH /photo_albums/:id (update)

  test "update saves valid changes" do
    patch "/photo_albums/#{@photo_album.id}",
          photo_album: { title: 'Updated', description: 'New desc' }

    assert_redirected_to @photo_album
    assert_equal I18n.t('flash.photo_albums.updated'), flash[:notice]
    assert_equal 'Updated', @photo_album.reload.title
  end

  test "update re-renders edit on validation failure" do
    patch "/photo_albums/#{@photo_album.id}",
          photo_album: { title: '', description: '' }

    assert_response :success
    assert_template 'edit'
  end

  # DELETE /photo_albums/:id (destroy)

  test "destroy removes album when confirmed" do
    assert_difference('PhotoAlbum.count', -1) do
      delete "/photo_albums/#{@photo_album.id}", commit: 'Ja, verwijderen'
    end
    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Foto album succesvol verwijderd.', flash[:notice]
  end

  test "destroy cascades to the album's pictures" do
    PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'two.jpg')

    assert_difference('PhotoAlbum.count', -1) do
      assert_difference('PhotoAlbumPicture.count', -2) do
        delete "/photo_albums/#{@photo_album.id}", commit: 'Ja, verwijderen'
      end
    end
  end

  test "destroy is a no-op when cancelled" do
    assert_no_difference('PhotoAlbum.count') do
      delete "/photo_albums/#{@photo_album.id}", commit: 'Nee, niet verwijderen'
    end
    assert_redirected_to controller: 'photo_albums', action: 'index'
  end

  test "destroy redirects with error when album does not exist" do
    delete '/photo_albums/999999', commit: 'Ja, verwijderen'
    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Opgegeven fotoalbum is niet gevonden!', flash[:error]
  end
end
