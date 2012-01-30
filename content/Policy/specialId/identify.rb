require 'hpricot'
#require 'nokogiri'

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
	#p (document.search("//div[@id='SponLinkHP']"))[0]
	result.each_key{|k|
		result[k].each{|id|
			elem = document.search("//*[@specialid='#{id}']")[0]
			if (elem.elem?)
				elemp = elem.parent
				while (elemp!=nil)&&(elemp.elem?)
					includedId = elemp.get_attribute('specialid')
					#result[k].delete(includedId)
					elemp = elemp.parent
				end
			end
		}
	}
	return result
end

traffic = File.read("traffic1.txt")
record = File.read("record1.txt")
result = identifyId(traffic,record)
p result