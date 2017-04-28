module StickyElephant
  class Payload
    def self.valid?(bytes)
      Payload.new(bytes).valid?
    end

    def initialize(bytes = [])
      @bytes = bytes.dup.freeze
    end

    VALID_TYPES=%i(ssl_request handshake quit query).freeze
    def valid?
      VALID_TYPES.include? type
    end

    def to_s
      bytes.pack("C*")
    end

    def ==(arr)
      bytes == arr
    end

    HANDLER_TYPES = {
      StickyElephant::Handler::SSLRequest => :ssl_request,
      StickyElephant::Handler::Handshake  => :handshake,
      StickyElephant::Handler::Quit       => :quit,
      StickyElephant::Handler::Query      => :query,
      StickyElephant::Handler::Error      => :invalid
    }.freeze

    VALID_HANDLERS = (HANDLER_TYPES.keys - [ StickyElephant::Handler::Error]).freeze

    def type
      @type ||= HANDLER_TYPES.fetch(handler)
    end

    def handler
      return @handler if defined? @handler
      _handlers = VALID_HANDLERS.select {|const| const.validates?(bytes)}
      if _handlers.length > 1
        raise StandardError.new("Multiple handlers validated payload #{self}; #{_handlers}")
      end
      @handler ||= _handlers.first || StickyElephant::Handler::Error
    end

    def valid_length?
      if has_claimed_type?
        bytes[1..4].pack("C*").unpack("N") == bytes.size - 1
      else
        bytes[0..3] == bytes.size
      end
    end

    private

    CLAIMED_TYPES=%w(X Q).freeze
    def has_claimed_type?
      CLAIMED_TYPES.include? bytes.first
    end

    attr_reader :bytes
  end
end