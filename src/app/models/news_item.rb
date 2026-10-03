class NewsItem < ApplicationRecord
  belongs_to :user
  has_many :news_comments, dependent: :destroy
  validates :message, presence: true

  def preview(size)
    message = self[:message]
    message = message.gsub(/<\/?[^>]*>/, "")
    message.strip!
    if message.size > size
      message = message[0, size]
      message.strip!
      message += "..."
    end
    message
  end
end
