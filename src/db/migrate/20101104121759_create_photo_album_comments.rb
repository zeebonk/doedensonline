class CreatePhotoAlbumComments < ActiveRecord::Migration
  def self.up
    create_table :photo_album_comments do |t|
      t.string :message
      t.integer :photo_album_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :photo_album_comments
  end
end
