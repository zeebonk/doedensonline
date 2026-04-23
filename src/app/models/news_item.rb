class NewsItem < ActiveRecord::Base
  attr_accessible :message, :user_id

  belongs_to :user
  has_many :news_comments
  validates_presence_of :message

  def self.latest(limit, offset)
    order('created_at DESC').limit(limit).offset(offset)
  end

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
