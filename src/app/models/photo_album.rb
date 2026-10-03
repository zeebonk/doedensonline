class PhotoAlbum < ApplicationRecord
  validates :title, :description, presence: true
  belongs_to :user
  has_many :photo_album_pictures, -> { order(:position, :id) }, dependent: :destroy, inverse_of: :photo_album
  has_many :photo_album_comments, dependent: :destroy
end
