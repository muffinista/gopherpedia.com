#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "bundler/setup"
require "mysql2"
require "sequel"

require './fetcher'

# connect to an in-memory database
DB = Sequel.connect(
                    :adapter => 'mysql2',
                    :host => 'localhost',
                    :database => 'gopher',
                    :user => 'root',
                    :password => nil)

# create an items table
if ! DB.table_exists?(:pages)
  DB.create_table :pages do
    primary_key :id
    String :title
    timestamp :viewed_at

    index :viewed_at
  end
end

require 'gopher2000'

set :host, '0.0.0.0'
set :port, 7070

# http://en.wikipedia.org/w/api.php?action=featuredfeed&feed=onthisday&feedformat=atom
# http://en.wikipedia.org/w/api.php?action=featuredfeed&feed=featured&feedformat=atom

#
# main route
#
route '/' do
  # generate a list of recent page requests
  pagelist = DB[:pages].distinct.select(:title).order(:viewed_at.desc).limit(20).collect { |p|
    p[:title]
  }

  render :index, pagelist
end


#
# main index for the server
#
menu :index do |pagelist|

  figlet "gopherpedia!"
  br

  block "Welcome to **Gopherpedia**, the gopher interface to Wikipedia. This is a direct interface to wikipedia, you can search and read articles via the search form below. Enjoy!"

  br
  link "more about gopherpedia", "/about"

  # use br(x) to add x space between lines
  br(2)

  # ask for some input
  text "Search gopherpedia:"
  input 'Search Gopherpedia', '/lookup'

  header "Recent pages"
  pagelist.each do |p|
    link p, "/get/#{p}"
  end
  br

  br(5)
  text "Powered by Gopher 2000, a Muffinlabs Production" 
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

route '/get/:title' do
  f = Fetcher.new
  data = f.get(params[:title])
  p = Parser.new
  a = p.parse(data)

  DB[:pages].insert(:title => params[:title])

  render :article, params[:title], a
end

#
# output the results of a search request
#
menu :search do |key, total, results|
  br
  text "** RESULTS FOR #{key} **"
  br
  results.each do |x|
    link x, "/get/#{x}"
  end
  br
  text "** Powered by Gopher 2000 **"
end


text :article do |title, article|
  br

  big_header title

  article.sections.
    reject { |k, v|
    v.output.length == 0 ||
    ["see also", "references", "external links"].include?(k.downcase)
  }.each do |k, section|

    if section.level < 2
      header section.title
    else
      small_header section.title
    end
    block section.output
    br(2)
  end

  br
end
