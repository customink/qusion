class Rails
  module VERSION
    MAJOR = 3
  end

  def self.env
    # ActiveSupport::StringInquirer.new("test")
    "test"
  end

  def self.root
    "/path/to/rails"
  end
end
