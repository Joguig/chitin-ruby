if defined?(Memcached)
  class Memcached
    {
      :set => "SET",
      :add => "ADD",
      :increment => "INCR",
      :decrement => "DECR",
      :replace => "REPLACE",
      :append => "APPEND",
      :prepend => "PREPEND",
      :cas => "CAS",
      :delete => "DELETE",
      :flush => "UNKNOWN_COMMAND",
      :get => "GET",
      :exist => "UNKNOWN_COMMAND",
      :get_from_last => "GET",
      :stats => "UNKNOWN_COMMAND"
    }.each do | func_name, command |
      # Add new functions based on the mapping above
      # define_method creates the new method
      # method loads the old method
      # alias_method_chain moves the old function to it's new name, and aliases the new one
      define_method(func_name.to_s + "_with_trace") do | *args, &blk |
        func = method(func_name.to_s + "_without_trace")

        return func.call(*args, &blk) unless Chitin::Config.track_outbound_memcache

        # Look up which server each key is sharded to and create a context for each server
        # This allows us to create a Trace event for each underlying server request despite
        # not having access to the low level code that handles creating connections
        servers = {}
        inspect_keys(args[0]).each do | key, server |
          servers[server] ||= {:context => Chitin::Context.span!, :keys => [], :found => 0}
          servers[server][:keys].push(key)
        end

        # Actually fire the trace event
        servers.each do | server, data |
          hostport = server.split(":")[0..1].join(":") # TODO: IPv6?
          Chitin::Trace.memcache_start(data[:context], :peer => hostport, :command => command, :keys => data[:keys].length)
        end

        # Memcached will raise errors even for expected situations, such as cache misses
        # This captures the error and stores it for later so that we can still fire a trace event
        begin
          e = nil
          r = func.call(*args, &blk)
        rescue => e
          r = nil
        end

        # Create a hash of keys => values so we can determine how many cache hits we had
        if r.is_a?(Hash)
          values = r
        else
          values = r ? {args[0] => r} : {}
        end

        # For each server determine how many cache hits we had, then fire a trace event
        servers.each do | server, data |
          found = 0
          data[:keys].each { |k| found += 1 if values[k] }
          Chitin::Trace.memcache_finish(data[:context], :keys => found)
        end

        # Return the result of the underlying call, which may be an error
        raise e if e
        r
      end
      alias_method_chain func_name, :trace
    end
  end
end
