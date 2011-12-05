require 'fileutils'
require_relative 'conf'
require_relative 'model'
require_relative 'utils'
require_relative 'naive'

PRootDir=ENV["Desktop"]+"DOMAR/policy/"		#root directory for generated policy
RRootDir=ENV["Desktop"]+"DOMAR/records/"	#root directory for collected records.
CRootDir=ENV["Desktop"]+"DOMAR/diff/"		#root directory for record - policy checking.

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def getNecessaryFile(hostD)
	hostDir = RRootDir+hostD
	files = Dir.glob(hostDir+"*")
	existingDomains = Hash.new
	returnList = Array.new
	files.each{|file|
		recordedTLD = Array.new
		f = File.open(file, 'r')
		while (line = f.gets)
			line=line.chomp
			_wholoc = line.index(" Who = ")
			if (_wholoc!=nil)
				_who = line[_wholoc+1,line.length]
				_tld = getTLD(_who)
				fileNo = (file.to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')).to_i
				if ((!recordedTLD.include?(_tld))&&((!existingDomains.keys.include? _tld) || (existingDomains[_tld]<MinRep)))
					if (!returnList.include? fileNo)
						returnList.push(fileNo)
					end
					existingDomains[_tld] = (existingDomains[_tld] == nil) ? 1 : existingDomains[_tld] + 1
					recordedTLD.push(_tld)
				end
			end
		end
	}
	return returnList
end

def extractRecordsFromFile(hostD, necFileList)
# This function extracts data from files to an associative array randomly, given the P_inst.
	accessArray = Hash.new
	pFolder = PRootDir+hostD
	rFolder = RRootDir+hostD
	#files = Dir.glob(hostDir+"/*")
	numberOfRecords = Dir.entries(rFolder).length-2					#Total number of records
	numberOfTrainingSamples = (numberOfRecords * P_inst).round		#Total training cases
	if (numberOfTrainingSamples < necFileList.length)
		p "Warning: Given number of training samples aren't even enough to cover all domains, automatically setting sample rate to a minimum of "+(necFileList.length/numberOfRecords.to_f).to_s
		puts ""
		numberOfTrainingSamples = necFileList.length
	end
	p numberOfTrainingSamples
	indexOfTrainingSamples = Array.new(necFileList)
	#randomize adding additional training data (necessary data should be already there)
	while ( indexOfTrainingSamples.length < numberOfTrainingSamples )
		temp = rand(numberOfRecords)
		if (!indexOfTrainingSamples.include?(temp)) 
			indexOfTrainingSamples.push(temp)
		end
	end
	p "Training sample indices are: " + indexOfTrainingSamples.to_s
	puts ""
	i = 0
	while (i < numberOfTrainingSamples)
		fileName = rFolder+"record"+indexOfTrainingSamples[i].to_s+".txt"
		i += 1
		f = File.open(fileName, 'r')
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
					#accessArray[_tld] = Hash.new
					accessArray[_tld] = Array.new
				end
				#If we want to care about the number of accesses of each node, we uncomment the next line and make necessary changes
				#accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
				if (!accessArray[_tld].include? _what)
					accessArray[_tld].push(_what)
				end
			end
		end
		f.close()
	end
	temp = ExtractedRecords.new(accessArray, indexOfTrainingSamples)
	return temp
end

#main training program
hostDomain = ""
hostURL = ""
if ARGV.length==2
	#arguments provided
	hostDomain = ARGV[0]
	hostURL=ARGV[1]
elsif ARGV.length == 0
	puts "What is the intended host domain to generate policy?"
	hostDomain = gets.chomp
	puts "What is the intended host URL to generate policy?"
	hostURL = gets.chomp
else
	#puts "Either give me no arguments or give me two, the first one is host domain and the second one is third party domain. Other arguments are not accepted."
	#Process.exit
	hostDomain = HostDomain
	hostURL = HostURL
end
if (!File.directory? PRootDir) 
	Dir.mkdir(PRootDir)
end
if (!File.directory? PRootDir+hostDomain)
	Dir.mkdir(PRootDir+hostDomain)
end
workingDir = hostDomain+"/"+hostURL+"/"
if (!File.directory? PRootDir+workingDir)
	Dir.mkdir(PRootDir+workingDir)
end

puts ""
puts "Initialized directory configuration, starting to run model building..."
puts ""
#For now we make sure training data includes traces from all possible sources.
necessaryFileList = Alldomain ? getNecessaryFile(workingDir) : Array.new

#
strictModelAvgResult = 0.0
for i in (1..3)
	necFileList = Alldomain ? necessaryFileList : Array.new
	extractedRecords = extractRecordsFromFile(workingDir, necFileList)
	strictModel = extractedRecords 	#strictest model is actually just extractedRecord
	exportStrictModel(extractedRecords,workingDir)
	strictModelTestResult = checkStrictModel(strictModel, workingDir)
	strictModelAvgResult += strictModelTestResult.percentage
	p strictModelTestResult.percentage
	exportDiffArray(strictModelTestResult, workingDir)
end
strictModelAvgResult = strictModelAvgResult / 3.0
if (strictModelAvgResult<Thres)
	p "done! Strictest model suffice. Average result is "+strictModelAvgResult.to_s
else
	p "Strictest model gives bad result, average is "+strictModelAvgResult.to_s
end