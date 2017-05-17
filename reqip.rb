require "commonmarker"
require "pg"
require "sinatra"

db = PG::Connection.new(ENV["DATABASE_URL"] || "postgres://localhost/reqip")

begin
  db.exec("SELECT id FROM requests LIMIT 1")
rescue
  db.exec <<-SQL
    CREATE TABLE requests (
      id bigserial PRIMARY KEY,
      created_at timestamp without time zone,
      ip inet
    );
  SQL
end

index_template = File.read("./index.template")
readme_markdown = File.read("./README.md")

get "/" do
  timestamp = Time.now.utc.round(10).iso8601(6)

  begin
    db.exec <<-SQL
      INSERT INTO requests (created_at, ip)
      VALUES (timestamp '#{timestamp}', '#{request.ip}')
    SQL
  rescue
  end

  markdown = [
    readme_markdown,
    "* **Your ip address is:** #{request.ip}",
    "* **The time is:** #{timestamp} UTC"
  ].join("\n")

  index_template.gsub(/YIELD_HTML_HERE/, CommonMarker.render_html(markdown))
end
