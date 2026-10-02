class ConvertSqliteBooleansToIntegers < ActiveRecord::Migration[5.2]
  COLUMNS = %w[notify_news isadmin notify_photo_album].freeze

  def up
    COLUMNS.each do |column|
      execute "UPDATE users SET #{column} = 1 WHERE #{column} = 't'"
      execute "UPDATE users SET #{column} = 0 WHERE #{column} = 'f'"
    end
  end

  def down
    COLUMNS.each do |column|
      execute "UPDATE users SET #{column} = 't' WHERE #{column} = 1"
      execute "UPDATE users SET #{column} = 'f' WHERE #{column} = 0"
    end
  end
end
