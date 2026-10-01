require 'test_helper'

class PhotoAlbumCommentTest < ActiveSupport::TestCase
  test "requires a user" do
    comment = PhotoAlbumComment.new(message: 'Hi', photo_album: photo_albums(:one))
    refute comment.valid?
    assert comment.errors.added?(:user, :required)
  end

  test "requires a photo album" do
    comment = PhotoAlbumComment.new(message: 'Hi', user: users(:one))
    refute comment.valid?
    assert comment.errors.added?(:photo_album, :required)
  end
end
