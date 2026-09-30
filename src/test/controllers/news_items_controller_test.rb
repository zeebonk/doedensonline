require 'test_helper'

class NewsItemsControllerTest < ActionDispatch::IntegrationTest
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

  # Authorization

  test "redirects to sign_in when not signed in" do
    reset!
    get '/news', params: {}
    assert_redirected_to controller: 'home', action: 'sign_in'
  end

  # GET /news

  test "index renders paginated news" do
    get '/news', params: {}
    assert_response :success
    assert_not_nil assigns(:news_items)
    assert assigns(:news_items).include?(@news_item)
    assert_equal 1, assigns(:news_items).current_page
  end

  test "index honors the page query parameter" do
    get '/news', params: { page: 2 }
    assert_response :success
    assert_template 'index'
    assert_equal 2, assigns(:news_items).current_page
  end

  # GET /news/new

  test "new renders new news_item form" do
    get '/news/new', params: {}
    assert_response :success
    assert_not_nil assigns(:news_item)
    assert assigns(:news_item).new_record?
  end

  # POST /news

  test "create saves news_item and notifies subscribers" do
    assert_difference('NewsItem.count', 1) do
      post '/news', params: { news_item: { message: 'Hello world' } }
    end

    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Nieuwtje succesvol toegevoegd.', flash[:notice]
    assert_equal @user.id, assigns(:news_item).user_id
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['bob@example.com'], ActionMailer::Base.deliveries.first.to
  end

  test "create does not email the author even when they have notify_news" do
    @user.update_attribute(:notify_news, true)

    post '/news', params: { news_item: { message: 'Hello again' } }

    assert_equal 1, ActionMailer::Base.deliveries.size
    assert_equal ['bob@example.com'], ActionMailer::Base.deliveries.first.to
  end

  test "create re-renders new on validation failure" do
    assert_no_difference('NewsItem.count') do
      post '/news', params: { news_item: { message: '' } }
    end

    assert_response :success
    assert_template 'new'
    assert_includes assigns(:news_item).errors[:message], 'Een nieuwtje moet tekst bevatten'
    assert_equal 0, ActionMailer::Base.deliveries.size
  end

  # GET /news/:id

  test "show renders news_item with its comments" do
    NewsComment.create!(message: 'A comment', news_item_id: @news_item.id, user_id: @user.id)

    get "/news/#{@news_item.id}", params: {}

    assert_response :success
    assert_equal @news_item, assigns(:news_item)
    assert_equal 1, assigns(:news_comments).size
  end

  test "show redirects when news_item does not exist" do
    get '/news/999999', params: {}
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # GET /news/:id/edit

  test "edit renders form for author" do
    get "/news/#{@news_item.id}/edit", params: {}
    assert_response :success
    assert_equal @news_item, assigns(:news_item)
  end

  test "edit redirects when news_item does not exist" do
    get '/news/999999/edit', params: {}
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # PATCH /news/:id

  test "update saves valid changes" do
    patch "/news/#{@news_item.id}", params: { news_item: { message: 'Updated message' } }

    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Het nieuwtje is succesvol aangepast.', flash[:notice]
    assert_equal 'Updated message', @news_item.reload.message
  end

  test "update re-renders edit on validation failure" do
    patch "/news/#{@news_item.id}", params: { news_item: { message: '' } }

    assert_response :success
    assert_template 'edit'
    assert_includes assigns(:news_item).errors[:message], 'Een nieuwtje moet tekst bevatten'
  end

  test "update redirects when news_item does not exist" do
    patch '/news/999999', params: { news_item: { message: 'anything' } }

    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # GET /news/:id/remove

  test "remove renders confirmation for author" do
    get "/news/#{@news_item.id}/remove", params: {}
    assert_response :success
    assert_equal @news_item, assigns(:news_item)
  end

  test "remove redirects when news_item does not exist" do
    get '/news/999999/remove', params: {}
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end

  # DELETE /news/:id

  test "destroy deletes news_item and its comments" do
    NewsComment.create!(message: 'comment', news_item_id: @news_item.id, user_id: @user.id)

    assert_difference('NewsItem.count', -1) do
      assert_difference('NewsComment.count', -1) do
        delete "/news/#{@news_item.id}", params: { commit: 'Ja, verwijderen' }
      end
    end

    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Nieuwtje succesvol verwijderd.', flash[:notice]
  end

  test "destroy is a no-op when cancelled" do
    assert_no_difference('NewsItem.count') do
      delete "/news/#{@news_item.id}", params: { commit: 'Nee, niet verwijderen' }
    end

    assert_redirected_to controller: 'news_items', action: 'index'
  end

  test "destroy redirects when news_item does not exist" do
    delete '/news/999999', params: { commit: 'Ja, verwijderen' }
    assert_redirected_to controller: 'news_items', action: 'index'
    assert_equal 'Opgegeven nieuwtje is niet gevonden!', flash[:error]
  end
end
