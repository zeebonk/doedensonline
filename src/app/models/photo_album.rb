class PhotoAlbum < ActiveRecord::Base
  validates :title, :description, presence: true
  belongs_to :user
  has_many :photo_album_pictures, -> { order(:position, :id) }, dependent: :destroy
  has_many :photo_album_comments, dependent: :destroy
end
