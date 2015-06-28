# Provides methods for reading and storing any grader logs in database.
module GraderLogging
  LOG_FILE = 'grader.log'

  def update_run(status, message, log_filename=LOG_FILE)
    run.update_attributes(status: status,
                          message: message,
                          log: File.read(log_filename))
  end
end
