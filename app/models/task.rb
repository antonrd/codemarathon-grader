class Task < ActiveRecord::Base
  module Constants
    TASK_TYPE_IOFILES = "iofiles"
    TASK_TYPE_UNIT = "unit"

    TASK_TYPES = [TASK_TYPE_IOFILES, TASK_TYPE_UNIT]
  end

  include Constants

  has_many :runs, dependent: :destroy
  belongs_to :user

  validates :task_type, inclusion: { in: TASK_TYPES }
  validates :checker_lang, presence: true,
    unless: Proc.new { |task| task.checker.blank? }
end
