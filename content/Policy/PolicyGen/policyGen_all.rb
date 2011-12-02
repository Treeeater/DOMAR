require 'fileutils'
require_relative 'naive'
require_relative 'model'

PRootDir=ENV["Desktop"]+"DOMAR/policy/"		#root directory for generated policy
RRootDir=ENV["Desktop"]+"DOMAR/records/"	#root directory for collected records.
CRootDir=ENV["Desktop"]+"DOMAR/diff/"		#root directory for record - policy checking.
HostDomain = "yelpcom"
HostURL = "httpwwwyelpcomcharlottesvilleva"
P_inst = 0.05								#instrumentation frequency

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def extractRecordsFromFile(hostD)
# This function extracts data from files to an associative array randomly, given the P_inst.
	accessArray = Hash.new
	pFolder = PRootDir+hostD
	rFolder = RRootDir+hostD
	#files = Dir.glob(hostDir+"/*")
	numberOfRecords = Dir.entries(rFolder).length-2			#Total number of records
	numberOfTrainingSamples = (numberOfRecords * P_inst).round		#Total training cases
	indexOfTrainingSamples = Array.new
	#randomize training data
	while ( indexOfTrainingSamples.length < numberOfTrainingSamples )
		temp = rand(numberOfRecords)
		if (!indexOfTrainingSamples.include?(temp)) 
			indexOfTrainingSamples.push(temp)
		end
	end
	
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

#main program
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
extractedRecords = extractRecordsFromFile(workingDir)
strictModel = extractedRecords 	#strictest model is actually just extractedRecord
exportStrictModel(extractedRecords,workingDir)
strictModelTestResult = checkStrictModel(strictModel, workingDir)
p strictModelTestResult.percentage
exportDiffArray(strictModelTestResult, workingDir)