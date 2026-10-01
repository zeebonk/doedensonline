require 'test_helper'

class PhotoAlbumPictureTest < ActiveSupport::TestCase
  test "requires a photo album" do
    picture = PhotoAlbumPicture.new(filename: 'picture.jpg')
    refute picture.valid?
    assert picture.errors.added?(:photo_album, :required)
  end
end
