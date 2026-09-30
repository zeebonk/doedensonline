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
    get "/photo_albums/#{@photo_album.id}/comments/new", params: {}
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /photo_albums/:photo_album_id/comments/new

  test "new renders new comment form for existing album" do
    get "/photo_albums/#{@photo_album.id}/comments/new", params: {}
    assert_response :success
    assert_not_nil assigns(:photo_album_comment)
    assert_equal @photo_album.id.to_s, assigns(:photo_album_comment).photo_album_id.to_s
  end

  test "new redirects when photo album does not exist" do
    get '/photo_albums/999999/comments/new', params: {}
    assert_redirected_to '/photo_albums'
    assert_equal 'Fotoalbum om reactie bij te plaatsen bestaat niet.', flash[:error]
  end

  # GET /photo_albums/:photo_album_id/comments/:id/edit

  test "edit renders for author" do
    get "/photo_albums/#{@photo_album.id}/comments/#{@comment.id}/edit", params: {}
    assert_response :success
    assert_equal @comment, assigns(:photo_album_comment)
  end

  test "edit redirects when comment does not exist" do
    get "/photo_albums/#{@photo_album.id}/comments/999999/edit", params: {}
    assert_redirected_to '/photo_albums'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # POST /photo_albums/:photo_album_id/comments (create)

  test "create saves valid comment and redirects to the album" do
    assert_difference('PhotoAlbumComment.count', 1) do
      post "/photo_albums/#{@photo_album.id}/comments", params: {
        photo_album_comment: { message: 'Great!' }
      }
    end

    assert_redirected_to photo_album_path(@photo_album)
    assert_equal 'Reactie is succesvol toegevoegd.', flash[:notice]
    assert_equal @user.id, assigns(:photo_album_comment).user_id
    assert_equal @photo_album.id, assigns(:photo_album_comment).photo_album_id
  end

  test "create re-renders new on validation failure" do
    assert_no_difference('PhotoAlbumComment.count') do
      post "/photo_albums/#{@photo_album.id}/comments", params: {
        photo_album_comment: { message: '' }
      }
    end

    assert_response :success
    assert_template 'new'
    assert_not_empty assigns(:photo_album_comment).errors[:message]
  end

  test "create strips leading ../ from message via root_src_img_tag" do
    post "/photo_albums/#{@photo_album.id}/comments", params: {
      photo_album_comment: { message: '../images/x.jpg' }
    }
    assert_equal '/images/x.jpg', assigns(:photo_album_comment).message
  end

  # PATCH /photo_albums/:photo_album_id/comments/:id (update)

  test "update saves valid changes" do
    patch "/photo_albums/#{@photo_album.id}/comments/#{@comment.id}", params: {
      photo_album_comment: { message: 'Updated' }
    }

    assert_redirected_to photo_album_path(@photo_album)
    assert_equal 'Uw reactie is succesvol aangepast.', flash[:notice]
    assert_equal 'Updated', @comment.reload.message
  end

  test "update re-renders edit on validation failure" do
    patch "/photo_albums/#{@photo_album.id}/comments/#{@comment.id}", params: {
      photo_album_comment: { message: '' }
    }

    assert_response :success
    assert_template 'edit'
    assert_not_empty assigns(:photo_album_comment).errors[:message]
  end

  test "update redirects when comment does not exist" do
    patch "/photo_albums/#{@photo_album.id}/comments/999999", params: {
      photo_album_comment: { message: 'x' }
    }

    assert_redirected_to '/photo_albums'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # GET /photo_albums/:photo_album_id/comments/:id/remove

  test "remove renders confirmation for author" do
    get "/photo_albums/#{@photo_album.id}/comments/#{@comment.id}/remove", params: {}
    assert_response :success
    assert_equal @comment, assigns(:photo_album_comment)
  end

  test "remove redirects when comment does not exist" do
    get "/photo_albums/#{@photo_album.id}/comments/999999/remove", params: {}
    assert_redirected_to '/photo_albums'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # DELETE /photo_albums/:photo_album_id/comments/:id (destroy)

  test "destroy deletes comment when confirmed" do
    assert_difference('PhotoAlbumComment.count', -1) do
      delete "/photo_albums/#{@photo_album.id}/comments/#{@comment.id}", params: { commit: 'Ja, verwijderen' }
    end

    assert_redirected_to photo_album_path(@photo_album)
    assert_equal 'Uw reactie is succesvol verwijderd.', flash[:notice]
  end

  test "destroy is a no-op when cancelled" do
    assert_no_difference('PhotoAlbumComment.count') do
      delete "/photo_albums/#{@photo_album.id}/comments/#{@comment.id}", params: { commit: 'Nee, niet verwijderen' }
    end

    assert_redirected_to photo_album_path(@photo_album)
  end

  test "destroy redirects when comment does not exist" do
    delete "/photo_albums/#{@photo_album.id}/comments/999999", params: { commit: 'Ja, verwijderen' }

    assert_redirected_to '/photo_albums'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end
end
