class PhotoAlbum < ApplicationRecord
  validates :title, :description, presence: true
  belongs_to :user, required: true
  has_many :photo_album_pictures, -> { order(:position, :id) }, dependent: :destroy
  has_many :photo_album_comments, dependent: :destroy
end
