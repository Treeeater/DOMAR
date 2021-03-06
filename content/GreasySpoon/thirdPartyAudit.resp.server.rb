#rights=ADMIN
#--------------------------------------------------------------------
#
#This is a GreasySpoon script.
#
#To install, you need :
#   -jruby
#   -hpricot library
#--------------------------------------------------------------------
#
#WHAT IT DOES:
#
#http://www.google.fr:
#   - show ref links as html tag
#
#--------------------------------------------------------------------
#
#==ServerScript==
#@status on
#@name            ThirdPartyAudit
#@order 0
#@description     ThirdPartyAudit
#@include       .*
#==/ServerScript==
#
require 'rubygems'
require 'hpricot'
#require 'digest/md5'
#require 'net/http'
#require 'uri'
#require 'pp'

#Available elements provided through ICAP server
#puts "---------------"
#puts "HTTP request header: #{$requestheader}"
#puts "HTTP request body: #{$httprequest}"
#puts "HTTP response header: #{$responseheader}"
#puts "HTTP response body: #{$httpresponse}"
#puts "user id (login in most cases): #{$user_id}"
#puts "user name (CN  provided through LDAP): #{$user_name}"
#puts "---------------"

=begin
def process(httpresponse, url, host)
    #puts url
    #puts host
    puts "Begin to parse "+url
    original_document = Hpricot(httpresponse)
    count = 1
    #puts "begin finding GA scripts"
    original_document.traverse_element() do |node|
    if ((node.elem?)&&(!node.comment?)&&(!node.doctype?)&&(!node.text?))
            node.attributes['specialId'] = count.to_s rescue nil
        count+=1
    end
    end
    puts "finish parsing "+url
    filecnt = 1
    while (File.exists? "/home/yuchen/traffic/traffic"+filecnt.to_s+".txt")
    filecnt+=1
    end
    File.open("/home/yuchen/traffic/traffic"+filecnt.to_s+".txt", 'w') {|f| f.write(original_document) }
    return "#{original_document}"
end
=end
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

def collectTextPattern(url)
	if (File.exists? "/home/yuchen/textPattern/"+url+".txt")
		return File.read("/home/yuchen/textPattern/"+url+".txt")
	end
	return nil
end
=begin
def tryToBuildModel(url)
	if ((!File.exists? "/home/yuchen/traffic/"+url+".txt")||(!File.exists? "/home/yuchen/records/"+url+".txt"))
		return
	end
	extractTextPattern("/home/yuchen/traffic/"+url+".txt", "/home/yuchen/records/"+url+".txt", url)
end
=end

def approxmatching(a,b)
	return (a==b)
end

