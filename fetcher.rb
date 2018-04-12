#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "filecache"

require "mediawiki_api"

class Fetcher
  attr_reader :cache

  def initialize
    @cache = FileCache.new("gopherpedia", "/tmp", 3600*24, 2)
    @mw = MediawikiApi::Client.new('https://en.wikipedia.org/w/api.php')
  end

  def search(key, offset = nil)
    # srlimit?
    result = @mw.action(:query, {list:'search', srsearch:key, token_type: false}).data
    total = result['searchinfo']['totalhits']
    links = result['search'].map { |row|
      row["title"]
    }

    return total, links
  end

  def get(key, exp = 3600)
    result = @cache.get(key)
    unless result
      result = @mw.get_wikitext(key).body.force_encoding("UTF-8")
      @cache.set(key, result)
    end
    result
  end
end
