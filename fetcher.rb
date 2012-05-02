#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "filecache"

require "./parser"
require "media_wiki"

class MediaWiki::Gateway
  def search(key, namespaces=nil, limit=@options[:limit], offset = nil)
	titles = []
	in_progress = true
	total = 0

	form_data = { 'action' => 'query',
	  'list' => 'search',
	  'srwhat' => 'text',
	  'srsearch' => key,
	  'srlimit' => limit
	}
	if namespaces
	  namespaces = [ namespaces ] unless namespaces.kind_of? Array
	  form_data['srnamespace'] = namespaces.map! do |ns| namespaces_by_prefix[ns] end.join('|')
	end
	begin
	  form_data['sroffset'] = offset if offset
	  res, offset = make_api_request(form_data, '//query-continue/search/@sroffset')
	  total = REXML::XPath.first(res, "//searchinfo").attributes["totalhits"].to_i
	  titles += REXML::XPath.match(res, "//p").map { |x| x.attributes["title"] }
	end while offset && offset.to_i < limit
	return total, titles
  end
end


class Fetcher
  attr_reader :cache

  def initialize
	@cache = FileCache.new("gopherpedia", "/tmp", 0, 2)
	@mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php',
	  :bot => false,
	  :loglevel => Logger::DEBUG,
	  :limit => 50)
  end

  def search(key)
	@mw.search(key)
  end

  def get(key, exp = 3600)
	result = @cache.get(key)
	unless result
	  result = @mw.get(key)
	  @cache.set(key, result)
	end
	result
  end
end


#url = "Rogers_Hornsby"
#wikitext = mw.get(url)

#wikitext = File.open('tmp.txt', 'r') { |f| f.read }
f = Fetcher.new
total, titles = f.search("Baseball")
puts total
puts titles
exit

wikitext = f.get("Rogers_Hornsby")

p = Parser.new
a = p.parse(wikitext)

a.sections.each do |k, section|
  puts "*** #{section.title} (#{section.level}) ***"
  puts section
end
