class PhotoAlbumComment < ActiveRecord::Base
  belongs_to :user
  belongs_to :photo_album
  validates_presence_of :message
end
