class PhotoAlbumComment < ApplicationRecord
  belongs_to :user
  belongs_to :photo_album
  validates_presence_of :message
end
