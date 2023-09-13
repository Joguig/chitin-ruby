require 'uri'

if defined?(Ethon)
  module Ethon
    class Easy
      module Http
        attr_reader :verb
        def http_request_with_save_verb(url, verb, opts = {})
          @verb = verb.to_s.upcase
          http_request_without_save_verb(url, verb, opts)
        end
        alias_method_chain :http_request, :save_verb
      end

      module Header
        def headers_with_save_headers=(headers)
          @raw_headers = headers
          self.headers_without_save_headers = headers
        end
        alias_method_chain :headers=, :save_headers
      end

      module Operations
        def perform_with_trace
          return perform_without_trace unless Chitin::Config.track_outbound_http
          u = URI(self.url)
          return perform_without_trace unless ["http","https"].include?(u.scheme) && u.host.present?
          ctx = Chitin::Context.span!
          self.headers = Chitin::Trace.augment_headers(ctx, @raw_headers, u)
          Chitin::Trace.request_head_prepared(ctx, :method => verb, :peer => u.host + ":" + u.port.to_s, :path => u.path)
          r = perform_without_trace
          Chitin::Trace.response_body_received(ctx, :status_code => response_code)
          r
        end
        alias_method_chain :perform, :trace
      end
    end
  end
end
