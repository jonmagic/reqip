require "commonmarker"
require "flipper"
require "flipper/adapters/redis"
require "ipaddr"
require "pg"
require "redis"
require "sinatra"

redis = Redis.new
db = PG::Connection.new(ENV["DATABASE_URL"] || "postgres://localhost/reqip")
flipper_redis_adapter = Flipper::Adapters::Redis.new(redis)
flipper = Flipper.new(flipper_redis_adapter)

begin
  db.exec("SELECT * FROM requests LIMIT 1")
rescue
  db.exec("CREATE TABLE requests (ip inet)")
  db.exec("CREATE UNIQUE INDEX index_on_ip ON requests (ip)")
end

index_template = File.read("./index.template")
readme_markdown = File.read("./README.md")

class Actor
  def initialize(ip)
    @ip = ip
  end

  def flipper_id
    IPAddr.new(@ip).to_i
  end
end

get "/" do
  actor = Actor.new(request.ip)
  markdown = [readme_markdown]

  if flipper[:ip].enabled?(actor)
    markdown << "* **Request ips:**"
    db.exec("SELECT * FROM requests") do |results|
      results.each do |row|
        markdown << "  * #{row.values_at("ip").first}"
      end
    end
  else
    db.exec("INSERT INTO requests (ip) VALUES ('#{request.ip}') ON CONFLICT DO NOTHING")
    flipper[:ip].enable_actor(actor)
    markdown << "* **Your ip address is:** #{request.ip}"
    markdown << "* **The time is:** #{Time.now.utc.round(10).iso8601(6)} UTC"
  end

  index_template.gsub(/YIELD_HTML_HERE/, CommonMarker.render_html(markdown.join("\n")))
end
