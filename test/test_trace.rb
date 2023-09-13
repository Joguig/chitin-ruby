require 'minitest/autorun'
require 'rack'
require 'chitin'
require 'test_utils'

class TestTrace <  Minitest::Test
  class BarrelMock
    def send(*args)
      raise "exceptions"
    end
  end


  def test_send_event
    ctx = Chitin::Context.load(Rack::Request.new({}))

    Chitin::Trace.class_variable_set(:@@barrel, BarrelMock.new)
    Chitin::Trace.send(:send_event, ctx) {|event| }
    sleep 6
    Chitin::Trace.send(:send_event, ctx) {|event| }

    assert_match /Exception exceptions occurred 2 times:/, Rails.logger.messages, "Failed to find exception"
  end
end
