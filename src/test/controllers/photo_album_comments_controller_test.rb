require 'test_helper'

class PhotoAlbumCommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
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
      isadmin: false
    )
    @photo_album = PhotoAlbum.create!(
      title: 'Trip',
      description: 'Summer trip',
      preview_picture: 'preview.jpg',
      user_id: @user.id
    )
    @comment = PhotoAlbumComment.create!(
      message: 'Nice',
      photo_album_id: @photo_album.id,
      user_id: @user.id
    )

    sign_in_as @user
  end

  # Authorization

  test "redirects to sign_in when not signed in" do
    reset!
    get '/photo_album_comments/new', id: @photo_album.id
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /photo_album_comments/new

  test "new renders new comment form for existing album" do
    get '/photo_album_comments/new', id: @photo_album.id
    assert_response :success
    assert_not_nil assigns(:photo_album_comment)
    assert_equal @photo_album.id.to_s, assigns(:photo_album_comment).photo_album_id.to_s
  end

  test "new redirects when photo album does not exist" do
    get '/photo_album_comments/new', id: 999_999
    assert_redirected_to controller: 'photo_albums'
    assert_equal 'Fotoalbum om reactie bij te plaatsen bestaat niet.', flash[:error]
  end

  # GET /photo_album_comments/:id/edit

  test "edit renders for author" do
    get "/photo_album_comments/#{@comment.id}/edit"
    assert_response :success
    assert_equal @comment, assigns(:photo_album_comment)
  end

  test "edit redirects when comment does not exist" do
    get '/photo_album_comments/999999/edit'
    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # POST /photo_album_comments (create)

  test "create saves valid comment and redirects to the album" do
    assert_difference('PhotoAlbumComment.count', 1) do
      post '/photo_album_comments',
           photo_album_comment: { message: 'Great!', photo_album_id: @photo_album.id }
    end

    assert_redirected_to controller: 'photo_albums', action: 'show', id: @photo_album.id
    assert_equal 'Reactie is succesvol toegevoegd.', flash[:notice]
    assert_equal @user.id, assigns(:photo_album_comment).user_id
  end

  test "create re-renders new on validation failure" do
    assert_no_difference('PhotoAlbumComment.count') do
      post '/photo_album_comments',
           photo_album_comment: { message: '', photo_album_id: @photo_album.id }
    end

    assert_response :success
    assert_template 'new'
    assert_not_empty assigns(:photo_album_comment).errors[:message]
  end

  test "create strips leading ../ from message via root_src_img_tag" do
    post '/photo_album_comments',
         photo_album_comment: { message: '../images/x.jpg', photo_album_id: @photo_album.id }
    assert_equal '/images/x.jpg', assigns(:photo_album_comment).message
  end

  # PATCH /photo_album_comments/:id (update)

  test "update saves valid changes" do
    patch "/photo_album_comments/#{@comment.id}",
          photo_album_comment: { message: 'Updated' }

    assert_redirected_to controller: 'photo_albums', action: 'show', id: @photo_album.id
    assert_equal 'Uw reactie is succesvol aangepast.', flash[:notice]
    assert_equal 'Updated', @comment.reload.message
  end

  test "update re-renders edit on validation failure" do
    patch "/photo_album_comments/#{@comment.id}",
          photo_album_comment: { message: '' }

    assert_response :success
    assert_template 'edit'
    assert_not_empty assigns(:photo_album_comment).errors[:message]
  end

  test "update redirects when comment does not exist" do
    patch '/photo_album_comments/999999',
          photo_album_comment: { message: 'x' }

    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # GET /photo_album_comments/:id/remove

  test "remove renders confirmation for author" do
    get "/photo_album_comments/#{@comment.id}/remove"
    assert_response :success
    assert_equal @comment, assigns(:photo_album_comment)
  end

  test "remove redirects when comment does not exist" do
    get '/photo_album_comments/999999/remove'
    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # DELETE /photo_album_comments/:id (destroy)

  test "destroy deletes comment when confirmed" do
    assert_difference('PhotoAlbumComment.count', -1) do
      delete "/photo_album_comments/#{@comment.id}", commit: 'Ja, verwijderen'
    end

    assert_redirected_to controller: 'photo_albums', action: 'show', id: @photo_album.id
    assert_equal 'Uw reactie is succesvol verwijderd.', flash[:notice]
  end

  test "destroy is a no-op when cancelled" do
    assert_no_difference('PhotoAlbumComment.count') do
      delete "/photo_album_comments/#{@comment.id}", commit: 'Nee, niet verwijderen'
    end

    assert_redirected_to controller: 'photo_albums', action: 'show', id: @photo_album.id
  end

  test "destroy redirects when comment does not exist" do
    delete '/photo_album_comments/999999', commit: 'Ja, verwijderen'

    assert_redirected_to controller: 'photo_albums', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end
end
