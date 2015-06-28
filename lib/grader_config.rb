class GraderConfig
  def initialize(filename)
    @filename = filename
    @values = nil
  end

  def load
    grader_conf = YAML.load_file(Rails.root.join(filename))
    puts "Reading configuration for env #{Rails.env}"
    if !grader_conf[Rails.env]
      puts "Cannot find configuration for #{Rails.env}. Check your #{filename}"
      return false
    end

    @values = grader_conf[Rails.env].with_indifferent_access
    true
  end

  def value(key)
    raise KeyError, "Key #{key} not found in config file. Check the #{Rails.env} section of #{filename}." if !values.has_key?(key)
    values[key]
  end

  def supported_language?(lang)
    values[:languages].split(';').select{ |lang| lang.strip.length > 0 }.include?(lang)
  end

  def compiled_language?(lang)
    values[:compiled_languages].split(';').select{ |lang| lang.strip.length > 0 }.include?(lang)
  end

  def has_key?(key)
    values.has_key?(key)
  end

  protected

  attr_reader :filename, :values
end
