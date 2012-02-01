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
	#document = Hpricot(traffic)
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

def findclosinggt(response,pointer)
    fsmcode = 0         # 0 stands for no opening attr, 1 stands for opening single quote attr and 2 stands for opening double quote attr.
    while (pointer<response.length)
        if ((response[pointer..pointer]!='>')&&(response[pointer..pointer]!='\'')&&(response[pointer..pointer]!='"'))
            pointer+=1
            next
        elsif (response[pointer..pointer]=='>')
            if (fsmcode == 0)
                break
            end
            pointer+=1
            next
        elsif (response[pointer..pointer]=='\'')
            if (fsmcode&2!=0)
                pointer+=1      #opening double quote attr, ignore sq
                next
            end
            fsmcode = 1 - fsmcode       #flip sq status
            pointer += 1
            next
        elsif (response[pointer..pointer]=='"')
            if (fsmcode&1!=0)
                pointer+=1      #opening single quote attr, ignore dq
                next
            end
            fsmcode = 2 - fsmcode       #flip sq status
            pointer += 1
            next
        end         
    end 
    return pointer
end

def findopeninglt(response,pointer)
    fsmcode = 0         # 0 stands for no opening attr, 1 stands for opening single quote attr and 2 stands for opening double quote attr.
    while (pointer<response.length)
        if ((response[pointer..pointer]!='<')&&(response[pointer..pointer]!='\'')&&(response[pointer..pointer]!='"'))
            pointer-=1
            next
        elsif (response[pointer..pointer]=='<')
            if (fsmcode == 0)
                break
            end
            pointer-=1
            next
        elsif (response[pointer..pointer]=='\'')
            if (fsmcode&2!=0)
                pointer-=1      #opening double quote attr, ignore sq
                next
            end
            fsmcode = 1 - fsmcode       #flip sq status
            pointer -= 1
            next
        elsif (response[pointer..pointer]=='"')
            if (fsmcode&1!=0)
                pointer-=1      #opening single quote attr, ignore dq
                next
            end
            fsmcode = 2 - fsmcode       #flip sq status
            pointer -= 1
            next
        end         
    end 
    return pointer
end

def learnTextPattern(traffic, specialIds)
	result = Hash.new
	specialIds.each_key{|k|
		result[k]=Array.new
		specialIds[k].each{|id|
			attrIndex = traffic.index(/specialId\s=\s\'#{id}\'/)
			p id
			closinggt = findclosinggt(traffic, attrIndex)
			openinglt = findopeninglt(traffic, attrIndex)
			tagInfo = traffic[openinglt..closinggt].gsub(/\sspecialId\s=\s\'\d+\'/,'')
			vicinityInfo = (traffic[closinggt+1,100].gsub(/\sspecialId\s=\s\'\d+\'/,'').gsub(/\n/,''))[0,30]
			result[k].push( [ tagInfo , vicinityInfo ] )
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
			fh.write("\n")
			fh.write(textPattern[k][id][0])
			fh.write(result[k][id].to_s+"\n")
			fh.write("&"+textPattern[k][id][1].to_s)
		}
		fh.write("\n-----\n")
	}
end

extractTextPattern(TrafficDir+"httpwwwnytimescom.txt",RecordsDir+"httpwwwnytimescom.txt",PolicyDir+"httpwwwnytimescom.txt")
