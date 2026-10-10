class NewsItem < ApplicationRecord
  belongs_to :user
  has_many :news_comments, dependent: :destroy
  validates :message, presence: true

  def preview(size)
    message = Loofah.html5_fragment(self[:message]).scrub!(:prune).to_text(encode_special_chars: false).squish
    if message.size > size
      message = message[0, size]
      message.strip!
      message += "..."
    end
    message
  end
end
