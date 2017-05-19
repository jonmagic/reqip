require "commonmarker"
require "pg"
require "sinatra"

db = PG::Connection.new(ENV["DATABASE_URL"] || "postgres://localhost/reqip")

begin
  db.exec("SELECT * FROM requests LIMIT 1")
rescue
  db.exec("CREATE TABLE requests (ip inet)")
  db.exec("CREATE UNIQUE INDEX index_on_ip ON requests (ip)")
end

index_template = File.read("./index.template")
readme_markdown = File.read("./README.md")

get "/" do
  db.exec("INSERT INTO requests (ip) VALUES ('#{request.ip}') ON CONFLICT DO NOTHING")

  markdown = [
    readme_markdown,
    "* **Your ip address is:** #{request.ip}",
    "* **The time is:** #{Time.now.utc.round(10).iso8601(6)} UTC"
  ].join("\n")

  index_template.gsub(/YIELD_HTML_HERE/, CommonMarker.render_html(markdown))
end
