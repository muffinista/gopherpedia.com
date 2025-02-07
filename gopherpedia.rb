#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

$: << File.dirname(__FILE__) unless $:.include? File.dirname(__FILE__)

require "rubygems"
require "bundler/setup"
require "trilogy"
require "sequel"

require 'parser'
require 'fetcher'
require 'daily'

port = (ENV['GOPHER_PORT'] || 70).to_i
host = '0.0.0.0'

puts "HOST #{host} PORT #{port}"

# connect to database
if ENV['GOPHERPEDIA_DB_URI']
  puts "Connect to #{ENV['GOPHERPEDIA_DB_URI']}"
  DB = Sequel.connect(ENV['GOPHERPEDIA_DB_URI'].gsub(/^mysql2/, 'trilogy'))
end

require 'gopher2000'

set :non_blocking, false
set :host, host
set :port, port

#
# main index for the server
#
menu :index do |pagelist, featured|
  figlet "gopherpedia!"
  br
  block "Welcome to **Gopherpedia**, the gopher interface to Wikipedia. This is a direct interface to wikipedia, you can search and read articles via the search form below. Enjoy!"

  br
  menu "more about gopherpedia", "/about", 'gopherpedia.com'

  # use br(x) to add x space between lines
  br(2)

  # ask for some input
  text "Search gopherpedia:"
  input 'Search Gopherpedia', '/lookup', 'gopherpedia.com'

  header "Featured Content"
  featured.reverse.each do |f|
    text_link "#{f[:date].strftime('%B %e, %Y')}: #{f[:title]}", "/#{f[:title]}", 'gopherpedia.com'
  end
  br(2)

  header "Recent pages"
  pagelist.each do |p|
    text_link p, "/#{p}", 'gopherpedia.com'
  end
  br

  br(5)
  text "Powered by Gopher 2000, a Muffinlabs Production" 
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
route '/:title?' do
  if params[:title] && ! params[:title].strip.nil? && params[:title] != "/"
    begin
      f = Fetcher.new
      data = f.get(params[:title])
      if redirect = data.match(/^#REDIRECT ?\[\[([^\]]+)\]\]/)
        data = f.get(redirect[1])
      end

      
      p = Parser.new
      a = p.parse(data)
    
      if defined?(DB) && !data.nil? && data != ""
        DB[:pages].insert(:title => params[:title])
      end
    
      render :article, params[:title], a
    rescue StandardError => ex
      render :error, ex.message
    end

  else
    # generate a list of recent page requests
    pagelist = if defined?(DB)
                 DB[:pages]
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

  text "Looks like something went wrong with that request"
  br
  br
  error "Error #{code.to_s}"
  br
  br
  menu "back to gopherpedia", "/", 'gopherpedia.com'
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
