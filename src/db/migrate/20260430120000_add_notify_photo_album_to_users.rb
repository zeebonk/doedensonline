class AddNotifyPhotoAlbumToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :notify_photo_album, :boolean
    execute "UPDATE users SET notify_photo_album = notify_news"
  end

  def self.down
    remove_column :users, :notify_photo_album
  end
end
