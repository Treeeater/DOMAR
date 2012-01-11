require 'fileutils'
require_relative 'conf'
require_relative 'model'
require_relative 'utils'
require_relative 'naive'
require_relative 'children'

PRootDir=ENV["Desktop"]+"DOMAR/policy/"		#root directory for generated policy
RRootDir=ENV["Desktop"]+"DOMAR/records/"	#root directory for collected records.
CRootDir=ENV["Desktop"]+"DOMAR/diff/"		#root directory for record - policy checking.

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def getSequentialFile(hostD)
	hostDir = RRootDir+hostD
	files = Dir.glob(hostDir+"*")
	#assuming file id is from 1 to N.
	numberOfRecords = Dir.entries(hostDir).length-2					#Total number of records
	numberOfTrainingSamples = (numberOfRecords * P_inst).round		#Total training cases
	i = 1
	returnList = Array.new
	while (i <= numberOfTrainingSamples)
		returnList.push(i)
		i+=1
	end
	return returnList
end

def getNecessaryFile(hostD)
	hostDir = RRootDir+hostD
	files = Dir.glob(hostDir+"*")
	files = permute_array(files)
	existingDomains = Hash.new
	returnList = Array.new
	files.each{|file|
		recordedTLD = Array.new
		f = File.open(file, 'r')
		while (line = f.gets)
			line=line.chomp
			_wholoc = line.index(" |:=> ")
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

def extractRecordsFromTrainingData(hostD, necFileList)
# This function extracts data from files to an associative array randomly, given the P_inst.
	accessHash = Hash.new
	locationHash = Hash.new			#This hash is used to store the embedding location of scripts for each individual tld.
	tlds = Array.new
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
			_scriptLocation = line.index(" <=|=> ")
			if (_scriptLocation!=nil)
				_who = line[0, _scriptLocation]
				_where = line[_scriptLocation+1,line.length]
				_tld = getTLD(_who)
			end
			_wholoc = line.index(" |:=> ")
			if (_wholoc!=nil)
				_what = line[0, _wholoc]
				_who = line[_wholoc+1,line.length]
				_tld = getTLD(_who)
				if (accessHash[_tld]==nil)
					#2-level array
					#accessHash[_tld] = Hash.new
					accessHash[_tld] = Array.new
				end
				#If we want to care about the number of accesses of each node, we uncomment the next line and make necessary changes
				#accessHash[_tld][_what] = (accessHash[_tld][_what]==nil) ? 1 : accessHash[_tld][_what]+1
				if (!accessHash[_tld].include? _what)
					accessHash[_tld].push(_what)
				end
			end		
		end
		f.close()
	end
	i = 0
	while (i < numberOfRecords)
		fileName = rFolder+"record"+indexOfTrainingSamples[i].to_s+".txt"
		i += 1
		f = File.open(fileName, 'r')
		while (line = f.gets)
			line=line.chomp
			_wholoc = line.index(" |:=> ")
			if (_wholoc!=nil)
				_who = line[_wholoc+1,line.length]
				_tld = getTLD(_who)
				if (!tlds.include? _tld) 
					tlds.push _tld
				end
			end
		end
		f.close()
	end
	#sort accessHash in an alphebatically order
	accessHash.each_key{|_tld|
		accessHash[_tld] = accessHash[_tld].sort
	}
	temp = ExtractedRecords.new(accessHash, indexOfTrainingSamples,tlds)
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
if (File.directory? PRootDir+workingDir+"relaxed/")
	cleanDirectory(PRootDir+workingDir+"relaxed/")
end
puts ""
puts "Initialized directory configuration, starting to run model building..."
puts ""
cleanDirectory(CRootDir)
puts "Cleaned diff dir..."
#For now we make sure training data includes traces from all possible sources.
#necessaryFileList = Alldomain ? getNecessaryFile(workingDir) : Array.new

#
for i in (1..Running_times)
	modelTotalResult = 1.0
	puts "Running for the #{i}th time"
	#necFileList = Alldomain ? necessaryFileList : Array.new
	necFileList = Alldomain ? getNecessaryFile(workingDir) : (Sequential ? getSequentialFile(workingDir) : Array.new)
	extractedRecords = extractRecordsFromTrainingData(workingDir, necFileList)
	exportAllRecords(extractedRecords,workingDir)
	model = Model.new
	tlds = Array.new
	extractedRecords.records.each_key{|tld|
		tempModel = buildStrictModel(extractedRecords.records[tld], tld) 	#strictest model is actually just extractedRecord
		strictModelTestResult = checkStrictModel(tempModel, workingDir, extractedRecords)
		if ((strictModelTestResult.percentage > StrictModelThreshold) && (RelaxedModeEnabled))
			#we need a more relaxed model
			relaxedModel = learnRelaxedModel(tempModel)
			exportRelaxedModel(relaxedModel, workingDir)
			relaxedModelTestResult = checkRelaxedModel(relaxedModel, workingDir, extractedRecords, strictModelTestResult)
			modelTotalResult *= (1-relaxedModelTestResult.percentage)
			p "Relaxed Model : Difference at #{tld} domain is :"
			p relaxedModelTestResult.percentage.to_s
			model.adoptTLD(tld,relaxedModel)
			exportDiffArrayToSingleFile(relaxedModelTestResult, workingDir, tld)
		else
			modelTotalResult *= (1-strictModelTestResult.percentage)
			model.adoptTLD(tld,tempModel)
			exportDiffArrayToSingleFile(strictModelTestResult, workingDir, tld)
		end
		p "Strict Model : Difference at #{tld} domain is :"
		p strictModelTestResult.percentage.to_s
		tlds.push tld			#to record what tld(s) have been checked.
		#exportDiffArray(strictModelTestResult, workingDir, tld)
	}
	if (!Alldomain)
		#if alldomain option is off, we need to check if any other domain exists besides the domains existing in training data.
		p "All domain is set to false, we will check for potential domain lost in training data..."
		flag = false
		extractedRecords.tlds.each{|tld|
			if (!extractedRecords.records.keys.include? tld)
				p tld + " not found in training data."
				flag = true
			end
		}
		if (!flag)
			p "Good, no domain is lost in training data!"
		end
	end
	p modelTotalResult.to_s
end
=begin
strictModelAvgResult = strictModelAvgResult / Running_times.to_f
if (strictModelAvgResult<Thres)
	p "done! Strictest model suffice. Average result is "+strictModelAvgResult.to_s
else
	p "Strictest model gives bad result, average is "+strictModelAvgResult.to_s
end
=end