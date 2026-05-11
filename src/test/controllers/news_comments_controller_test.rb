require 'test_helper'

class NewsCommentsControllerTest < ActionDispatch::IntegrationTest
  def setup
    NewsComment.delete_all
    NewsItem.delete_all
    User.delete_all

    @user = create_user!(
      first_name: 'Alice',
      last_name: 'Anderson',
      email: 'alice@example.com',
      password: 'secret',
      notify_news: false,
      isadmin: false
    )
    @news_item = NewsItem.create!(message: 'Existing news', user_id: @user.id)

    sign_in_as @user
  end

  # Authorization

  test "redirects to sign_in when not signed in" do
    reset!
    get "/news/#{@news_item.id}/comments/new"
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /news/:news_item_id/comments/new

  test "new renders new comment form" do
    get "/news/#{@news_item.id}/comments/new"
    assert_response :success
    assert_not_nil assigns(:news_comment)
    assert_equal @news_item.id.to_s, assigns(:news_comment).news_item_id.to_s
  end

  # POST /news/:news_item_id/comments

  test "create saves valid comment" do
    assert_difference('NewsComment.count', 1) do
      post "/news/#{@news_item.id}/comments", news_comment: { message: 'Nice' }
    end

    assert_redirected_to controller: 'news_items', action: 'show', id: @news_item.id
    assert_equal 'Reactie is succesvol toegevoegd.', flash[:notice]
    assert_equal @user.id, assigns(:news_comment).user_id
  end

  test "create re-renders on validation failure" do
    assert_no_difference('NewsComment.count') do
      post "/news/#{@news_item.id}/comments", news_comment: { message: '' }
    end

    assert_response :success
    assert_template 'new'
    assert_not_empty assigns(:news_comment).errors[:message]
  end

  # GET /news/:news_item_id/comments/:id/edit

  test "edit renders form for author" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    get "/news/#{@news_item.id}/comments/#{comment.id}/edit"

    assert_response :success
    assert_equal comment, assigns(:news_comment)
  end

  test "edit redirects when comment does not exist" do
    get "/news/#{@news_item.id}/comments/999999/edit"
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # PATCH /news/:news_item_id/comments/:id

  test "update saves valid changes" do
    comment = NewsComment.create!(message: 'old', news_item_id: @news_item.id, user_id: @user.id)

    patch "/news/#{@news_item.id}/comments/#{comment.id}", news_comment: { message: 'new' }

    assert_redirected_to controller: 'news_items', action: 'show', id: @news_item.id
    assert_equal 'Uw reactie is succesvol aangepast.', flash[:notice]
    assert_equal 'new', comment.reload.message
  end

  test "update re-renders on validation failure" do
    comment = NewsComment.create!(message: 'old', news_item_id: @news_item.id, user_id: @user.id)

    patch "/news/#{@news_item.id}/comments/#{comment.id}", news_comment: { message: '' }

    assert_response :success
    assert_template 'edit'
    assert_not_empty assigns(:news_comment).errors[:message]
  end

  test "update redirects when comment does not exist" do
    patch "/news/#{@news_item.id}/comments/999999", news_comment: { message: 'x' }
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # GET /news/:news_item_id/comments/:id/remove

  test "remove renders confirmation for author" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    get "/news/#{@news_item.id}/comments/#{comment.id}/remove"

    assert_response :success
    assert_equal comment, assigns(:news_comment)
  end

  test "remove redirects when comment does not exist" do
    get "/news/#{@news_item.id}/comments/999999/remove"
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # DELETE /news/:news_item_id/comments/:id

  test "destroy deletes the comment" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    assert_difference('NewsComment.count', -1) do
      delete "/news/#{@news_item.id}/comments/#{comment.id}", commit: 'Ja, verwijderen'
    end

    assert_redirected_to controller: 'news_items', action: 'show', id: @news_item.id
    assert_equal 'Uw reactie is succesvol verwijderd.', flash[:notice]
  end

  test "destroy is a no-op when cancelled" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    assert_no_difference('NewsComment.count') do
      delete "/news/#{@news_item.id}/comments/#{comment.id}", commit: 'Nee, niet verwijderen'
    end

    assert_redirected_to controller: 'news_items', action: 'show', id: @news_item.id
  end

  test "destroy redirects when comment does not exist" do
    delete "/news/#{@news_item.id}/comments/999999", commit: 'Ja, verwijderen'
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end
end
