class Addisadmintousers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :isadmin, :boolean
  end

  def self.down
    remove_column :users, :isadmin
  end
end
