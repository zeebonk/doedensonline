class PhotoAlbumPicture < ActiveRecord::Base
  attr_accessible :filename, :photo_album_id

  validates_presence_of :filename, :photo_album_id
  belongs_to :photo_album
end
