class PhotoAlbumComment < ActiveRecord::Base
  attr_accessible :message, :photo_album_id, :user_id

  belongs_to :user
  belongs_to :photo_album
  validates_presence_of :message
end
