class PhotoAlbumPicture < ApplicationRecord
  validates :filename, presence: true
  belongs_to :photo_album, required: true

  before_create :assign_position
  after_destroy :remove_image_files

  private

  def assign_position
    return if position

    max = PhotoAlbumPicture.where(photo_album_id: photo_album_id).maximum(:position) || 0
    self.position = max + 1
  end

  def remove_image_files
    %w[small medium large].each do |size|
      path = Rails.root.join('public', 'images', size, filename).to_s
      FileUtils.remove_file(path, true)
    end
  end
end
