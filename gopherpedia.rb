#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require "rubygems"
require "bundler/setup"

require './fetcher'

require 'gopher2000'

set :host, '0.0.0.0'
set :port, 7070


#
# main route
#
route '/' do
  render :index
end


#
# main index for the server
#
menu :index do
  text "Let's read some shit"

  # use br(x) to add x space between lines
  br(2)

  # ask for some input
  input 'Search for an article', '/lookup'
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
