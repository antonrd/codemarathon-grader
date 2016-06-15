class Run < ActiveRecord::Base
  module Constants
    CODE_NEW_TASK = "new_task"
    CODE_UPDATE_TASK = "update_task"
    CODE_RUN_TASK = "run_task"
    CODE_UPDATE_CHECKER = "update_checker"

    STATUS_STARTING = "starting"
    STATUS_PENDING = "pending"
    STATUS_RUNNING = "running"
    STATUS_CE = "compilation error"
    STATUS_ERROR = "unknown error"
    STATUS_GRADER_ERROR = "grader error"
    STATUS_SUCCESS = "finished"

    TEST_OUTCOME_TIME_LIMIT = 'tl'
    TEST_OUTCOME_MEMORY_LIMIT = 'ml'
    TEST_OUTCOME_RUNTIME_ERROR = 're'
    TEST_OUTCOME_WRONG_ANSWER = 'wa'
    TEST_OUTCOME_OK = 'ok'
    TEST_OUTCOME_GRADER_ERROR = 'ge'

    RUN_TEST_BLOCK_REGEX = /====== BEGIN RUN TEST ======(.*?)====== END RUN TEST ======/m
    EXECUTION_BLOCK_REGEX = /====== BEGIN EXECUTION ======(.*?)====== END EXECUTION ======/m
    STATS_BLOCK_REGEX = /====== BEGIN STATS ======(.*?)====== END STATS ======/m
    STATUS_BLOCK_REGEX = /====== BEGIN STATUS ======(.*?)====== END STATUS ======/m
    COMPILATION_BLOCK_REGEX = /====== BEGIN COMPILATION ======(.*?)====== END COMPILATION ======/m
  end

  include Constants

  validates :task_id, presence: true

  scope :latest_first, -> { order('created_at desc') }
  scope :earliest_first, -> { order('created_at asc') }
  scope :pending, -> { where(status: [STATUS_PENDING, STATUS_RUNNING, STATUS_STARTING]) }

  before_create do
    self.status = STATUS_PENDING if self.status.blank?
    self.message = "Pending" if self.message.blank?
  end

  belongs_to :user
  belongs_to :task

  def is_updating_run?
    self.code == CODE_UPDATE_TASK
  end

  def is_grading_run?
    self.code == CODE_RUN_TASK
  end

  def description
    @description ||= compute_description
  end

  private

  def compute_description
    result = {
      status: 0,
      message: "Run #{ id } details",
      run_status: status,
      run_message: message,
      compilation: compilation_log,
      run_log: log,
      test_cases: test_cases_description
    }
  end

  def compilation_log
    if log.present?
      match = log.match(COMPILATION_BLOCK_REGEX)
      return unless match
      match[1].strip
    end
  end

  def test_cases_description
    if log.present?
      log.scan(RUN_TEST_BLOCK_REGEX).map { |t| test_case_description(t.first) }
    end
  end

  def test_case_description test_case_log
    {
      status: test_case_status(test_case_log),
      execution: test_case_execution(test_case_log),
    }.merge(used_resources_description(test_case_log.match(
      STATS_BLOCK_REGEX)[1].strip))
  end

  def test_case_status test_case_log
    match = test_case_log.match(STATUS_BLOCK_REGEX)
    return unless match
    match[1].strip
  end

  def test_case_execution test_case_log
    match = test_case_log.match(EXECUTION_BLOCK_REGEX)
    return unless match
    match[1].strip
  end

  def used_resources_description(stats_log)
    {
      used_time: stats_log.match(/Used time: ([0-9\.]+)/)[1].strip.to_f,
      used_memory: stats_log.match(/Used mem: ([0-9]+)/)[1].strip.to_i
    }
  end
end
