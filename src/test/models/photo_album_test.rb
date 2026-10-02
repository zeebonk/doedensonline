require 'test_helper'

class PhotoAlbumTest < ActiveSupport::TestCase
  test "requires a user" do
    photo_album = PhotoAlbum.new(title: 'Title', description: 'Description')
    refute photo_album.valid?
    assert_includes photo_album.errors[:user], I18n.t('errors.messages.required')
  end
end
