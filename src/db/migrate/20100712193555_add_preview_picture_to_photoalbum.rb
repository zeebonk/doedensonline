class AddPreviewPictureToPhotoalbum < ActiveRecord::Migration
  def self.up
    add_column :photo_albums, :preview_picture, :string
  end

  def self.down
    remove_column :photo_albums, :preview_picture
  end
end
