class NewsItem < ActiveRecord::Base

  belongs_to :user
  has_many :news_comments
  validates_presence_of :message, :message=> 'Een nieuwtje moet tekst bevatten'
  
  def self.latest(limit, offset)
    NewsItem.all  :order => 'created_at DESC', :limit => limit, :offset => offset
  end
  
  def preview(size)
    message = self[:message]
    message = message.gsub(/<\/?[^>]*>/, "")
    message.strip!
    if message.size > size
      message = message[0,size]
      message.strip!
      message = message + "..."
    end
    return message
  end
  
end
