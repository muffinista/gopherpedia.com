#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "filecache"

require "./parser"
require "media_wiki"

class Fetcher
  attr_reader :cache

  def initialize
	@cache = FileCache.new("gopherpedia", "/tmp", 0, 2)
  end

  def get(key, exp = 3600)
	result = @cache.get(key)
	unless result
	  mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')
	  result = mw.get(key)
	  @cache.set(key, result)
	end
	result
  end
end


#url = "Rogers_Hornsby"
#wikitext = mw.get(url)

#wikitext = File.open('tmp.txt', 'r') { |f| f.read }
f = Fetcher.new
wikitext = f.get("Rogers_Hornsby")

p = Parser.new
a = p.parse(wikitext)

a.sections.each do |k, section|
  puts "*** #{section.title} (#{section.level}) ***"
  puts section
end
