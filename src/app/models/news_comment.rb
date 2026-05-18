class NewsComment < ActiveRecord::Base
  belongs_to :user, required: true
  belongs_to :news_item, required: true
  validates_presence_of :message
end
