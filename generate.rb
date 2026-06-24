# .
# ├── generate.rb
# ├── input/
# │   ├── index.yml
# │   ├── 01-merulo.it.txt
# │   ├── 01-merulo.de.txt
# │   ├── 10-01-primo.it.txt
# │   └── 10-01-primo.de.txt
# ├── style.css
# └── script.js


require "yaml"
require "cgi"
require "fileutils"

INPUT_DIR = "input"
OUTPUT_FILE = "index.html"
NOTES_CANDIDATES = [
  File.join(INPUT_DIR, "notes.md"),
  "notes.md"
].freeze

index = YAML.load_file(File.join(INPUT_DIR, "index.yml"))

def read_poem(path)
  File.read(path, encoding: "UTF-8")
      .lines
      .map(&:chomp)
      .join("<br />\n")
end

def read_markdown(path)
  return "" unless File.exist?(path)

  File.read(path, encoding: "UTF-8")
end

def markdown_blocks(markdown)
  markdown
    .split(/\n{2,}/)
    .map(&:strip)
    .reject(&:empty?)
end

def markdown_inline(text)
  normalized = text.gsub(/\\([\\`*_{}\[\]()#+\-.!>])/, "\\1")
  rendered = CGI.escapeHTML(normalized)

  rendered = rendered.gsub(/`([^`]+)`/) do
    "<code>#{$1}</code>"
  end

  rendered = rendered.gsub(/\[([^\]]+)\]\(([^)]+)\)/) do
    label = $1
    url = CGI.escapeHTML($2)
    %(<a href="#{url}">#{label}</a>)
  end

  rendered = rendered.gsub(/\*\*([^*]+)\*\*/, "<strong>\\1</strong>")
  rendered = rendered.gsub(/(^|[^*])\*([^*]+)\*(?!\*)/, '\1<em>\2</em>')

  rendered
end

def parse_notes(markdown)
  groups = []
  current = nil

  markdown_blocks(markdown).each do |block|
    if (match = block.match(/^\*([^*]+)\*$/m))
      current = {
        title: match[1].strip,
        paragraphs: []
      }
      groups << current
    else
      current ||= {
        title: nil,
        paragraphs: []
      }
      current[:paragraphs] << block
    end
  end

  groups
end

def render_markdown_paragraphs(markdown)
  groups = parse_notes(markdown)
  return "" if groups.empty?

  groups.each_with_index.map do |group, _group_index|
    group_title = group[:title] || "Paragrafo"
    group_id = "note-#{slug(group_title)}"

    paragraphs_html = group[:paragraphs].map do |block|
      content = block
                .lines
                .map(&:rstrip)
                .map { |line| markdown_inline(line) }
                .join("<br />\n")

      "<p>#{content}</p>"
    end.join("\n")

    <<~HTML
      <section class="note-group" id="#{group_id}">
        <details class="note-block">
          <summary>#{CGI.escapeHTML(group_title)}</summary>
          <div class="note-block-body" lang="de">
            #{paragraphs_html}
          </div>
        </details>
      </section>
    HTML
  end.join("\n")
end

def slug(key)
  key.gsub(/^\d+-?/, "").gsub(/[^a-zA-Z0-9]+/, "-").downcase
end

def gen_item_html(item, subpoem=false)
  heading = subpoem ? "h3" : "h2"
  html = <<~HTML

    <article class="poem" id="#{item[:id]}">
      <#{heading}>#{CGI.escapeHTML(item[:title])}</#{heading}>

        <div class="poem-author">
          #{CGI.escapeHTML(item[:author] ? item[:author] : "")}
        </div>

        <div class="poem-book">
          #{CGI.escapeHTML(item[:book] ? item[:book] : "")}
        </div>

      <div class="text original">
        <p>
#{item[:original]}
        </p>
      </div>

      <button class="toggle-translation" type="button">
        Deutsche Übersetzung anzeigen
      </button>

      <div class="text translation" hidden>
        <p>
#{item[:translation]}
        </p>
      </div>
    </article>
  HTML
  html
end

regular_items = []
camera_items = []
notes_path = NOTES_CANDIDATES.find { |path| File.exist?(path) } || NOTES_CANDIDATES.first
notes_markdown = read_markdown(notes_path)
notes_html = render_markdown_paragraphs(notes_markdown)

index.each do |key, label|
  it_path = File.join(INPUT_DIR, "#{key}.it.txt")
  de_path = File.join(INPUT_DIR, "#{key}.de.txt")

  next unless File.exist?(it_path) && File.exist?(de_path)

  label = "NO TITLE" if !label

  title  = label.sub(/\s*\(.+\)\s*(?:\[.+\])?\s*$/, "")
  author = label[/\(([^)]+)\)/, 1]
  book   = label[/\[([^\]]+)\]/, 1]

  item = {
    key: key,
    label: label,
    id: "poem-#{slug(key)}",
    title: title,#label.sub(/\s*\(.+\)\s*$/, ""),
    author: author,
    book: book,
    original: read_poem(it_path),
    translation: read_poem(de_path)
  }

  if key.match?(/^15-\d+-/)
    camera_items << item
  else
    regular_items << item
  end
end

html = <<~HTML
<!doctype html>
<html lang="it">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Una serata principesca</title>
  <link rel="stylesheet" href="style.css" />
</head>
<body>
  <main class="book">
    <header class="site-header">
      <h1>Una serata principesca</h1>
      <p>Divertimenti und Musik an den Adelshöfen von Bologna</p>
      <p>Domus Artis & Il Madrigalone</p>
    </header>

    <nav class="section-jump" aria-label="Section navigation">
      <a href="#notes">PROGRAMMHINWEISE</a>
      <a href="#texts">TEXTE</a>
    </nav>

    <section class="notes-section" id="notes">
      <h2>Programmhinweise</h2>
HTML

html << notes_html

html << <<~HTML
    </section>

    <section id="texts" class="texts-section">
      <nav class="index">
        <h2>Inhaltsverzeichnis der Texte</h2>
        <ol>
HTML

regular_items.each do |item|
  html << <<~HTML
        <li><a href="##{item[:id]}">#{CGI.escapeHTML(item[:title])}</a></li>
  HTML
end

if camera_items.any?
  html << <<~HTML
        <li>
          Trattenimenti da Villa
          <ol>
  HTML

  camera_items.each do |item|
    html << <<~HTML
            <li><a href="##{item[:id]}">#{CGI.escapeHTML(item[:label])}</a></li>
    HTML
  end

  html << <<~HTML
          </ol>
        </li>
  HTML
end

html << <<~HTML
      </ol>
    </nav>
HTML

=begin
(regular_items + camera_items).each do |item|
  html << <<~HTML

    <article class="poem" id="#{item[:id]}">
      <h2>#{CGI.escapeHTML(item[:title])}</h2>

      <button class="toggle-translation" type="button">
        Deutsche Übersetzung anzeigen
      </button>

      <div class="text original">
        <p>
#{item[:original]}
        </p>
      </div>

      <div class="text translation" hidden>
        <p>
#{item[:translation]}
        </p>
      </div>
    </article>
  HTML
end
=end

(regular_items).each do |item|
  html << gen_item_html(item)
end

html<< "<hr><h2>Trattenimenti da Villa</h2>"

html << <<~HTML
<div class="poem-author">
  Adriano Banchieri
</div>

<div class="poem-book">
  Venezia, 1630
</div>
HTML

(camera_items).each do |item|
  html << gen_item_html(item, true)
end

html << <<~HTML
  </main>

  <script src="script.js"></script>
</body>
</html>
HTML

File.write(OUTPUT_FILE, html, encoding: "UTF-8")
puts "Generated #{OUTPUT_FILE}"