def convertResponse(response, textPattern, url, filecnt)
	listToAdd = Hash.new
	vicinityList = Hash.new
	recordedVicinity = Hash.new
	processedNodes = Hash.new
	id = ""
	error = false
	errormsg = ""
	textPattern.each_line{|l|
		l = l.chomp
		if (l[0..0]=='<')
			matches = false
			id = l.gsub(/.*\>(\d+)$/,'\1')
			if (processedNodes[id]==true)
				next			#we don't want to add multiples of specialId to a node.
			end
			processedNodes[id]=true
			tagName = l.gsub(/\<(\w*).*/,'\1')
			toMatch = l.gsub(/(\<.*\>)\d*/,'\1')
			toMatcht = toMatch
=begin
			#this is the code base to deal with attributes shuffled. However there is a bug. if we need to turn this back on we need to fix it.
			toMatchGrp = toMatch.scan(/(\w*)=\"([\w\s]*)\"/)
			toMatchGrp.each_index{|i|
				toMatchGrp[i] = toMatchGrp[i][0]+"=\""+toMatchGrp[i][1]+"\""
			}
			 to deal with the problem of having different permutations of attributes.
			temp = toMatchGrp.permutation(toMatchGrp.length).to_a
			temp.each_index{|i|
				toMatch = '<'+tagName+(temp[i].length==0?"":" ")+temp[i].join(" ")+'>'
				matchpoints = response.enum_for(:scan,toMatch).map{Regexp.last_match.begin(0)}
				i = 0
				while (i<matchpoints.size)
					matches = true
					listToAdd[id] = (listToAdd[id]==nil) ? Array.new([matchpoints[i]+toMatch.length-1]) : listToAdd[id].push(matchpoints[i]+toMatch.length-1)
					vicinityInfo = (response[matchpoints[i]+toMatch.length,100].gsub(/\n/,''))[0,30]
					vicinityList[id] = (vicinityList[id]==nil) ? Array.new([vicinityInfo]) : vicinityList[id].push(vicinityInfo)
					i+=1
					#response.insert(response.index(toMatch)+toMatch.length-1,' specialId="'+id.to_s+'"')
				end
			}
=end
			matchpoints = response.enum_for(:scan,toMatch).map{Regexp.last_match.begin(0)}
			i = 0
			while (i<matchpoints.size)
				matches = true
				listToAdd[id] = (listToAdd[id]==nil) ? Array.new([matchpoints[i]+toMatch.length-1]) : listToAdd[id].push(matchpoints[i]+toMatch.length-1)
				vicinityInfo = (response[matchpoints[i]+toMatch.length,100].gsub(/\n/,''))[0,30]
				vicinityList[id] = (vicinityList[id]==nil) ? Array.new([vicinityInfo]) : vicinityList[id].push(vicinityInfo)
				i+=1
			end
			if (matches==false)
				error = true
				errormsg += "failed to find a match for "+toMatcht+"\n"
			end
		end
		if (l[0..0]=='&')
			recordedVicinity[id] = l[1,l.length]		#if we want to extract children information
		end
	}
	vicinityList.each_key{|id|
		if (vicinityList[id].length>1)
			#FIXME:We gotta find some way to eliminate this case, otherwise we are screwed.
			screwed = true
			found = 0
			vicinityList[id].each_index{|i|
				if (approxmatching(vicinityList[id][i],recordedVicinity[id]))
					listToAdd[id]=Array.new([listToAdd[id][i]])
					screwed = false
					found += 1
				end
			}
			if (screwed == true)
				error = true
				errormsg += "multiple matches found for: "+toMatcht + ", because no vicinity matches original model.\n"
			end
			if (found > 1)
				error = true
				errormsg += "multiple matches found for: "+toMatcht + ", because more than 1 vicinity matches original model. found a total of "+found.to_s+" matches.\n"
			end
		end
	}
	i = 0
	idToAdd = Array.new
	listToAdd.each_key{|id|
		idToAdd.push(id.to_i)
	}
	idToAdd = idToAdd.sort
	idToAdd.each{|id|
		index = listToAdd[id.to_s][0]+i
		content = " specialId=\"#{id.to_s}\""
		response = response.insert(index, content)
		i+=(" specialId=\"#{id.to_s}\"".length)
	}
	#p vicinityList
	#p recordedVicinity	
	if (error)
		logfh = File.open("/home/yuchen/errorlog.txt","a")
		logfh.write("error when converting url: #{url}, id: #{filecnt}.\n")
		logfh.write(errormsg)
		logfh.close
	end
	return response
end

def initialTraining(response)
    globalNodeIdCount = 0
    pointer = 0
    startingTag = response.index('<',pointer)
    while (startingTag!=nil)
        pointer = startingTag+1
        while (response[pointer..pointer]==" ") 
            pointer+=1                          #skip spaces
        end
        if (response[pointer..pointer]=='/')                    #skip closing tags
            startingTag = response.index('<',pointer)
            next
        end
        if (response.downcase[pointer..pointer+7]=='!doctype')              #skip doctype declarations
            startingTag = response.index('>',pointer)               #assuming no greater than in DOCTYPE declaration.
            startingTag = response.index('<',startingTag)
            next
        end
        if (response[pointer..pointer+2]=='!--')                    #skip comment nodes
            startingTag = response.index('-->',pointer)
            startingTag = response.index('<',startingTag)
            next
        end
        if (response.downcase[pointer..pointer+5] == "script")              #skip chunks of scripts
            pointer = findclosinggt(response,pointer)
            if (response[pointer-1..pointer-1]=='/') 
                #self closing script tag, we don't need to worry about this.
                startingTag = response.index('<',pointer)
                next
            end
            #not self closing script tag, we need to find </script>
            pointer = response.downcase.index('</scr'+'ipt>',pointer) + 1
            startingTag = response.index('<',pointer)
            next
        end
        #we need to add special attrs, now we should find the closing greater than for this opening tag.
        #dealing with '>' in attrs.
        pointer = findclosinggt(response,pointer)
        globalNodeIdCount+=1
        if (response[pointer-1..pointer-1]=='/') 
            response = response[0..pointer-2] + " specialId = \'" + globalNodeIdCount.to_s + "\'" + response[pointer-1..response.length-1]      #self closing tags
        else 
            response = response[0..pointer-1] + " specialId = \'" + globalNodeIdCount.to_s + "\'" + response[pointer..response.length-1]
        end
        startingTag = response.index('<',pointer)
    end   
	return response
end

def process(response, url, host)
    #puts url
    #puts host
    puts "Begin to parse "+url
    sanitizedurl = url.gsub(/[^a-zA-Z0-9]/,"")
    filecnt = 1
    while (File.exists? "/home/yuchen/traffic/#{sanitizedurl}"+filecnt.to_s+".txt")
    	filecnt+=1
    end
    p response[0..10]
	
	textPattern = collectTextPattern(sanitizedurl)
	if (textPattern==nil)
		#no policy file yet, we need to train one.
		response = initialTraining(response)
		#tryToBuildModel(sanitizedurl)
	else
		#found policy file, we can use it directly
		response = convertResponse(response,textPattern,url,filecnt)
	end
    puts "finish parsing "+url
    File.open("/home/yuchen/traffic/#{sanitizedurl}"+filecnt.to_s+".txt", 'w') {|f| f.write(response) }
    return response
end

#main function begins
url = ""
host = ""
hostChopped = ""
policyFile = ""
p "A new request"
if ($httpresponse.match(/\A[^{]/))               #response should not start w/ '{', otherwise it's a json response
    if (($httpresponse.match(/\A\s*\<[\!hH]/)!=nil)&&(!$httpresponse.match(/\A\s*\<\?[xX]/)))
        #getting the URL and host of the request
        if $requestheader =~ /GET\s(.*?)\sHTTP/     #get the URL of the request
		url = $1
		if $requestheader =~ /Host:\s(.*)/  #get the host of the request
		    host = $1
		    hostChopped = host.chop     # The $1 matches the string with a CR added. we don't want that.
		    hostChopped = hostChopped.gsub(/(\.|\/|:)/,'')
		    $httpresponse=process($httpresponse,url,host)
		end
        end
    end
end

