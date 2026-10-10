class DropMailers < ActiveRecord::Migration[8.1]
  # Created in 2010 but never used: Mailer is an ActionMailer::Base subclass.
  def change
    drop_table :mailers do |t|
      t.timestamps null: true, precision: nil
    end
  end
end
