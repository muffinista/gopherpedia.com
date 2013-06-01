#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"

require './fetcher'

f = Fetcher.new
#data = f.get("U2_3D")
data = f.get("Over_There_(Fringe)")
p = Parser.new
article = p.parse(data)

puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

article.sections.reject { |k, v|
  v.output.length == 0 ||
  ["see also", "references", "external links", "primary sources", "secondary sources" ].include?(k.downcase)
}.each do |k, section|

  puts "*** #{section.title}"
  puts section.output
end

