#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "media_wiki"

mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')
url = "Rogers_Hornsby"
#wikitext = mw.get(url)


wikitext = File.open('tmp.txt', 'r') { |f| f.read }

def handle_template(x)
  params = x.split("|")
  case params.first
  when "By"
    return params.last
  when "Inflation"
    return params[2]
  when "Birth date"
    ""
  else
    return ""
  end

#   **{{Birth date|1896|4|27}}**
# **{{death date and age|1963|1|5|1896|4|27}}**
# **{{By|1915}}**
# **{{Inflation|US|75|1914|r=0}}**
end


special_info = ""
sections = {}
see_also = ""

in_body = false
in_special = false
current_section = "Introduction"
in_table = false
wikitext.each_line do |line|
  line.chomp!

  # skip move commands
  next if line.match(/\^{\{pp-move/) ||

    # skip s- commands
    line.match(/^\{\{s\-/) ||

    # skip translations/other languages
    line.match(/^\[\[[a-z]{2}\:/)


  puts "#{current_section} #{in_special} #{in_body} #{line}"

  if in_table
    if line.match(/\|\}$/)
      in_table = false
      next
    end
  elsif line.match(/^\{\|/)
    in_table = true
    next
  elsif in_special
    if line.match(/^\}\}$/)
      in_special = false
      in_body = true
    else
      special_info << line << "\n"
      next
    end
  elsif line.match /\=\=([^\=]+)\=\=/
    current_section = $1
  elsif in_body == false && line.match(/^\{\{Infobox/)
    in_special = true
    next
  else
    in_body = true
    sections[current_section] ||= ""
    sections[current_section] << line << "\n"
  end
end

require 'pp'
pp sections.keys.inspect

sections.each do |k, text|
  puts text
end
exit



result = wikitext.gsub(/(\{\{([^\{\}]+)\}\})/) do |x|
  handle_template($2)
end.
  gsub(/(\{\{([^\{\}]+)\}\})/x, "").
  gsub(/<ref[^\/]+\/>/, "").
  gsub(/<ref\b[^>]*>(.*?)<\/ref>/, "").
  gsub("&nbsp;", " ").
  gsub("($ today)", "").
  gsub(/\[\[([^\]]+)\]\]/) do |x|
   $1.split("|").last
end.
  # dump everything after see-also section
  split("==See also==").first.

  # remove lines with any extra square brackets
  split("\n").collect do |x|
  if x.match(/^\[\[/) || x.match(/\]\]$/)
    nil
  else
    x
  end
end.compact.join("\n")
puts "====================================================="
puts "====================================================="
puts "====================================================="
puts result
