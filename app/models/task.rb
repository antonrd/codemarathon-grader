class Task < ActiveRecord::Base
  attr_accessible :description, :name, :user_id

  has_many :runs
  belongs_to :user
end
