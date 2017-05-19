require "commonmarker"
require "flipper"
require "flipper/adapters/redis"
require "flipper/adapters/instrumented"
require "flipper/instrumenters/memory"
require "ipaddr"
require "redis"
require "sinatra"

redis = Redis.new
flipper_instrumenters_memory = Flipper::Instrumenters::Memory.new
flipper_adapters_redis = Flipper::Adapters::Redis.new(redis)
flipper_adapters_instrumented = Flipper::Adapters::Instrumented.new(flipper_adapters_redis, {
  instrumenter: flipper_instrumenters_memory
})
flipper = Flipper.new(flipper_adapters_instrumented)

index_template = File.read("./index.template")
readme_markdown = File.read("./README.md")

class Actor

  def self.from_ip(ip)
    ipaddr = IPAddr.new(ip, Socket::AF_INET6) rescue IPAddr.new(ip, Socket::AF_INET)
    new(ipaddr.to_i)
  end

  def self.from_id(id)
    new(id)
  end

  def initialize(flipper_id)
    @flipper_id = flipper_id
  end

  attr_reader :flipper_id

  def ip
    IPAddr.new(flipper_id, Socket::AF_INET) rescue IPAddr.new(flipper_id, Socket::AF_INET6)
  end

  def to_s
    ip.to_s
  end
end

get "/" do
  actor = Actor.from_ip(request.ip)
  enabled_for_actor = flipper[:ip].enabled?(actor)

  markdown = [
    readme_markdown,
    "* **Your ip address is:** #{request.ip}",
    "* **The time is:** #{Time.now.utc.round(10).iso8601(6)} UTC",
    "* **Flipper instrumented events:**",
  ]

  flipper_instrumenters_memory.events.each do |event|
    markdown << "  * **#{event.payload[:operation]}** feature **#{event.payload[:feature_name]}** from **#{event.payload[:adapter_name]}** adapter"
  end

  if enabled_for_actor
    markdown << "* **Request ips:**"
    flipper[:ip].actors_value.each do |id|
      markdown << "  * #{Actor.from_id(id.to_i)}"
    end
  else
    flipper[:ip].enable_actor(actor)
  end

  index_template.gsub(/YIELD_HTML_HERE/, CommonMarker.render_html(markdown.join("\n")))
end
