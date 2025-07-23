#!/usr/bin/env nu

use feeds.nu feeds

# let contents = $feeds | each {|url| http get $url }
# $contents | to json | save -f contents.json
# return
let contents = open contents.json

def parse_entry [] {
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

# TODO: build html with actual links and reasonable style
$contents
  | each { $in | get content | where tag == entry | first 4 | each { parse_entry } }
  | flatten | sort-by --reverse published | to html
