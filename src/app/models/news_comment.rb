class NewsComment < ActiveRecord::Base
  attr_accessible :message, :news_item_id, :user_id

  belongs_to :user
  belongs_to :news_item
  validates_presence_of :message
end
