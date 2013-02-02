#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# grep -v -E '^Help:|MediaWiki:|Portal:|Template:|Wikipedia:|File:|Category:' /tmp/titles > /tmp/shorter-titles

# cat shorter-titles | sed "s/'/''/g" | sed "s/.*/'&'/" > titles-load
# 10266  grep ":" /tmp/titles |  awk '{split($0,a,":"); print a[1]}' | sort | uniq -c | sort -n

 #    596 Help
 #   1648 MediaWiki
 #   3361 Book
 # 106542 Portal
 # 385378 Template
 # 657283 Wikipedia
 # 818681 File
 # 949431 Category


require "rubygems"
require "bundler/setup"
require "mysql2"
require "sequel"

require './fetcher'
require './daily'

db_params = {
  :adapter => 'mysql2',
  :host => 'localhost',
  :database => 'gopherpedia',
  :user => 'root',
  :password => nil
}

db_params = {
  :adapter => 'mysql2',
  :host => 'mysql.muffinlabs.com',
  :database => 'gopherpedia',
  :user => 'gopherpedia',
  :password => 'g0ferp3dlia'
}

host = 'gopherpedia.com'
port = 70

# connect to an in-memory database
DB = Sequel.connect(db_params)

def file_for_key(key)
  depth = 4
  root = "/home/mitchc2/gopherpedia-data"
  
  md5 = Digest::MD5.hexdigest(key).to_s
  dir = File.join(root, md5.split(//)[-depth, depth])
  File.join(dir, md5)
end

require 'gopher2000'

set :non_blocking, false
set :host, host
set :port, port

#
# main route
#
route '/' do
  # generate a list of recent page requests
  pagelist = DB[:pages].distinct.select(:title).order(:viewed_at.desc).limit(20).collect { |p|
    p[:title]
  }

  # pull featured content
  f = FeaturedContent.new
  featured = f.fetch

  render :index, pagelist, featured
end


#
# main index for the server
#
menu :index do |pagelist, featured|

  figlet "gopherpedia!"
  br

  block "Welcome to **Gopherpedia**, the gopher interface to Wikipedia. This is a direct interface to wikipedia, you can search and read articles via the search form below. Enjoy!"

  br
  menu "more about gopherpedia", "/about"

  # use br(x) to add x space between lines
  br(2)

  # ask for some input
  text "Search gopherpedia:"
  input 'Search Gopherpedia', '/lookup'

  header "Featured Content"
  featured.reverse.each do |f|
    link "#{f[:date].strftime('%B %e, %Y')}: #{f[:title]}", "/get/#{f[:href]}"
  end
  br(2)

  header "Recent pages"
  pagelist.each do |p|
    link p, "/get/#{p}"
  end
  br

  br(5)
  text "Powered by Gopher 2000, a Muffinlabs Production" 
end

route '/about' do
  render :about
end

menu :about do
  block "In 1991, the Gopher protocol was born -- a method of searching for and distributing information on the Internet. Gopher was intended to be easy to implement and use, and for awhile, it was very popular."
  br

  block "Of course, HTTP and the World Wide Web launched right around that time, and it wasn't long before the Web was proven to be a better platform. Gopher has survived to this day, but the WWW reigns supreme."
  br

  block "Despite its lack of popularity, Gopher is still an awesome protocol - it's extremely hackable and fun to work on. People like to put random stuff on their gopher servers -- their blog, articles they write, etc. I decided that I wanted to write an interface to the single greatest source of information on the Internet -- Wikipedia."
  br

  block "So, I built Gopherpedia. It runs on Gopher2000 (https://github.com/muffinista/gopher2000), a Ruby library I wrote for developing Gopher services. The web proxy to Gopherpedia is GoPHPer (https://github.com/muffinista/gophper-proxy), which I also wrote."
  br

  menu "back to gopherpedia", "/"

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
  puts request.inspect
  key = request.input.strip

  #results = DB[:titles].where(Sequel.like(:title, "%#{key}%"))
  results = DB[:titles].with_sql("SELECT title, MATCH (title) AGAINST (:key) AS score FROM titles WHERE MATCH(title) AGAINST(:key) ORDER BY score DESC LIMIT 100", :key => key)
  total = results.count
  
  #  f = Fetcher.new
#  total, results = f.search(key)

  render :search, key, total, results
end

route '/get/:title' do
  file = file_for_key(params[:title])

  # f = Fetcher.new
  # data = f.get(params[:title])

  data = open(file, &:read)
  
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
    link x[:title], "/get/#{x[:title]}"
  end
  br
  text "** Powered by Gopher 2000 **"
end


text :article do |title, article|
  br

  big_header title

  article.sections.reject { |k, v|
    v.output.length == 0 ||
    ["see also", "references", "external links", "primary sources", "secondary sources" ].include?(k.downcase)
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
