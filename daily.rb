#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "filecache"
require "feedzirra"

class FeaturedContent
  def initialize
    @cache = FileCache.new("gopherpedia", "/tmp", 3600, 2)
    @key = "featured.atom"
  end

  def fetch
    @feed = @cache.get(@key)
    unless @feed
      puts "feed not cached, fetch"
      @feed = Feedzirra::Feed.fetch_and_parse("http://en.wikipedia.org/w/api.php?action=featuredfeed&feed=featured&feedformat=atom")
      @cache.set(@key, @feed)
    end

    result = []

    #feed = Feedzirra::Feed.fetch_and_parse("http://en.wikipedia.org/w/api.php?action=featuredfeed&feed=featured&feedformat=atom")
    @feed.entries.each do |entry|
      doc = Nokogiri::HTML(entry.summary)
      doc.xpath("//a").each do |a|
        if a.children.first.name != "img"
          result << {
            :date => entry.published,
            :title => a.attributes["title"].value,
            :href => a.attributes["href"].value
          }
          break
        end
      end
    end

    puts result.inspect
    result

  end
end

f = FeaturedContent.new
f.fetch
