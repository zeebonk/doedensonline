require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "destroy deletes the user's content and the comments and pictures on it" do
    NewsComment.create!(message: 'Hi', news_item: news_items(:one), user: users(:two))
    PhotoAlbumComment.create!(message: 'Hi', photo_album: photo_albums(:one), user: users(:two))
    photo_albums(:one).photo_album_pictures.create!(filename: 'test.jpg')

    users(:one).destroy!

    assert_equal 0, NewsItem.count
    assert_equal 0, NewsComment.count
    assert_equal 0, PhotoAlbum.count
    assert_equal 0, PhotoAlbumComment.count
    assert_equal 0, PhotoAlbumPicture.count
  end

  test "destroy deletes the user's comments on other users' content" do
    news_comment = NewsComment.create!(message: 'Hi', news_item: news_items(:one), user: users(:two))
    photo_album_comment = PhotoAlbumComment.create!(message: 'Hi', photo_album: photo_albums(:one), user: users(:two))

    users(:two).destroy!

    assert_not NewsComment.exists?(news_comment.id)
    assert_not PhotoAlbumComment.exists?(photo_album_comment.id)
    assert NewsItem.exists?(news_items(:one).id)
    assert PhotoAlbum.exists?(photo_albums(:one).id)
  end

  test "delete fails while the user has content" do
    assert_raises(ActiveRecord::InvalidForeignKey) { users(:one).delete }
  end
end
