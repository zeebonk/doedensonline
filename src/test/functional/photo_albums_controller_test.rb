require 'test_helper'

class PhotoAlbumsControllerTest < ActionController::TestCase
  def setup
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
      isadmin: false
    )
    @photo_album = PhotoAlbum.create!(
      title: 'Trip',
      description: 'Summer trip',
      preview_picture: 'preview.jpg',
      user_id: @user.id
    )

    sign_in_as @user
  end

  def sign_in_as(user)
    @request.session[:user_id] = user.id
  end

  def uploaded_jpeg_fixture
    fixture_file_upload('files/sample.jpg', 'image/jpeg', :binary)
  end

  def uploaded_bad_extension_fixture
    upload = fixture_file_upload('files/sample.jpg', 'application/octet-stream', :binary)
    upload.instance_variable_set(:@original_filename, 'evil.exe')
    upload
  end

  # Authorization

  test "redirects to sign_in when not signed in" do
    @request.session[:user_id] = nil
    get :index
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /photo_albums

  test "index renders paginated photo albums" do
    get :index
    assert_response :success
    assert assigns(:photo_albums).include?(@photo_album)
    assert_equal 1, assigns(:paginator).current_page
  end

  # GET /photo_albums/page/:page_number

  test "page renders index with requested page" do
    get :page, page_number: '2'
    assert_response :success
    assert_template 'index'
    assert_equal 2, assigns(:paginator).current_page
  end

  # GET /photo_albums/:id

  test "show renders the album with its comments" do
    PhotoAlbumComment.create!(message: 'Nice', photo_album_id: @photo_album.id, user_id: @user.id)

    get :show, id: @photo_album.id

    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
    assert_equal 1, assigns(:photo_album_comments).size
  end

  # GET /photo_albums/new

  test "new renders the new album form" do
    get :new
    assert_response :success
    assert assigns(:photo_album).new_record?
  end

  # GET /photo_albums/:id/edit

  test "edit renders the edit form" do
    get :edit, id: @photo_album.id
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
  end

  # GET /photo_albums/:id/remove

  test "remove renders the removal confirmation" do
    get :remove, id: @photo_album.id
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
  end

  # GET /photo_albums/:id/manage_pictures

  test "manage_pictures renders for the album" do
    get :manage_pictures, id: @photo_album.id
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
  end

  # POST /photo_albums (create)

  test "create re-renders new with validation errors when no pictures uploaded" do
    assert_no_difference('PhotoAlbum.count') do
      post :create, photo_album: { title: 'Title', description: 'Desc' }
    end
    assert_response :success
    assert_template 'new'
    assert assigns(:photo_album).errors[:pictures].present?
  end

  test "create re-renders new with validation errors when title and description blank" do
    before = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size
    assert_no_difference('PhotoAlbum.count') do
      post :create, photo_album: { title: '', description: '', pictures: [uploaded_jpeg_fixture] }
    end
    after = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size

    assert_response :success
    assert_template 'new'
    refute assigns(:photo_album).persisted?
    assert_equal before, after, "no files should orphan when validation fails"
  end

  test "create saves the album with multiple pictures and uses first as preview" do
    assert_difference('PhotoAlbum.count', 1) do
      assert_difference('PhotoAlbumPicture.count', 2) do
        post :create, photo_album: {
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

    pictures = album.photo_album_pictures.order(:id).to_a
    assert_equal pictures.first.filename, album.preview_picture

    pictures.each do |picture|
      %w(large medium small).each do |size|
        path = Rails.root.join('public', 'images', size, picture.filename)
        assert File.exist?(path), "expected #{size} variant at #{path}"
        File.delete(path)
      end
    end
  end

  test "create rejects unsupported file types and writes no images" do
    bad_file = uploaded_bad_extension_fixture

    before = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size
    assert_no_difference('PhotoAlbum.count') do
      post :create, photo_album: {
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

  # PUT /photo_albums/:id (update)

  test "update saves valid changes when no preview picture is uploaded" do
    post :update,
         id: @photo_album.id,
         photo_album: { title: 'Updated', description: 'New desc' }

    assert_redirected_to @photo_album
    assert_equal I18n.t('flash.photo_albums.updated'), flash[:notice]
    assert_equal 'Updated', @photo_album.reload.title
  end

  test "update re-renders edit on validation failure" do
    post :update,
         id: @photo_album.id,
         photo_album: { title: '', description: '' }

    assert_response :success
    assert_template 'edit'
  end

  # DELETE /photo_albums/:id (destroy)

  test "destroy removes album when confirmed" do
    assert_difference('PhotoAlbum.count', -1) do
      post :destroy, id: @photo_album.id, commit: 'Ja, verwijderen'
    end
    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Foto album succesvol verwijderd.', flash[:notice]
  end

  test "destroy is a no-op when cancelled" do
    assert_no_difference('PhotoAlbum.count') do
      post :destroy, id: @photo_album.id, commit: 'Nee, niet verwijderen'
    end
    assert_redirected_to controller: 'photo_albums', action: 'index'
  end

  test "destroy redirects with error when album does not exist" do
    post :destroy, id: 999_999, commit: 'Ja, verwijderen'
    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Opgegeven fotoalbum is niet gevonden!', flash[:error]
  end

  # POST /photo_albums/add_picture

  test "add_picture flashes an error when no files were selected" do
    post :add_picture, album_id: @photo_album.id
    assert_response :success
    assert_template 'manage_pictures'
    assert_equal "U heeft geen foto's geselecteerd om toe te voegen.", flash[:error]
  end

  test "add_picture stores the uploaded image and creates resized variants" do
    assert_difference('PhotoAlbumPicture.count', 1) do
      post :add_picture, album_id: @photo_album.id, file: [uploaded_jpeg_fixture]
    end

    picture = PhotoAlbumPicture.last
    assert_equal @photo_album.id, picture.photo_album_id
    %w(large medium small).each do |size|
      path = Rails.root.join('public', 'images', size, picture.filename)
      assert File.exist?(path), "expected #{size} variant at #{path}"
      File.delete(path)
    end
    assert_equal I18n.t('flash.photo_albums.pictures_added'), flash[:notice]
  end

  test "add_picture stores multiple uploaded images" do
    assert_difference('PhotoAlbumPicture.count', 3) do
      post(:add_picture,
           album_id: @photo_album.id,
           file: [uploaded_jpeg_fixture, uploaded_jpeg_fixture, uploaded_jpeg_fixture])
    end

    PhotoAlbumPicture.last(3).each do |picture|
      %w(large medium small).each do |size|
        path = Rails.root.join('public', 'images', size, picture.filename)
        assert File.exist?(path), "expected #{size} variant at #{path}"
        File.delete(path)
      end
    end
  end

  test "add_picture rolls back all writes when one upload fails" do
    bad_file = uploaded_bad_extension_fixture

    before = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size
    assert_no_difference('PhotoAlbumPicture.count') do
      post :add_picture, album_id: @photo_album.id, file: [uploaded_jpeg_fixture, bad_file]
    end
    after = Dir.glob(Rails.root.join('public', 'images', 'large', '*')).size

    assert_equal before, after, "no files should be left on disk after partial failure"
    assert_equal I18n.t('flash.photo_albums.some_pictures_failed'), flash[:error]
  end

  # POST /photo_albums/destroy_many_pictures

  test "destroy_many_pictures deletes selected pictures" do
    p1 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'one.jpg')
    p2 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'two.jpg')

    assert_difference('PhotoAlbumPicture.count', -1) do
      post :destroy_many_pictures, album_id: @photo_album.id, selected: [p1.id.to_s]
    end

    assert_response :success
    assert_template 'manage_pictures'
    assert_nil PhotoAlbumPicture.find_by_id(p1.id)
    assert_not_nil PhotoAlbumPicture.find_by_id(p2.id)
  end

  test "destroy_many_pictures flashes an error when nothing is selected" do
    post :destroy_many_pictures, album_id: @photo_album.id
    assert_response :success
    assert_template 'manage_pictures'
    assert_equal "Geen foto's geselecteerd om te verwijderen.", flash[:error]
  end
end
