class PhotoAlbumComment < ApplicationRecord
  belongs_to :user
  belongs_to :photo_album
  validates :message, presence: true
end
