class User < ApplicationRecord
  has_many :news_items, dependent: :destroy
  has_many :news_comments, dependent: :destroy
  has_many :photo_albums, dependent: :destroy
  has_many :photo_album_comments, dependent: :destroy

  validates :password, length: { minimum: 4 }
  validates :first_name, length: { minimum: 3 }
  validates :last_name, length: { minimum: 3 }
  validates :email, format: { with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i }

  # Password setter
  def password=(pwd)
    # Make sure password isn't blank
    self[:password] = if pwd.blank?
                        nil
                      else
                        User.encrypted_password(pwd)
                      end
  end

  # Method to authenticate a user
  def self.authenticate(first_name, password)
    # Search for a user with given username, case insensetive
    users = where("lower(first_name) = ?", first_name.downcase)

    # Check if given password and user password are not the same
    for user in users do
      return user if user.password == encrypted_password(password)
    end

    nil
  end

  def generate_new_password
    # Generate a random new password (from: http://snippets.dzone.com/posts/show/491, by: sprsquish, at: 24/11/2008, original by: ?)
    new_password = Array.new(6) { rand(256) }.pack('C*').unpack1('H*')
    # Set the news password for the user
    update_attribute(:password, new_password)
    # Send the user his new password trough email
    Mailer.password_forgotten(self, new_password).deliver_now
  end

  private

  # Method to create an hash for a password and salt combination
  def self.encrypted_password(password)
    # Create string to hash
    string_to_hash = "doe#{password}dens"
    # Create and return SHA1 hash for string
    Digest::SHA1.hexdigest(string_to_hash)
  end
end
