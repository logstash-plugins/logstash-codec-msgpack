# encoding: utf-8
require "logstash/codecs/base"
require "logstash/timestamp"
require "logstash/util"

require 'logstash/plugin_mixins/event_support/event_factory_adapter'
require 'logstash/plugin_mixins/validator_support/field_reference_validation_adapter'

class LogStash::Codecs::Msgpack < LogStash::Codecs::Base

  extend LogStash::PluginMixins::ValidatorSupport::FieldReferenceValidationAdapter

  include LogStash::PluginMixins::EventSupport::EventFactoryAdapter

  config_name "msgpack"

  config :format, :validate => :string, :default => nil

  # Defines a target field for placing decoded fields.
  # If this setting is omitted, data gets stored at the root (top level) of the event.
  #
  # NOTE: the target is only relevant while decoding data into a new event.
  config :target, :validate => :field_reference

  public
  def register
    require "msgpack"
  end

  public
  def decode(data)
    begin
      # Msgpack does not care about UTF-8
      event = targeted_event_factory.new_event(MessagePack.unpack(data))
      
      if @format && event.get("message").nil?
        event.set("message", event.sprintf(@format))
      end
    rescue => e
      # Treat as plain text and try to do the best we can with it?
      @logger.warn("Trouble parsing msgpack input, falling back to plain text", input: data, exception: e.class, message: e.message)
      event = event_factory.new_event('message' => data, 'tags' => ["_msgpackparsefailure"])
    end
    yield event
  end # def decode

  public
  def encode(event)
    # use normalize to make sure returned Hash is pure Ruby for
    # MessagePack#pack which relies on pure Ruby object recognition
    data = LogStash::Util.normalize(event.to_hash)
    # timestamp is serialized as a iso8601 string
    # merge to avoid modifying data which could have side effects if multiple outputs
    @on_event.call(event, MessagePack.pack(data.merge(LogStash::Event::TIMESTAMP => event.timestamp.to_iso8601)))
  end # def encode

end # class LogStash::Codecs::Msgpack
