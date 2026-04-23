class PhotoAlbum < ActiveRecord::Base
  attr_accessible :title, :description, :preview_picture, :user_id

  validates_presence_of :title, :description, :preview_picture
  belongs_to :user
  has_many :photo_album_pictures
  has_many :photo_album_comments

  def self.latest(limit, offset)
    order('created_at DESC').limit(limit).offset(offset)
  end
end
