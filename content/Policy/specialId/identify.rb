#!/usr/bin/ruby
require 'rubygems'
require 'hpricot'
#require 'nokogiri'

TrafficDir = "/home/yuchen/traffic/"
RecordsDir = "/home/yuchen/records/"
PolicyDir = "/home/yuchen/textPattern/"

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def identifyId(traffic, record)
	#takes a traffic string and a record string, return an associative array containing domains as keys and an array of 'root' nodes associated with them.
	result = Hash.new
	record.each_line {|r|
		r=r.chomp
		if (r[0..1]=="//")
			url = r[r.index("|:=>")+5..r.length-1]
			specialId = r.gsub(/^\/\/(\d+?)[\s\/].*/m,'\1')
			domain = getTLD(url)
			if (result.has_key? domain)
				result[domain].push(specialId)
			else
				result[domain] = Array.new
				result[domain].push(specialId)
			end
		end
	}
	result.each_key{|k|
		result[k] = result[k].uniq
	}
	#done getting all specialId touched
	document = Hpricot(traffic)
	#document = Nokogiri::HTML(traffic)
=begin
	result.each_key{|k|
		result[k].each{|id|
			elem = document.search("//*[@specialid='#{id}']")[0]
			if (elem.elem?)
				elemp = elem.parent
				while (elemp!=nil)&&(elemp.elem?)
					includedId = elemp.get_attribute('specialid')
					result[k].delete(includedId)
					elemp = elemp.parent
				end
			end
		}
	}
=end
	return result
end

def learnTextPattern(traffic, specialIds)
	result = Hash.new
	document = Hpricot(traffic)
	specialIds.each_key{|k|
		specialIds[k].each{|id|
			elem = document.search("//*[@specialid='#{id}']")[0]
			p id
			if (elem.elem?)
				elem.remove_attribute('specialid')
				elemText = elem.name + elem.attributes_as_html
				elem.set_attribute('specialid',id)
				if (result[k]==nil)
					result[k] = Array.new
				end
				result[k].push(elemText)
			end
		}
	}
	return result
end

def extractTextPattern(trafficFile,recordFile,url)
	traffic = File.read(trafficFile)
	record = File.read(recordFile)
	result = identifyId(traffic,record)
	textPattern = learnTextPattern(traffic,result)
	#p result
	#p textPattern
	fh = File.new(url,'w')
	textPattern.each_key{|k|
		fh.write(k)
		textPattern[k].each_index{|id|
			fh.write("\n<")
			fh.write(textPattern[k][id])
			fh.write(">"+result[k][id].to_s)
		}
		fh.write("\n-----\n")
	}
end

extractTextPattern(TrafficDir+"httpwwwnytimescom.txt",RecordsDir+"httpwwwnytimescom.txt",PolicyDir+"httpwwwnytimescom.txt")
