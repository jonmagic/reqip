require "sinatra"
require "commonmarker"

index_template = File.read("./index.template")
readme_markdown = File.read("./README.md")
readme_html = CommonMarker.render_html(readme_markdown)

get "/" do
  index_template.gsub(/YIELD_HTML_HERE/, readme_html)
end
