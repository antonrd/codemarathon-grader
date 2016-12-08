class DiffOutputs
  def initialize filename1, filename2
    @filename1 = filename1
    @filename2 = filename2
  end

  def call
    line_counter = 0

    File.readlines(filename1).zip(File.readlines(filename2)).each do |line1, line2|
      line_counter += 1
      stripped_line1 = line1.nil? ? '' : line1.strip
      stripped_line2 = line2.nil? ? '' : line2.strip

      if stripped_line1 != stripped_line2
        unless stripped_line1.blank? && stripped_line2.blank?
          puts "Difference at line #{ line_counter }:"
          puts "=== #{ filename1 }"
          puts "> #{ stripped_line1[0..100] }"
          puts "=== #{ filename2 }"
          puts "< #{ stripped_line2[0..100] }"
          return false
        end
      end
    end

    true
  end

  private

  attr_reader :filename1, :filename2
end
