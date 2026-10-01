class NewsComment < ApplicationRecord
  belongs_to :user
  belongs_to :news_item
  validates_presence_of :message
end
