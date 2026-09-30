class CreateMailers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :mailers do |t|

      t.timestamps null: true
    end
  end

  def self.down
    drop_table :mailers
  end
end
