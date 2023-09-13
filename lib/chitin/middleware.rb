module Chitin
  class Middleware
    def initialize(application)
      @application = application
    end

    def call(environment)
      return @application.call(environment) unless Chitin::Config.track_inbound_http

      request = Rack::Request.new(environment)
      ctx = Context.load(request)
      Trace.request_body_received(ctx, request)

      response = response(request)
      Trace.response_head_prepared(ctx, response)
      response.finish
    end

    def response(request)
      status, headers, body = @application.call(request.env)
      Rack::Response.new(body, status, headers)
    end
  end
end
