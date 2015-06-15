#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "filecache"

require "parser"
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
    end while offset && offset.to_s.to_i < limit
    return total, titles
  end
end


class Fetcher
  attr_reader :cache

  def initialize
    @cache = FileCache.new("gopherpedia", "/tmp", 3600*24, 2)
    @mw = MediaWiki::Gateway.new('https://en.wikipedia.org/w/api.php',
                                 :bot => false,
                                 #:loglevel => Logger::DEBUG,
                                 :ignorewarnings => true,
                                 :maxlag => 3600,
                                 :limit => 50)
  end

  def search(key, offset = nil)
    @mw.search(key, nil, 25, offset)
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
