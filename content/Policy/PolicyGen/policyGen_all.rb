require 'fileutils'
require_relative 'model'
require_relative 'utils'
require_relative 'naive'

PRootDir=ENV["Desktop"]+"DOMAR/policy/"		#root directory for generated policy
RRootDir=ENV["Desktop"]+"DOMAR/records/"	#root directory for collected records.
CRootDir=ENV["Desktop"]+"DOMAR/diff/"		#root directory for record - policy checking.
HostDomain = "nytimescom"
HostURL = "httpwwwnytimescom"
P_inst = 0.04								#instrumentation frequency
Thres = 0.1									#allowed maximum false positive
Alldomain = true							#allow the model builder to first scan all records and record all files that contain a new domain. Those files will be automatically considered in training phase.

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def getNecessaryFile(hostD)
	hostDir = RRootDir+hostD
	files = Dir.glob(hostDir+"*")
	existingDomains = Array.new
	returnList = Array.new
	files.each{|file|
		f = File.open(file, 'r')
		while (line = f.gets)
			line=line.chomp
			_wholoc = line.index(" Who = ")
			if (_wholoc!=nil)
				_who = line[_wholoc+1,line.length]
				_tld = getTLD(_who)
				fileNo = file.to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')
				if ((!existingDomains.include? _tld)&&(!returnList.include? fileNo))
					returnList.push(fileNo)
					existingDomains.push(_tld)
				end
			end
		end
	}
	return returnList
end

def extractRecordsFromFile(hostD, necessaryFileList)
# This function extracts data from files to an associative array randomly, given the P_inst.
	accessArray = Hash.new
	pFolder = PRootDir+hostD
	rFolder = RRootDir+hostD
	#files = Dir.glob(hostDir+"/*")
	numberOfRecords = Dir.entries(rFolder).length-2					#Total number of records
	numberOfTrainingSamples = (numberOfRecords * P_inst).round		#Total training cases
	if (numberOfTrainingSamples < necessaryFileList.length)
		p "Warning: Given number of training samples aren't even enough to cover all domains, automatically setting sample rate to a minimum of "+(necessaryFileList.length/numberOfRecords.to_f).to_s
		puts ""
		numberOfTrainingSamples = necessaryFileList.length
	end
	p numberOfTrainingSamples
	indexOfTrainingSamples = necessaryFileList
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
					accessArray[_tld] = Hash.new
				end
				accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
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
for i in (1..1)
	extractedRecords = extractRecordsFromFile(workingDir, necessaryFileList)
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
end