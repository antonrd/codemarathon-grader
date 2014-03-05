class Task < ActiveRecord::Base
  module Constants
    TASK_TYPE_IOFILES = "iofiles"
    TASK_TYPE_PYUNIT = "pyunit"
  end

  attr_accessible :description, :name, :user_id, :task_type, :wrapper_code

  has_many :runs
  belongs_to :user

  include Constants
end
