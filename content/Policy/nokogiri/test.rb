require 'open-uri'
require 'nokogiri'

f = File.open("nyt.txt")

# Perform a google search
#doc = Nokogiri::HTML(open('http://www.nytimes.com'))
doc = Nokogiri::HTML(f)

# Print out each link using a CSS selector
puts doc.xpath('/html/body/div')[1].content

#doc.css('a').each do |link|
#  puts link.content
#end