#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "filecache"
require "feedjira"
require 'net/http'

#
# grab wikipedia's daily featured content atom feed
#

# http://en.wikipedia.org/w/api.php?action=featuredfeed&feed=onthisday&feedformat=atom
# http://en.wikipedia.org/w/api.php?action=featuredfeed&feed=featured&feedformat=atom

class FeaturedContent
  #FEED_URL = "https://en.wikipedia.org/w/api.php?action=featuredfeed&feed=featured&feedformat=atom"
  
  def initialize(locale='en')
    @cache = FileCache.new("gopherpedia", "/tmp", 3600, 2)
    @key = "featured.#{locale}.atom"
    @locale = locale
  end

  def fetch(force=false)
    @feed = @cache.get(@key) unless force
    unless @feed
      puts "feed not cached, fetch"
      uri = URI("https://#{@locale}.wikipedia.org/w/api.php?action=featuredfeed&feed=featured&feedformat=atom")
      data = Net::HTTP.get(uri)
      @feed = Feedjira.parse(data)

      @cache.set(@key, @feed)
    end

    result = []

    @feed.entries.each do |entry|
      doc = Nokogiri::HTML(entry.summary)
      doc.xpath("//a").each do |a|
        if a.children.first.name != "img"
          if a.attributes['title']
            title = a.attributes["title"].value
          else
            title = a.text
          end

#          puts a.inspect
#          puts title
#          puts a.attributes["href"]
          result << {
            :date => entry.published,
            :title => title,
            :href => a.attributes["href"].value.gsub("/wiki/", "")
          }
          break
        end
      end
    end

    result

  end
end

if __FILE__ == $0
  f = FeaturedContent.new
  puts f.fetch(true)
end
