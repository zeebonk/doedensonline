require 'test_helper'

class PhotoAlbumTest < ActiveSupport::TestCase
  test "requires a user" do
    photo_album = PhotoAlbum.new(title: 'Title', description: 'Description')
    assert_not photo_album.valid?
    assert_includes photo_album.errors[:user], I18n.t('errors.messages.required')
  end

  test "destroy deletes the comments and pictures" do
    photo_album = photo_albums(:one)
    photo_album.photo_album_comments.create!(message: 'Hi', user: users(:two))
    photo_album.photo_album_pictures.create!(filename: 'test.jpg')

    photo_album.destroy!

    assert_equal 0, PhotoAlbumComment.count
    assert_equal 0, PhotoAlbumPicture.count
  end

  test "delete fails while the album has pictures" do
    photo_albums(:one).photo_album_pictures.create!(filename: 'test.jpg')
    assert_raises(ActiveRecord::InvalidForeignKey) { photo_albums(:one).delete }
  end
end
