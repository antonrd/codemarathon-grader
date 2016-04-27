class DiffOutputs
  def initialize filename1, filename2
    @filename1 = filename1
    @filename2 = filename2
  end

  def call
    line_counter = 0

    File.readlines(filename1).zip(File.readlines(filename2)).each do |line1, line2|
      line_counter += 1
      stripped_line1 = line1.nil? ? line1 : line1.strip
      stripped_line2 = line2.nil? ? line2 : line2.strip

      if stripped_line1 != stripped_line2
        unless stripped_line1.blank? && stripped_line2.blank?
          puts "Difference at line #{ line_counter }:"
          puts "=== #{ filename1 }"
          puts "> #{ line1 }"
          puts "=== #{ filename2 }"
          puts "< #{ line2 }"
          return false
        end
      end
    end

    true
  end

  private

  attr_reader :filename1, :filename2
end
