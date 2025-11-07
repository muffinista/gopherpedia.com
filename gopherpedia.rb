#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__) unless $:.include? File.dirname(__FILE__)

require "rubygems"
require "bundler/setup"
require "trilogy"
require "sequel"
require "i18n"

require 'parser'
require 'fetcher'
require 'daily'

# require 'pry'

USE_DB = ENV['GOPHERPEDIA_DB_URI'] != nil

I18n.load_path += Dir[File.expand_path("config/locales") + "/*.yml"]
I18n.default_locale = :en # (note that `en` is already the default!)

port = (ENV['GOPHER_PORT'] || 70).to_i
host = '0.0.0.0'

puts "HOST #{host} PORT #{port}"
puts "Locales: #{I18n.load_path.inspect}"

#
# This is a fairly simple wrapper around a DB constant that will check
# the connection status before returning the db handle. Sequel seems
# to like having a constant variable for the connection, and the
# alternative of reconnecting for each request seems ridiculous, so
# this basically fakes being a constant.
#
class DbWrapper
  MY_DB = nil
  class << self
    def connect_to_db
      self.const_set(:MY_DB, Sequel.connect(ENV['GOPHERPEDIA_DB_URI'].gsub(/^mysql2/, 'trilogy')))
    end

    def DB
      if !self.const_get(:MY_DB)&.test_connection
        self.connect_to_db
      else
        self.const_get(:MY_DB)
      end
    end
  end
end


require 'gopher2000'

set :non_blocking, false
set :host, host
set :port, port

LOCALE_MATCH = Regexp.new(/^\/lang=(\w+)/)

before_action do |selector, params|
  if re = LOCALE_MATCH.match(selector)
    params['lang'] = re[1]
    selector = selector.gsub(/#{re[0]}/, '/')
    I18n.locale = params['lang']
  else
    params['lang'] = I18n.locale = I18n.default_locale
  end
  return selector, params
end

#
# main index for the server
#
menu :index do |pagelist, featured|
  block params['lang']
  figlet "gopherpedia!"
  br
  block I18n.t('index.welcome')

  br
  menu I18n.t('index.more_about'), "/about", 'gopherpedia.com'

  # use br(x) to add x space between lines
  br(2)

  # ask for some input
  text I18n.t('index.search_header')
  input I18n.t('index.search_input'), '/lookup', 'gopherpedia.com'

  header I18n.t('index.featured_content')
  featured.reverse.each do |f|
    text_link "#{f[:date].strftime(I18n.t('.date'))}: #{f[:title]}", "/#{f[:title]}", 'gopherpedia.com'
  end
  br(2)

  header I18n.t('index.recent_pages')
  pagelist.each do |p|
    text_link p, "/#{p}", 'gopherpedia.com'
  end
  br

  br(5)
  text I18n.t('.powered_by')
end

route '/about' do
  render :about
end

menu :about do
  figlet "Gopher!"
  br

  block "In 1991, the Gopher protocol was born -- a method of searching for and distributing information on the Internet. Gopher was intended to be easy to implement and use, and for a little while, it was very popular."
  br

  block "Of course, HTTP and the World Wide Web launched right around that time, and it wasn't long before the Web was proven to be a better platform. Gopher has survived to this day, but the WWW reigns supreme."
  br

  block "Despite its lack of popularity, Gopher is still an awesome protocol - it's extremely hackable and fun to work on. People like to put random stuff on their gopher servers -- their blog, articles they write, etc. I decided that I wanted to write an interface to the single greatest source of information on the Internet -- Wikipedia."
  br

  block "So, I built Gopherpedia. It runs on Gopher2000 (https://github.com/muffinista/gopher2000), a Ruby library I wrote for developing Gopher services. The web proxy to Gopherpedia is GoPHPer (https://github.com/muffinista/gophper-proxy), which I also wrote."
  br

  text_link "more about the Gopher protocol", "Gopher (protocol)", 'gopherpedia.com'

  http "gopher2000 - a ruby gopher server", "http://github.com/muffinista/gopher2000", 'gopherpedia.com'
  http "gophper-proxy - a modern PHP gopher proxy", "http://github.com/muffinista/gophper-proxy", 'gopherpedia.com'

  br
  menu "back to gopherpedia", "/", 'gopherpedia.com'
end


#
# actions have access to the request object, and can grab the following data:
#
# input: The input string, if provided (for searches, etc)
# selector: The path of the request being made
# ip_address: The remote IP address
#
#  location = request.input.strip

route '/lookup' do
  key = request.input.strip
  f = Fetcher.new
  total, results = f.search(key)

  render :search, key, total, results
end

#
# main route
#
route '/*' do
  title = params[:splat].strip

  if title && title != '/' && title.length > 0
    begin
      f = Fetcher.new
      data = f.get(title)
      if redirect = data.match(/^#REDIRECT ?\[\[([^\]]+)\]\]/)
        data = f.get(redirect[1])
      end
      
      p = Parser.new
      a = p.parse(data)
    
      if USE_DB && !data.nil? && data != ""
        DbWrapper.DB[:pages].insert(:title => title)
      end
    
      render :article, title, a
    rescue StandardError => ex
      render :error, ex.message
    end

  else
    # generate a list of recent page requests
    pagelist = if USE_DB
                 DbWrapper.DB[:pages]
                   .select(:title,
                           Sequel.function(:max, :viewed_at).as(:viewed_at))
                   .group_by(:title)
                   .order(Sequel.desc(:viewed_at))
                   .limit(20)
                   .collect { |p| p[:title] }
               else
                 []
               end

    # pull featured content
    f = FeaturedContent.new
    featured = f.fetch
    
    render :index, pagelist, featured
  end
end

#
# output the results of a search request
#
menu :search do |key, total, results|
  br
  text "** RESULTS FOR #{key} **"
  br
  results.each do |x|
    text_link x, "/#{x}", 'gopherpedia.com'
  end
  br
  text "** Powered by Gopher 2000 **"
end


menu :error do |code|
  figlet "Ooops!"
  br

  text I18n.t('error.heading')
  br
  br
  error "Error #{code.to_s}"
  br
  br
  menu I18n.t('.back_to'), "/", 'gopherpedia.com'
end

text :article do |title, article|
  br

  big_header title

  article.sections.reject { |k, v|
    v.output.length == 0 || v.output.gsub("*", "").strip.length == 0
  }.each do |k, section|
    if section.level < 2
      header section.title
    else
      small_header section.title
    end
    block section.output
    br(2)
  end

  small_header "License"
  text "All content on Gopherpedia comes from Wikipedia, and is licensed under CC-BY-SA"
  text "License URL: http://creativecommons.org/licenses/by-sa/3.0/"
  text "Original Article: http://en.wikipedia.org/wiki/#{title.gsub(/ /, '_')}"
  
  br
end
