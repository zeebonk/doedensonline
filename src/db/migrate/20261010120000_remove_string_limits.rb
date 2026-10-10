class RemoveStringLimits < ActiveRecord::Migration[8.1]
  # The 2010 migrations created these as varchar(255), which current Rails no
  # longer does for t.string. Drop the limits so the database matches what the
  # migrations produce today, and store photo album comments as text like news
  # comments.
  STRING_COLUMNS = {
    users: %i[first_name last_name email password],
    photo_albums: %i[title],
    photo_album_pictures: %i[filename]
  }.freeze

  def up
    STRING_COLUMNS.each do |table, columns|
      columns.each { |column| change_column table, column, :string }
    end
    change_column :photo_album_comments, :message, :text
  end

  def down
    change_column :photo_album_comments, :message, :string, limit: 255
    STRING_COLUMNS.each do |table, columns|
      columns.each { |column| change_column table, column, :string, limit: 255 }
    end
  end
end
