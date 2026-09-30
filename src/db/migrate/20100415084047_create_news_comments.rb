class CreateNewsComments < ActiveRecord::Migration[4.2]
  def self.up
    create_table :news_comments do |t|
      t.text :message
      t.integer :news_item_id
      t.integer :user_id

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :news_comments
  end
end
