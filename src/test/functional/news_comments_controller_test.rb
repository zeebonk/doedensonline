require 'test_helper'

class NewsCommentsControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:news_comments)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create news_comment" do
    assert_difference('NewsComment.count') do
      post :create, :news_comment => { }
    end

    assert_redirected_to news_comment_path(assigns(:news_comment))
  end

  test "should show news_comment" do
    get :show, :id => news_comments(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => news_comments(:one).id
    assert_response :success
  end

  test "should update news_comment" do
    put :update, :id => news_comments(:one).id, :news_comment => { }
    assert_redirected_to news_comment_path(assigns(:news_comment))
  end

  test "should destroy news_comment" do
    assert_difference('NewsComment.count', -1) do
      delete :destroy, :id => news_comments(:one).id
    end

    assert_redirected_to news_comments_path
  end
end
