class NewsComment < ApplicationRecord
  belongs_to :user
  belongs_to :news_item
  validates :message, presence: true
end
