class CreateNewsComments < ActiveRecord::Migration
  def self.up
    create_table :news_comments do |t|
      t.text :message
      t.integer :news_item_id
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :news_comments
  end
end
