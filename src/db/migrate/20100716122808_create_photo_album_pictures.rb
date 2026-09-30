class CreatePhotoAlbumPictures < ActiveRecord::Migration[4.2]
  def self.up
    create_table :photo_album_pictures do |t|
      t.integer :photo_album_id
      t.string :filename

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :photo_album_pictures
  end
end
