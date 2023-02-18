class User < ActiveRecord::Base

  validates_length_of :password, :minimum => 4
  validates_length_of :first_name, :minimum => 3
  validates_length_of :last_name, :minimum => 3
  validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i, :message => 'is ongeldig.'

  # Password setter
  def password=pwd
    # Make sure password isn't blank
    if pwd.blank?
      self[:password] = nil
    else
      self[:password] = User.encrypted_password(pwd)
    end
  end
  
  # Method to authenticate a user
  def self.authenticate(first_name, password)
  
    # Search for a user with given username, case insensetive
    users = self.find( :all, :conditions => [ "lower(first_name) = ?", first_name.downcase ])

    # Check if given password and user password are not the same
    for user in users do
      if user.password == encrypted_password(password)    
        return user
      end
    end
    
    return nil
    
  end
  
  def generate_new_password
    # Generate a random new password (from: http://snippets.dzone.com/posts/show/491, by: sprsquish, at: 24/11/2008, original by: ?)
    new_password = Array.new(6) { rand(256) }.pack('C*').unpack('H*').first
    # Set the news password for the user
    update_attribute(:password, new_password)
    # Send the user his new password trough email
     Mailer.deliver_password_forgotten(self, new_password)
  end
 
private 
  
  # Method to create an hash for a password and salt combination
  def self.encrypted_password(password)
    # Create string to hash
    string_to_hash = "doe" + password + "dens"
    # Create and return SHA1 hash for string
    Digest::SHA1.hexdigest(string_to_hash)
  end

end
