require 'test_helper'

class PhotoAlbumCommentTest < ActiveSupport::TestCase
  test "requires a user" do
    comment = PhotoAlbumComment.new(message: 'Hi', photo_album: photo_albums(:one))
    assert_not comment.valid?
    assert_includes comment.errors[:user], I18n.t('errors.messages.required')
  end

  test "requires a photo album" do
    comment = PhotoAlbumComment.new(message: 'Hi', user: users(:one))
    assert_not comment.valid?
    assert_includes comment.errors[:photo_album], I18n.t('errors.messages.required')
  end
end
