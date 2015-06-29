class Task < ActiveRecord::Base
  module Constants
    TASK_TYPE_IOFILES = "iofiles"
    TASK_TYPE_PYUNIT = "pyunit"
  end

  has_many :runs, dependent: :destroy
  belongs_to :user

  include Constants
end
