class DeleteOrphanedRecords < ActiveRecord::Migration[8.1]
  # Rows whose parent is gone, or whose column is NULL, would fail the foreign
  # keys and NOT NULL constraints of AddForeignKeys. In production that's news
  # comments from 2010 and 2018 and pictures of albums deleted between 2010 and
  # 2022, none of which the app can reach. The pictures' image files stay on
  # disk: the migrate container doesn't mount the image directories.
  #
  # Parents come first, so that deleting a news item or album also gets its
  # comments and pictures deleted.
  RELATIONS = [
    %i[news_items users],
    %i[photo_albums users],
    %i[news_comments news_items],
    %i[news_comments users],
    %i[photo_album_pictures photo_albums],
    %i[photo_album_comments photo_albums],
    %i[photo_album_comments users]
  ].freeze

  def up
    RELATIONS.each do |from_table, to_table|
      column = "#{to_table.to_s.singularize}_id"
      deleted = exec_delete(<<~SQL.squish)
        DELETE FROM #{from_table}
        WHERE #{column} IS NULL OR #{column} NOT IN (SELECT id FROM #{to_table})
      SQL
      say "Deleted #{deleted} #{from_table} rows with a missing or NULL #{column}"
    end
  end

  def down
    # The deleted rows can't be restored, and the schema didn't change.
  end
end
