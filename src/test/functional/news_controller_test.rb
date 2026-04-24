require 'test_helper'

class NewsControllerTest < ActionController::TestCase
  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries.clear

    # Start clean: fixture users store raw passwords and news_items fixtures
    # reference user_id: 1, which would orphan after we rebuild users.
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
    @subscriber = create_user!(
      first_name: 'Bob',
      last_name: 'Brown',
      email: 'bob@example.com',
      password: 'secret',
      notify_news: true,
      isadmin: false
    )
    @news_item = NewsItem.create!(message: 'Existing news', user_id: @user.id)

    sign_in_as @user
  end

  def sign_in_as(user)
    @request.session[:user_id] = user.id
  end

  # Authorization

  test "redirects to sign_in when not signed in" do
    @request.session[:user_id] = nil
    get :index
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /news

  test "index renders paginated news" do
    get :index
    assert_response :success
    assert_not_nil assigns(:news_items)
    assert assigns(:news_items).include?(@news_item)
    assert_equal 1, assigns(:page)
  end

  # GET /news/page/:page_number

  test "page renders index with requested page" do
    get :page, page_number: '2'
    assert_response :success
    assert_template 'index'
    assert_equal 2, assigns(:page)
  end

  # GET /news/add

  test "add renders new news_item form" do
    get :add
    assert_response :success
    assert_not_nil assigns(:news_item)
    assert assigns(:news_item).new_record?
  end

  # POST /news/create

  test "create saves news_item and notifies subscribers" do
    assert_difference('NewsItem.count', 1) do
      post :create, news_item: { message: 'Hello world' }
    end

    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Nieuwtje succesvol toegevoegd.', flash[:notice]
    assert_equal @user.id, assigns(:news_item).user_id
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['bob@example.com'], ActionMailer::Base.deliveries.first.to
  end

  test "create does not email the author even when they have notify_news" do
    @user.update_attribute(:notify_news, true)

    post :create, news_item: { message: 'Hello again' }

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['bob@example.com'], ActionMailer::Base.deliveries.first.to
  end

  test "create re-renders add on validation failure" do
    assert_no_difference('NewsItem.count') do
      post :create, news_item: { message: '' }
    end

    assert_response :success
    assert_template 'add'
    assert_equal 'Let op: een nieuwtje moet wel tekst bevatten!', flash[:error]
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  # GET /news/edit/:id

  test "edit renders form for author" do
    get :edit, id: @news_item.id
    assert_response :success
    assert_equal @news_item, assigns(:news_item)
  end

  test "edit redirects when news_item does not exist" do
    get :edit, id: 999_999
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # PUT /news/update

  test "update saves valid changes" do
    put :update, news_item: { id: @news_item.id, message: 'Updated message' }

    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Het nieuwtje is succesvol aangepast.', flash[:notice]
    assert_equal 'Updated message', @news_item.reload.message
  end

  test "update re-renders edit on validation failure" do
    put :update, news_item: { id: @news_item.id, message: '' }

    assert_response :success
    assert_template 'edit'
    assert_equal 'Let op: een nieuwtje moet wel tekst bevatten!', flash[:error]
  end

  test "update redirects when news_item does not exist" do
    put :update, news_item: { id: 999_999, message: 'anything' }

    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # GET /news/remove/:id

  test "remove renders confirmation for author" do
    get :remove, id: @news_item.id
    assert_response :success
    assert_equal @news_item, assigns(:news_item)
  end

  test "remove redirects when news_item does not exist" do
    get :remove, id: 999_999
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # POST /news/destroy

  test "destroy deletes news_item and its comments" do
    NewsComment.create!(message: 'comment', news_item_id: @news_item.id, user_id: @user.id)

    assert_difference('NewsItem.count', -1) do
      assert_difference('NewsComment.count', -1) do
        post :destroy, id: @news_item.id, commit: 'Ja, verwijderen'
      end
    end

    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Nieuwtje succesvol verwijderd.', flash[:notice]
  end

  test "destroy is a no-op when cancelled" do
    assert_no_difference('NewsItem.count') do
      post :destroy, id: @news_item.id, commit: 'Nee, niet verwijderen'
    end

    assert_redirected_to controller: 'news', action: 'index'
  end

  test "destroy redirects when news_item does not exist" do
    post :destroy, id: 999_999, commit: 'Ja, verwijderen'
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # GET /news/view/:id

  test "view renders news_item with its comments" do
    NewsComment.create!(message: 'A comment', news_item_id: @news_item.id, user_id: @user.id)

    get :view, id: @news_item.id

    assert_response :success
    assert_equal @news_item, assigns(:news_item)
    assert_equal 1, assigns(:news_comments).size
  end

  test "view redirects when news_item does not exist" do
    get :view, id: 999_999
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # GET /news/add_comment/:id

  test "add_comment renders new comment form" do
    get :add_comment, id: @news_item.id
    assert_response :success
    assert_not_nil assigns(:news_comment)
    assert_equal @news_item.id.to_s, assigns(:news_comment).news_item_id.to_s
  end

  # POST /news/create_comment

  test "create_comment saves valid comment" do
    assert_difference('NewsComment.count', 1) do
      post :create_comment, news_comment: { message: 'Nice', news_item_id: @news_item.id }
    end

    assert_redirected_to controller: 'news', action: 'view', id: @news_item.id
    assert_equal 'Reactie is succesvol toegevoegd.', flash[:notice]
    assert_equal @user.id, assigns(:news_comment).user_id
  end

  test "create_comment re-renders on validation failure" do
    assert_no_difference('NewsComment.count') do
      post :create_comment, news_comment: { message: '', news_item_id: @news_item.id }
    end

    assert_response :success
    assert_template 'add_comment'
    assert_equal 'Een reactie moet wel tekst bevatten!', flash[:error]
  end

  # GET /news/edit_comment/:id

  test "edit_comment renders form for author" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    get :edit_comment, id: comment.id

    assert_response :success
    assert_equal comment, assigns(:news_comment)
  end

  test "edit_comment redirects when comment does not exist" do
    get :edit_comment, id: 999_999
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # PUT /news/update_comment

  test "update_comment saves valid changes" do
    comment = NewsComment.create!(message: 'old', news_item_id: @news_item.id, user_id: @user.id)

    put :update_comment, news_comment: { id: comment.id, message: 'new' }

    assert_redirected_to controller: 'news', action: 'view', id: @news_item.id
    assert_equal 'Uw reactie is succesvol aangepast.', flash[:notice]
    assert_equal 'new', comment.reload.message
  end

  test "update_comment re-renders on validation failure" do
    comment = NewsComment.create!(message: 'old', news_item_id: @news_item.id, user_id: @user.id)

    put :update_comment, news_comment: { id: comment.id, message: '' }

    assert_response :success
    assert_template 'edit_comment'
    assert_equal 'Een reactie moet wel tekst bevatten!', flash[:error]
  end

  test "update_comment redirects when comment does not exist" do
    put :update_comment, news_comment: { id: 999_999, message: 'x' }
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # GET /news/remove_comment/:id

  test "remove_comment renders confirmation for author" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    get :remove_comment, id: comment.id

    assert_response :success
    assert_equal comment, assigns(:news_comment)
  end

  test "remove_comment redirects when comment does not exist" do
    get :remove_comment, id: 999_999
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end

  # POST /news/destroy_comment

  test "destroy_comment deletes the comment" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    assert_difference('NewsComment.count', -1) do
      post :destroy_comment, id: comment.id, commit: 'Ja, verwijderen'
    end

    assert_redirected_to controller: 'news', action: 'view', id: @news_item.id
    assert_equal 'Uw reactie is succesvol verwijderd.', flash[:notice]
  end

  test "destroy_comment is a no-op when cancelled" do
    comment = NewsComment.create!(message: 'c', news_item_id: @news_item.id, user_id: @user.id)

    assert_no_difference('NewsComment.count') do
      post :destroy_comment, id: comment.id, commit: 'Nee, niet verwijderen'
    end

    assert_redirected_to controller: 'news', action: 'view', id: @news_item.id
  end

  test "destroy_comment redirects when comment does not exist" do
    post :destroy_comment, id: 999_999, commit: 'Ja, verwijderen'
    assert_redirected_to controller: 'news', action: 'index'
    assert_equal 'Opgegeven reactie is niet gevonden!', flash[:error]
  end
end
