class Task < ActiveRecord::Base
  module Constants
    TASK_TYPE_IOFILES = "iofiles"
    TASK_TYPE_PYUNIT = "pyunit"

    TASK_TYPES = [TASK_TYPE_IOFILES, TASK_TYPE_PYUNIT]
  end

  include Constants

  has_many :runs, dependent: :destroy
  belongs_to :user

  validates :task_type, inclusion: { in: TASK_TYPES }
end
