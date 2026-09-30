class AddPreviewPictureToPhotoalbum < ActiveRecord::Migration[4.2]
  def self.up
    add_column :photo_albums, :preview_picture, :string
  end

  def self.down
    remove_column :photo_albums, :preview_picture
  end
end
