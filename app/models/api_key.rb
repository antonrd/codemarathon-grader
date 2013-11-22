class ApiKey < ActiveRecord::Base
  attr_accessible :access_token, :user_id

  belongs_to :user

  before_create :generate_access_token

private
  
  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
    end while self.class.exists?(access_token: access_token)
  end
end
