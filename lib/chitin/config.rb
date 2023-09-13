module Chitin
  class Config
    cattr_accessor :service_name do "code.justin.tv/common/chitin-ruby/unknown" end
    cattr_accessor :track_inbound_http do true end
    cattr_accessor :track_outbound_http do true end
    cattr_accessor :track_outbound_sql do true end
    cattr_accessor :track_outbound_memcache do true end

    cattr_accessor :debug do false end
  end

  def self.configure
    yield Chitin::Config
  end
end
