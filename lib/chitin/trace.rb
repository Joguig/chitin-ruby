require "active_support/multibyte"

module Chitin
  class Trace
    include ::Code::Justin::Tv::Release::Trace::Pbmsg

    # HTTP
    def self.request_body_received(ctx, request)
      send_event(ctx) do |event|
        event.kind = Event::Kind::REQUEST_BODY_RECEIVED
        event.extra.peer = request.env.fetch("REMOTE_ADDR", '') + ":0" # TODO: Get actual port, ensure IPv6 works
        event.extra.http = ExtraHTTP.new
        event.extra.http.method = ExtraHTTP::Method.enum_for_name(request.request_method)
        event.extra.http.uri_path = request.path
      end
    end

    def self.response_head_prepared(ctx, response)
      send_event(ctx) do |event|
        event.kind = Event::Kind::RESPONSE_HEAD_PREPARED
        event.extra.http = ExtraHTTP.new
        event.extra.http.status_code = response.status
      end
    end

    def self.request_head_prepared(ctx, options = {})
      send_event(ctx) do |event|
        event.kind = Event::Kind::REQUEST_HEAD_PREPARED
        event.extra.peer = options[:peer] || "0.0.0.0:0"
        event.extra.http = ExtraHTTP.new
        event.extra.http.method = ExtraHTTP::Method.enum_for_name(options[:method] || "UNKNOWN")
        event.extra.http.uri_path = options[:path] || ""
      end
    end

    def self.response_body_received(ctx, options = {})
      send_event(ctx) do |event|
        event.kind = Event::Kind::RESPONSE_BODY_RECEIVED
        event.extra.http = ExtraHTTP.new
        event.extra.http.status_code = options[:status_code] || 0
      end
    end

    def self.augment_headers(ctx, headers, url)
      # Strip out existing Trace-* headers and add the correct values, if it's to an internal system
      # Sending Trace headers to external systems could result in a side-channel attack
      # since Trace-Span exposes how many service calls our app has made for a given request
      headers = headers.to_a.reject{ |i| i[0].start_with?("Trace-") }
      if url.host.end_with?("127.0.0.1", "localhost", ".justin.tv", ".twitch.tv")
        headers << ["Trace-ID", ctx.transaction_id[0]]
        headers << ["Trace-ID", ctx.transaction_id[1]]
        headers << ["Trace-Span", ctx.transaction_path_string]
      end
      headers
    end

    # SQL
    def self.sql_start(ctx, options = {})
      send_event(ctx) do |event|
        event.kind = Event::Kind::REQUEST_HEAD_PREPARED
        event.extra.peer = options[:peer] || "0.0.0.0:0"
        event.extra.sql = ExtraSQL.new
        event.extra.sql.database_name = options[:db]
        event.extra.sql.database_user = options[:user]
        event.extra.sql.stripped_query = truncate(options[:query] || "")
      end
    end

    def self.sql_finish(ctx, options = {})
      send_event(ctx) do |event|
        event.kind = Event::Kind::RESPONSE_HEAD_RECEIVED
        event.extra.sql = ExtraSQL.new
      end
    end

    def self.annotate_sql(ctx, query)
      txid = ctx.transaction_id_string.gsub(/[^0-9a-f]/, '') # Only allow hex
      txspan = ctx.transaction_path_string.gsub(/[^0-9\.]/, '') # Only allow digits and .
      query + " /* Trace-Id=#{txid} Trace-Span=#{txspan} */"
    end

    # Memcache
    def self.memcache_start(ctx, options = {})
      send_event(ctx) do |event|
        event.kind = Event::Kind::REQUEST_HEAD_PREPARED
        event.extra.peer = options[:peer] || "0.0.0.0:0"
        event.extra.memcached = ExtraMemcached.new
        event.extra.memcached.command = ExtraMemcached::MemcachedCommand.enum_for_name(options[:command] || "UNKNOWN_COMMAND")
        event.extra.memcached.n_keys = options[:keys] || 0
      end
    end

    def self.memcache_finish(ctx, options = {})
      send_event(ctx) do |event|
        event.kind = Event::Kind::RESPONSE_BODY_RECEIVED
        event.extra.memcached = ExtraMemcached.new
        event.extra.memcached.n_keys = options[:keys] || 0
      end
    end

    private

    def self.barrel
      @@barrel ||= UDPSocket.new
    end

    def self.truncate(str, len = 1024)
      # Ensure unicode string is no longer then len bytes, and is still valid
      ActiveSupport::Multibyte::Chars.new(str).compose.limit(len).to_s
    end

    def self.send_event(ctx)
      event = Event.new
      event.extra = Extra.new

      event.pid = ctx.pid
      event.hostname = ctx.hostname
      event.svcname = ctx.service_name
      event.transaction_id = ctx.transaction_id
      event.path = ctx.transaction_path

      yield event

      now = Time.now.utc
      event.time = now.to_i * 1_000_000_000 + now.nsec

      eventset = EventSet.new(:event => [event])
      begin
        barrel.send(eventset.encode, 0, "127.0.0.1", 8943)
      rescue => e
        sample_exception(e)
      end

      debug_event(event) if Chitin::Config.debug
    end

    def self.debug_event(event)
      txid = event.transaction_id.pack("Q<*").unpack("H*")[0]
      path = event.path.map{ |x| "." + x.to_s }.join("")

      line = []
      line.push(txid + path)

      if event.extra.http
        line.push("HTTP")
      elsif event.extra.sql
        line.push("SQL")
      elsif event.extra.memcached
        line.push("MEMCACHE")
      else
        line.push("UNKNOWN")
      end

      line.push(event.kind.name.downcase)
      line.push(event.extra.peer)

      if event.extra.http
        line.push(event.extra.http.method.name) if event.extra.http.method
        line.push(event.extra.http.uri_path) if event.extra.http.uri_path
        line.push(event.extra.http.status_code.to_s) if event.extra.http.status_code
      end

      if event.extra.sql
        line.push(event.extra.sql.database_name) if event.extra.sql.database_name
        line.push(event.extra.sql.database_user) if event.extra.sql.database_user
      end

      if event.extra.memcached
        line.push(event.extra.memcached.command.name) if event.kind == Event::Kind::REQUEST_HEAD_PREPARED
        line.push(event.extra.memcached.n_keys.to_s) if event.extra.memcached.n_keys
      end

      Rails.logger.debug line.join(" ")
    end

    def self.sample_exception(e)
      key = e.to_s
      $sample_exceptions ||= {}
      $sample_exceptions[key] ||= {count: 0, last_time: Time.now}
      $sample_exceptions[key][:count] += 1
      time_elapsed = (Time.now - $sample_exceptions[key][:last_time]).to_i
      if time_elapsed > 5 #seconds
        backtrace = e.backtrace.join("\n\t")
        Rails.logger.error "Exception #{e} occurred #{$sample_exceptions[key][:count]} times: \n#{backtrace}\n\n"
        $sample_exceptions[key][:count] = 0
        $sample_exceptions[key][:last_time] = Time.now
      end
    end
  end
end
