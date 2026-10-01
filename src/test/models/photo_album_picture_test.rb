require 'test_helper'

class PhotoAlbumPictureTest < ActiveSupport::TestCase
  test "requires a photo album" do
    picture = PhotoAlbumPicture.new(filename: 'picture.jpg')
    refute picture.valid?
    assert_includes picture.errors[:photo_album], I18n.t('errors.messages.required')
  end
end
