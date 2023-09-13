require "pg_query"

if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
  module ActiveRecord
    module ConnectionAdapters
      class PostgreSQLAdapter
        def execute_with_trace(sql, name = nil)
          trace(sql) { |sql| execute_without_trace(sql, name) }
        end
        alias_method_chain :execute, :trace

        def exec_query_with_trace(sql, name = "SQL", binds = [])
          trace(sql) { |sql| exec_query_without_trace(sql, name, binds) }
        end
        alias_method_chain :exec_query, :trace

        def exec_update_with_trace(sql, name = "SQL", binds = [])
          # Calls execute internally in AR 3.1 and below
          return exec_update_without_trace(sql, name, binds) unless Gem::Version.new(VERSION::STRING) > Gem::Version.new("3.1")
          trace(sql) { |sql| exec_update_without_trace(sql, name, binds) }
        end
        alias_method_chain :exec_update, :trace

        def exec_delete_with_trace(sql, name = "SQL", binds = [])
          # Calls execute internally in AR 3.1 and below
          return exec_delete_without_trace(sql, name, binds) unless Gem::Version.new(VERSION::STRING) > Gem::Version.new("3.1")
          trace(sql) { |sql| exec_delete_without_trace(sql, name, binds) }
        end
        alias_method_chain :exec_delete, :trace

        private

        def trace(sql)
          return yield sql unless Chitin::Config.track_outbound_sql
          ctx = Chitin::Context.span!
          peer = @connection.host + ":" + @connection.port.to_s
          Chitin::Trace.sql_start(ctx, :peer => peer, :db => @connection.db, :user => @connection.user, :query => scrub(sql))
          sql = Chitin::Trace.annotate_sql(ctx, sql)
          r = yield sql
          Chitin::Trace.sql_finish(ctx)
          r
        end

        def scrub(sql)
          # Replace constants, remove comments, normalize whitespace
          PgQuery.normalize(sql).gsub(/\/\*.*?\*\//, "").gsub(/\s+/, " ").strip
        end
      end
    end
  end
end
