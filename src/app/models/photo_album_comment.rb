class PhotoAlbumComment < ApplicationRecord
  belongs_to :user, required: true
  belongs_to :photo_album, required: true
  validates_presence_of :message
end
