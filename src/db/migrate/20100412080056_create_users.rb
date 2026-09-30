class CreateUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :users do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :password
      t.boolean :notify_news

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :users
  end
end
