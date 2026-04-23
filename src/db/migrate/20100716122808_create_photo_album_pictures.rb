class CreatePhotoAlbumPictures < ActiveRecord::Migration
  def self.up
    create_table :photo_album_pictures do |t|
      t.integer :photo_album_id
      t.string :filename

      t.timestamps
    end
  end

  def self.down
    drop_table :photo_album_pictures
  end
end
