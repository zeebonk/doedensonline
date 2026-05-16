class PhotoAlbum < ActiveRecord::Base
  validates :title, :description, presence: true
  belongs_to :user
  has_many :photo_album_pictures, -> { order(:position, :id) }, dependent: :destroy
  has_many :photo_album_comments

  def self.latest(limit, offset)
    order('created_at DESC').limit(limit).offset(offset)
  end
end
