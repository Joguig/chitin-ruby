class Thread
  attr_reader :parent
  alias_method :orig_initialize, :initialize
  def initialize(*args, &block)
    @parent = Thread.current
    orig_initialize(*args, &block)
  end
end

module Chitin
  class Context
    # Constructors
    def self.load(request)
      txid = request.env["HTTP_TRACE_ID"]
      txspan = request.env["HTTP_TRACE_SPAN"]

      txid = txid && txid.strip.split(/[,\s]+/).map(&:to_i)
      txspan = txspan && txspan.strip.split(".").drop(1).map(&:to_i)

      self.current = Context.new(txid, txspan)
    end

    def initialize(id = nil, path = nil)
      @transaction_id = id || [SecureRandom.random_number(2**64), SecureRandom.random_number(2**64)]
      @transaction_path = path || []
      @span = 0
    end


    # Global values
    def pid
      @@pid ||= Process.pid
    end

    def hostname
      @@hostname ||= `hostname -f`.chomp
    end

    def service_name
      Chitin::Config.service_name
    end


    # Instance values
    attr_reader :transaction_id, :transaction_path

    def transaction_id_string
      # Hex value of the bytes of the ID, least significant bits first
      transaction_id.pack("Q<*").unpack("H*")[0]
    end

    def transaction_path_string
      transaction_path.map{ |x| "." + x.to_s }.join("")
    end

    def span!
      @span += 1
      Context.new(transaction_id, transaction_path + [@span - 1])
    end


    # Look up context from either the current thread, or any of its parents
    # If no context can be found, create one, but don't save it
    def self.current
      lookup || Context.new
    end

    def self.current=(ctx)
      Thread.current.thread_variable_set(:chitin, ctx)
    end

    # Returns a context appropriate for a new outbound call
    # Different from Context.current.span!, which creates a context for the inbound call
    # and then returns a context for a child outbound call for the inbound call.
    def self.span!
      ctx = lookup
      ctx ? ctx.span! : Context.new
    end

    private

    def self.lookup
      c = nil
      t = Thread.current
      while c.nil? do
        c = t.thread_variable_get(:chitin)
        break if t == Thread.main
        t = t.parent
      end
      c
    end
  end
end
