#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

class ArticleSection
  attr_accessor :level
  attr_accessor :title
  attr_accessor :content

  def initialize(s, l=1)
	@title = s
	@level = l
	@content = ""
  end

  def <<(x)
	self.content << x
  end

  def to_s
	clean_text(content)
  end

  def clean_text(t)
	result = t.gsub(/(\{\{([^\{\}]+)\}\})/) do |x|
	  handle_template($2)
	end.
	  gsub("'''", "").
	  gsub("''", "'").
	  gsub(/(\{\{([^\{\}]+)\}\})/x, "").
	  gsub(/<ref[^\/]+\/>/, "").
	  gsub(/<ref\b[^>]*>(.*?)<\/ref>/, "").
	  gsub("&nbsp;", " ").
	  gsub("($ today)", "").
	  gsub(/\[\[([^\]]+)\]\]/) do |x|
	  $1.split("|").last
	end.
	  # dump everything after see-also section
	  #split("==See also==").first.

	  # remove lines with any extra square brackets
	  split("\n").collect do |x|
	  if x.match(/^\[\[/) || x.match(/\]\]$/)
		nil
	  else
		x
	  end
	end.compact.join("\n")
  end

  def handle_template(x)
	params = x.split("|")
	case params.first
	when "By"
	  return params.last
	when "Inflation"
	  return params[2]
	when "Birth date"
	  ""
	else
	  return ""
	end

	#   **{{Birth date|1896|4|27}}**
	# **{{death date and age|1963|1|5|1896|4|27}}**
	# **{{By|1915}}**
	# **{{Inflation|US|75|1914|r=0}}**
  end


end

class Article
  attr_accessor :special
  attr_accessor :sections
  attr_accessor :links
  attr_accessor :categories

  def initialize
	@special = ""
	@sections = {}
	@links = ""

	@categories = []
  end
end

class Parser

  def parse(text)

	w = Article.new

	in_body = false
	in_special = false
	current_section = "Introduction"
	in_table = false

	text.each_line do |line|
	  line.chomp!

	  # skip move commands
	  next if line.match(/\^{\{pp-move/) ||

		# skip s- commands
		line.match(/^\{\{s\-/) ||

		# skip translations/other languages
		line.match(/^\[\[[a-z]{2}\:/)

	  #puts "#{current_section} #{in_special} #{in_body} #{line}"


	  if in_table
		# skip tables
		if line.match(/\|\}$/)
		  in_table = false
		  next
		end
	  elsif line.match(/^\{\|/)
		in_table = true
		next
	  elsif line.match(/^\[\[File\:/)
		next
	  elsif in_special

		# track the special info that is at the top of an entry, we might use it
		if line.match(/^\}\}$/)
		  in_special = false
		  in_body = true
		else
		  w.special << line << "\n"
		  next
		end
	  elsif line.match /\[\[Category\:([^\]]+)\]\]/
		# store categories on their own
		w.categories << $1
	  elsif line.match /\=\=([^\=]+)\=\=/
		# section switch
		current_section = $1
		level = (line.count("=") / 2).to_i - 1
		w.sections[current_section] ||= ArticleSection.new(current_section, level)
	  elsif in_body == false && line.match(/^\{\{Infobox/)
		in_special = true
		next
	  else

		# add this line to our current section
		in_body = true
		w.sections[current_section] ||= ArticleSection.new(current_section)
		w.sections[current_section] << line << "\n"
	  end
	end

	w
  end
end
