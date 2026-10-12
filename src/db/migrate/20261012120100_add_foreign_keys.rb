class AddForeignKeys < ActiveRecord::Migration[8.1]
  # No on_delete: the models delete the children through dependent: :destroy,
  # so a delete that bypasses them fails instead of leaving orphans (or, for
  # pictures, image files) behind.
  FOREIGN_KEYS = [
    %i[news_items users],
    %i[news_comments news_items],
    %i[news_comments users],
    %i[photo_albums users],
    %i[photo_album_pictures photo_albums],
    %i[photo_album_comments photo_albums],
    %i[photo_album_comments users]
  ].freeze

  def change
    FOREIGN_KEYS.each do |from_table, to_table|
      column = "#{to_table.to_s.singularize}_id"
      change_column_null from_table, column, false
      add_index from_table, column
      add_foreign_key from_table, to_table
    end

    reversible { |direction| direction.up { check_foreign_keys } }
  end

  private

  # SQLite doesn't check the existing rows when the table rebuild adds a
  # foreign key, so orphans would survive the migration unnoticed.
  def check_foreign_keys
    violations = select_rows("PRAGMA foreign_key_check")
    return if violations.empty?

    rows = violations.map { |table, rowid, parent| "#{table} id #{rowid} -> #{parent}" }
    raise "Foreign key violations found: #{rows.join(', ')}"
  end
end
