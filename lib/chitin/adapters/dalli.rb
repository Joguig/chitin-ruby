if defined?(Dalli)
  module Dalli
    class Server
      def request_with_trace(op, *args)
        return request_without_trace(op, *args) unless Chitin::Config.track_outbound_memcache

        ctx = Chitin::Context.span!
        peer = hostname + ":" + port.to_s
        command = op == :send_multiget ? "GET" : op.to_s.upcase
        keys = op == :send_multiget ? args[0].length : 1

        Chitin::Trace.memcache_start(ctx, :peer => peer, :command => command, :keys => keys)

        # Dalli will raise errors even for expected situations, such as cache misses
        # This captures the error and stores it for later so that we can still fire a trace event
        begin
          e = nil
          r = request_without_trace(op, *args)
        rescue => e
          r = nil
        end

        # multiget has a vastly different code flow than other calls. Instead of returning immediately,
        # the client instead polls for data until it's all been read (or a timeout occurs).
        # So we store our context in an instance variable, and handle firing the closing event in the
        # method the client calls to fetch the stored data.
        if op == :send_multiget
          @multi_gets ||= []
          multi_gets.push({:context => ctx, :keys => 0})
        else
          Chitin::Trace.memcache_finish(ctx, :keys => r ? 1 : 0)
        end

        # Return the result of the underlying call, which may be an error
        raise e if e
        r
      end
      alias_method_chain :request, :trace

      def multi_response_nonblock_with_trace
        return multi_response_nonblock_without_trace unless Chitin::Config.track_outbound_memcache

        begin
          e = nil
          r = multi_response_nonblock_without_trace
        rescue => e
          r = {}
        end

        # Track how many cache hits we've found.
        multi_gets[0][:keys] += r.length

        # We have no other methods to hook into, so we must detect when 
        # we've read all data and fire the event here.
        if multi_response_completed?
          m = multi_gets.shift
          ctx = m[:context]
          keys = m[:keys]
          Chitin::Trace.memcache_finish(ctx, :keys => keys)
        end

        # Return the result of the underlying call, which may be an error
        raise e if e
        r
      end
      alias_method_chain :multi_response_nonblock, :trace
    end
  end
end
