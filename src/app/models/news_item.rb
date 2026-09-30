class NewsItem < ApplicationRecord
  belongs_to :user, required: true
  has_many :news_comments, dependent: :destroy
  validates_presence_of :message

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
