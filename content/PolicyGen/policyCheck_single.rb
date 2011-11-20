PRootDir="C:/Users/Yuchen/Desktop/DOMAR/policy/"	#root directory for generated policy
RRootDir="C:/Users/Yuchen/Desktop/DOMAR/records/"	#root directory for collected records.
CRootDir="C:/Users/Yuchen/Desktop/DOMAR/check/"		#root directory for record - policy checking.

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def pLoad(hostD)
	#load from stored policy library into accessArray (2-level hash)
	accessArray = Hash.new
	files = Dir.glob(hostD+"*")
	files.each{|file|
		f = File.open(file, 'r')
		file = file.gsub(/.*\/(.*)\.txt/,'\1')
		accessArray[file]=Hash.new
		while (line = f.gets)
			line = line.chomp
			splited = line.split('|:=>')
			accessArray[file][splited[0]]=splited[1]
		end
		f.close()
	}
	return accessArray	
end

def rLoad(requestRecordFile)
	#load from recordings of a single request into accessArray
	accessArray = Hash.new
	f = File.open(requestRecordFile, 'r')
	while (line = f.gets)
		line=line.chomp
		_whatloc = line.index(" What = ")
		_wholoc = line.index(" Who = ")
		if ((_whatloc!=nil)&&(_wholoc!=nil))
			_when = line[0,_whatloc]
			_what = line[_whatloc+1, _wholoc-_whatloc]
			_who = line[_wholoc+1,line.length]
			_tld = getTLD(_who)
			if (accessArray[_tld]==nil)
				#2-level array
				accessArray[_tld] = Hash.new
			end
			accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
		end
	end
	f.close()
	return accessArray
end

def compare(pArray, aArray)
	#aArray is the actual new recordings, pArray is stored policies. Our job is to find the elements that's inside aArray but not inside pArray.
	diffArray = Hash.new
	aArray.each_key{|tld|
		if (pArray[tld]==nil)
			#script from new source detected. We want to copy all accesses from this script to diff.
			diffArray[tld] = Hash.new
			aArray[tld].each_key{|what|
				diffArray[tld][what]=aArray[tld][what]
			}
		else
			#we have policies for this script's source domain
			diffArray[tld]=Hash.new
			aArray[tld].each_key{|what|
				if (pArray[tld][what]==nil)
					#This access has never happened before
					#This is illegal, record
					diffArray[tld][what]=aArray[tld][what]
				end
			}
		end
	}
	return diffArray
end

#main program
hostDomain = ""
requestFile = ""
if ARGV.length==2
	#arguments provided
	hostDomain = ARGV[0]
	requestFile = ARGV[1]
elsif ARGV.length == 0
	puts "where is the intended host domain/URL policy stored? e.g. yelpcom/httpwwwyelpcomuserdetails"
	#hostDomain = gets.chomp
	hostDomain = "yelpcom/httpwwwyelpcomuserdetails"
	puts "What is the intended request record file to check? e.g. record1.txt"
	requestFile = gets.chomp
end
requestFile=hostDomain+"/"+requestFile
output = "diff.txt"
policyFolder = PRootDir+hostDomain+"/"
requestFile = RRootDir+requestFile
if ((!File.directory? policyFolder)||(!File.exists? requestFile))
	puts("No policy found!")
	Process.exit
end

policyArray = pLoad(policyFolder)
accessArray = rLoad(requestFile)
diffArray = compare(policyArray,accessArray)
outputFile = File.open(output, 'w')
diffArray.each_key{|tld|
	outputFile.puts("-----"+tld+"------")
	if (diffArray[tld].length==0)
		outputFile.puts("------All accesses are legal!------")
	else
		diffArray[tld].each_key{|what|
			outputFile.puts(what.to_s+"|:=>"+diffArray[tld][what].to_s)
		}
	end
}
outputFile.close()