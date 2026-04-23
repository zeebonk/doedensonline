require 'test_helper'

class PhotoAlbumPicturesControllerTest < ActionController::TestCase
  def setup
    PhotoAlbumPicture.delete_all
    PhotoAlbum.delete_all
    User.delete_all

    @user = User.create!(
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

  # Authorization

  test "redirects to sign_in when not signed in" do
    @request.session[:user_id] = nil
    get :show, id: @photo_album.id
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /photo_album_pictures/:id

  test "show renders the album with a new picture placeholder" do
    get :show, id: @photo_album.id
    assert_response :success
    assert_equal @photo_album, assigns(:photo_album)
    assert assigns(:photo_album_picture).new_record?
    assert_equal @photo_album.id, assigns(:photo_album_picture).photo_album_id
  end

  # POST /photo_album_pictures (create)

  test "create re-renders show when filename is missing" do
    assert_no_difference('PhotoAlbumPicture.count') do
      post :create, photo_album_picture: { filename: nil, photo_album_id: @photo_album.id }
    end

    assert_response :success
    assert_template 'show'
    assert !assigns(:photo_album_picture).errors.empty?
  end

  # POST /photo_album_pictures/destroy_many

  test "destroy_many deletes the selected pictures and redirects to show" do
    p1 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'one.jpg')
    p2 = PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'two.jpg')

    assert_difference('PhotoAlbumPicture.count', -1) do
      post :destroy_many, album: @photo_album.id, delete: [p1.id.to_s]
    end

    assert_redirected_to controller: 'photo_album_pictures', action: 'show', id: @photo_album.id
    assert_nil PhotoAlbumPicture.find_by_id(p1.id)
    assert_not_nil PhotoAlbumPicture.find_by_id(p2.id)
  end

  test "destroy_many is a no-op when nothing is selected" do
    PhotoAlbumPicture.create!(photo_album_id: @photo_album.id, filename: 'only.jpg')

    assert_no_difference('PhotoAlbumPicture.count') do
      post :destroy_many, album: @photo_album.id
    end

    assert_redirected_to controller: 'photo_album_pictures', action: 'show', id: @photo_album.id
  end
end
