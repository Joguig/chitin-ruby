class TestLogger < Logger
  def initialize
    @strio = StringIO.new
    super(@strio)
  end

  def messages
    @strio.string
  end
end

class Rails
  def self.logger
    @logger ||= TestLogger.new
  end
end
