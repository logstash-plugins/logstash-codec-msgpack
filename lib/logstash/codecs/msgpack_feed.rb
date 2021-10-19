# encoding: utf-8
require "logstash/codecs/base"

# The "msgpack_feed" codec is for decoding msgpack feeds (streams) which
# have no delimiter between events.
#
# This is useful for decoding msgpack feeds over tcp inputs, pipes or
# other stream-based protocols.
#
# Unfortunately, the default msgpack codec will only work to decode
# complete msgpack objects.
class LogStash::Codecs::MsgpackFeed < LogStash::Codecs::Base
  config_name "msgpack_feed"


  # Set the message you which to emit for each event. This supports `sprintf`
  # strings.
  #
  # This setting only affects inputs (decoding of events).
  config :format, :validate => :string, :default => nil

  def initialize(params={})
    super(params)
    @unpacker = MessagePack::Unpacker.new
  end

  public
  def register
    require "msgpack"
  end

  public
  def decode(data)
    begin
      @unpacker.feed_each(data) do |rawevent|
        event = LogStash::Event.new(rawevent)
        event["tags"] ||= []
        if @format
          event["message"] ||= event.sprintf(@format)
        end
        yield event
      end
    rescue => e
      # Treat as plain text and try to do the best we can with it?
      @logger.warn("Trouble parsing msgpack input, falling back to plain text",
                   :input => data, :exception => e)
      event = LogStash::Event.new
      event["message"] = data.encode('utf-8', 'binary', :invalid => :replace,
                                                        :replace => ' ')
      event["tags"] ||= []
      event["tags"] << "_msgpackparsefailure"
      yield event
    end
  end # def decode
end # class LogStash::Codecs::MsgpackFeed
