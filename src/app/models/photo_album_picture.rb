class PhotoAlbumPicture < ActiveRecord::Base
  validates_presence_of :filename , :photo_album_id
  belongs_to :photo_album
end
