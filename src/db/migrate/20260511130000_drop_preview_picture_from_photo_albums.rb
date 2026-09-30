class DropPreviewPictureFromPhotoAlbums < ActiveRecord::Migration[4.2]
  def self.up
    add_column :photo_album_pictures, :position, :integer

    now = connection.quote(Time.now.utc.strftime('%Y-%m-%d %H:%M:%S'))

    albums = connection.select_rows('SELECT id, preview_picture FROM photo_albums')

    albums.each do |album_id, preview_filename|
      album_id = album_id.to_i
      preview_picture_id = preview_picture_id_for(album_id, preview_filename, now)
      assign_positions(album_id, preview_picture_id)
    end

    remove_column :photo_albums, :preview_picture
  end

  def self.down
    add_column :photo_albums, :preview_picture, :string
    remove_column :photo_album_pictures, :position
  end

  def self.preview_picture_id_for(album_id, preview_filename, now)
    return nil if preview_filename.blank?

    existing = connection.select_value(<<-SQL.squish)
      SELECT id FROM photo_album_pictures
      WHERE photo_album_id = #{album_id}
        AND filename = #{connection.quote(preview_filename)}
      ORDER BY id ASC
      LIMIT 1
    SQL

    return existing.to_i if existing

    connection.insert(<<-SQL.squish)
      INSERT INTO photo_album_pictures (photo_album_id, filename, created_at, updated_at)
      VALUES (#{album_id}, #{connection.quote(preview_filename)}, #{now}, #{now})
    SQL
  end

  def self.assign_positions(album_id, preview_picture_id)
    picture_ids = connection.select_values(<<-SQL.squish).map(&:to_i)
      SELECT id FROM photo_album_pictures
      WHERE photo_album_id = #{album_id}
      ORDER BY id ASC
    SQL

    next_position = 1
    picture_ids.each do |picture_id|
      if picture_id == preview_picture_id
        execute "UPDATE photo_album_pictures SET position = 0 WHERE id = #{picture_id}"
      else
        execute "UPDATE photo_album_pictures SET position = #{next_position} WHERE id = #{picture_id}"
        next_position += 1
      end
    end
  end
end
