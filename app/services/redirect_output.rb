class RedirectOutput
  def initialize(filename)
    @filename = filename
  end

  def call
    old_stdout, old_stderr = $stdout.dup, $stderr.dup

    File.open(filename, "w") do |f|
      f.sync = true
      STDOUT.reopen(f)
      STDERR.reopen(f)

      yield
    end

  ensure
    STDOUT.reopen(old_stdout)
    STDERR.reopen(old_stderr)
  end

  protected

  attr_reader :filename
end
