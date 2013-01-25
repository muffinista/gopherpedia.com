#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

require "sanitize"

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

  def output
    @output ||= Sanitize.clean(clean_text(content)).lstrip.rstrip
  end

  #  def to_s
  #	clean_text(content)
  #  end

  def clean_text(t)
    result = t.gsub(/(\{\{([^\{\}]+)\}\})/) do |x|
      handle_template($2)
    end.
      gsub("'''", "").
      gsub("''", "'").
      gsub(/<!--[\s\S]*?-->/, "").
      gsub(/(\{\{([^\{\}]+)\}\})/x, "").
      gsub(/<ref[^\/]+\/>/i, "").
      gsub(/<ref\b[^>]*>(.*?)<\/ref>/i, "").

      # run a ref strip again to catch multi-line refs
      gsub(/<ref\b[^>]*>/i, "").
      gsub(/<\/ref>/i, "").
      gsub("&nbsp;", " ").
      gsub(/–/, "-").
      gsub("($ today)", "").
      gsub(/\[\[([^\]]+)\]\]/) do |x|
      $1.split("|").last
    end.
#      gsub("()", "").
#      gsub(" ,", ",").

      # dump everything after see-also section
      #split("==See also==").first.

      # remove lines with any extra square brackets
      split("\n").collect do |x|
      if x.match(/^\[\[/) || x.match(/\]\]$/)
        nil
      else
        x
      end
    end.
      compact.join("\n")
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

  #
  # strip some HTML out that we want to remove completely -- mostly
  # ref tags
  #
  def strip_html(text)
    doc = Nokogiri::HTML(text)

    blacklist = ['title', 'script', 'style', 'ref', 'math']
    nodelist = doc.search('//text()')
    blacklist.each do |tag|
      doc.xpath("//" + tag).each { |x| 
        x.children.each { |c| c.remove }

        x.remove 
      }
      #nodelist -= doc.search('//' + tag + '/text()')
    end
    #    nodelist.text
    doc.text
  end

  def parse(text)
    text = strip_html(text)
    w = Article.new

    in_body = false
    special_level = 0
    current_section = "Introduction"
    in_table = false
    
    text = text.gsub(/\{\{'s\}\}/, "'s").gsub(/\{\{/, "\n{{\n")..gsub(/\}\}/, "}}\n")
    
    text.each_line do |line|
      line.chomp!

      # skip move commands
      next if line.match(/\^{\{pp-move/) ||

        # skip s- commands
        line.match(/^\{\{s\-/) ||

        # skip translations/other languages
        line.match(/^\[\[[a-z]{2}\:/)


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
      elsif special_level > 0
        # track the special info that is at the top of an entry, we might use it
        if line.match(/^\}\}/)
          special_level -= 1
          in_body = true if special_level == 0
        else
          w.special << line << "\n"
          next
        end
      elsif line.match /\[\[Category\:([^\]]+)\]\]/
        # store categories on their own
        w.categories << $1
      elsif line.match /\=\=([^\=]+)\=\=/
        # section switch
        current_section = $1.lstrip.rstrip
        level = (line.count("=") / 2).to_i - 1
        w.sections[current_section] ||= ArticleSection.new(current_section, level)
#      elsif in_body == false && line.match(/^\{\{Infobox/)
      elsif in_body == false && line.match(/^\{\{/)        
        special_level += 1
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
