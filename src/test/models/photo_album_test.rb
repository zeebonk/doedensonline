require 'test_helper'

class PhotoAlbumTest < ActiveSupport::TestCase
  test "requires a user" do
    photo_album = PhotoAlbum.new(title: 'Title', description: 'Description')
    refute photo_album.valid?
    assert photo_album.errors.added?(:user, :required)
  end
end
