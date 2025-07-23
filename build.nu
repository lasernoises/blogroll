#!/usr/bin/env nu

use feeds.nu

let atom_contents = $feeds.atom | each {|url| http get $url }
let rss_contents = $feeds.rss | each {|url| http get $url }

# $contents | to json | save -f contents.json
# return
# let contents = open contents.json

def parse_atom_entry [] {
  let content = $in.content
  let title = $content | where tag == title | first | get content | first | get content
  let link = $content | where tag == link | first | get attributes.href

  let published = $content | where tag == published

  let published = if ($published | is-empty) {
    # TODO: Should we just use updated everywhere?
    $content | where tag == updated
  } else {
    $published
  }

  let published = $published | first | get content | first | get content | into datetime

  {
    title: $title,
    published: $published
    link: $link
  }
}

def parse_rss_entry [] {
  let content = $in.content
  let title = $content | where tag == title | first | get content | first | get content
  let link = $content | where tag == link | first | get content | first | get content

  let published = $content | where tag == pubDate | first | get content | first | get content | into datetime

  {
    title: $title,
    published: $published
    link: $link
  }
}


let entries = [
  ($atom_contents
    | each { $in | get content | where tag == entry | first 4 | each { parse_atom_entry } }
    | flatten)
  ($rss_contents
    | each {
      get content
        | where tag == channel
        | first
        | get content
        | where tag == item
        | first 4
        | each { parse_rss_entry }
      }
    | flatten)
] | flatten | sort-by --reverse published

# $entries | save entries.json
# let entries = open entries.json

def escape_html [] {
  # pure efficiency
  $in | php -r 'echo htmlspecialchars(file_get_contents("php://stdin"));'
}

mkdir _site

let css = "
body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  line-height: 1.6;
  max-width: 800px;
  margin: 0 auto;
  padding: 2rem;
  background-color: #fafafa;
  color: #333;
}

h1, title {
  color: #2c3e50;
  margin-bottom: 2rem;
}

div {
  gap: 1rem;
}

a {
  display: block;
  padding: 1rem 1.5rem;
  background: white;
  border: 1px solid #e1e5e9;
  border-radius: 8px;
  text-decoration: none;
  color: #2c3e50;
  transition: all 0.2s ease;
  box-shadow: 0 2px 4px rgba(0,0,0,0.05);
}

a:hover {
  background: #f8f9fa;
  border-color: #3498db;
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.1);
}

a:visited {
  color: #7f8c8d;
}

@media (max-width: 600px) {
  body {
    padding: 1rem;
  }

  a {
    padding: 0.75rem 1rem;
  }
}"

let html = $'<!doctype html>
<html lang="en-US">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width" />

    <title>Blogroll</title>

    <style>($css)</style>
  </head>

  <body>
    <div style="display: flex; flex-direction: column;">
      (
        $entries | each {|entry| $"<a href=\"($entry.link | escape_html)\">($entry.title | escape_html)</a>" } | str join
      )
      <a href="https://github.com/lasernoises/blogroll/actions">
        Last updated: (date now | format date "%Y-%m-%d %H:%M:%S")
      </a>
    </div>
  </body>
</html>'

$html out> _site/index.html
