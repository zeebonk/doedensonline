class CreatePhotoAlbums < ActiveRecord::Migration[4.2]
  def self.up
    create_table :photo_albums do |t|
      t.string :title
      t.text :description
      t.integer :user_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :photo_albums
  end
end
