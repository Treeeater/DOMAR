require 'fileutils'
require_relative 'conf'
require_relative 'model'
require_relative 'utils'
require_relative 'naive'
require_relative 'children'


def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def probeXPATH(hostD)
	files = Dir.glob(hostD+"*")
	return File.read(files[0]).include?("<=:| ")
end

def getSequentialFile(hostD)
	#based on last modified date.
	returnList = Array.new
	hostDir = RRootDir+hostD
	files = Dir.glob(hostDir+"*")
	#p files
	#sorted_files = files.sort_by {|filename| File.mtime(filename) }
	#p sorted_files
	times = Array.new
	lookupTable = Hash.new
	files.each{|file|
		modtime = File.mtime(file)
		times.push(modtime)
		lookupTable[modtime]=file
	}
	times = times.sort
	#assuming file id is from 1 to N.
	numberOfRecords = Dir.entries(hostDir).length-2					#Total number of records
	numberOfTrainingSamples = (numberOfRecords * P_inst).round		#Total training cases
	i = 0
	while (i < numberOfTrainingSamples)
		fileNo = (lookupTable[times[i]].to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')).to_i
		returnList.push(fileNo)
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
				_who = line[_wholoc+6..line.length]
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
	accessHashA = Hash.new
	accessHashR = Hash.new
	rFolder = RRootDir+hostD
	files = Dir.glob(rFolder+"*")
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
=begin
			_scriptLocation = line.index(" <=|=> ")
			if (_scriptLocation!=nil)
				_who = line[0, _scriptLocation]
				_where = line[_scriptLocation+1,line.length]
				_tld = getTLD(_who)
			end
=end
			_wholoc1 = line.index(" |:=> ")
			_wholoc2 = line.index(" <=:| ")
			if (_wholoc1==nil)
				next
			end
			if (_wholoc2==nil)
				_whatA = line[0.._wholoc1]
				_who = line[_wholoc1+6..line.length]
				_tld = getTLD(_who)
				if (accessHashA[_tld]==nil)
					#2-level array
					#accessHash[_tld] = Hash.new
					accessHashA[_tld] = Array.new
				end
				#If we want to care about the number of accesses of each node, we uncomment the next line and make necessary changes
				#accessHash[_tld][_what] = (accessHash[_tld][_what]==nil) ? 1 : accessHash[_tld][_what]+1
				if (!accessHashA[_tld].include? _whatA)
					accessHashA[_tld].push(_whatA)
				end
				if (line[0]!='/')
					#not DOM node access, but we still need to push it to relative model.
					if (accessHashR[_tld]==nil)
						accessHashR[_tld] = Array.new
					end
					if (!accessHashR[_tld].include? _whatA)
						accessHashR[_tld].push(_whatA)
					end
				end
			else
				#relative XPATH
				_whatR = line[0.._wholoc2]
				_whatA = line[_wholoc2+6.._wholoc1]
				_who = line[_wholoc1+6..line.length]
				_tld = getTLD(_who)
				if (accessHashR[_tld]==nil)
					accessHashR[_tld] = Array.new
				end
				if (accessHashA[_tld]==nil)
					accessHashA[_tld] = Array.new
				end
				if (!accessHashR[_tld].include? _whatR)
					accessHashR[_tld].push(_whatR)
				end
				if (!accessHashA[_tld].include? _whatA)
					accessHashA[_tld].push(_whatA)
				end
			end
		end
		f.close()
	end
	p "done learning basic model."
	j = 0
	tldsDetails = Hash.new
	files.each{|file|
		j = j + 1
		f = File.open(file, 'r')
		while (line = f.gets)
			line=line.chomp
			_wholoc = line.index(" |:=> ")
			if (_wholoc!=nil)
				_who = line[_wholoc+6..line.length]
				_tld = getTLD(_who)
				i = (file.to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')).to_i
				if (!tldsDetails.key? _tld) 
					tldsDetails[_tld] = Array.new
					tldsDetails[_tld].push(i)
				else
					#if (!tldsDetails[_tld].include? i)
						#performance reasons: this significantly slows down the process, making it O(N2) instead of linear.
						#memory is not a issue, we just gonna push the elements.
						tldsDetails[_tld].push(i)
					#end
				end
			end
		end
		f.close()
	}
	tldsDetails.each_key{|_tld|
		tldsDetails[_tld] = tldsDetails[_tld].uniq
	}
	p "done extracting all tlds."
	#sort accessHash in an alphebatically order
	accessHashA.each_key{|_tld|
		accessHashA[_tld] = accessHashA[_tld].sort
	}
	accessHashR.each_key{|_tld|
		accessHashR[_tld] = accessHashR[_tld].sort
	}
	p "done sorting all tlds."
	temp = ExtractedRecords.new(accessHashR, accessHashA, indexOfTrainingSamples, tldsDetails)
	return temp
end

#main training program
hostDomain = ""
hostURL = ""
if ARGV.length==1
	#arguments provided
	domainOfInterest = ARGV[0]
	hostDomain = HostDomain
	hostURL = HostURL
=begin
elsif ARGV.length == 0
	puts "What is the intended host domain to generate policy?"
	hostDomain = gets.chomp
	puts "What is the intended host URL to generate policy?"
	hostURL = gets.chomp
=end
else
	#puts "Either give me no arguments or give me two, the first one is host domain and the second one is third party domain. Other arguments are not accepted."
	#Process.exit
	domainOfInterest = ""			#interested in all domains
	hostDomain = HostDomain
	hostURL = HostURL
end
if (!File.directory? PRootDirA) 
	Dir.mkdir(PRootDirA)
end
if (!File.directory? PRootDirR) 
	Dir.mkdir(PRootDirR)
end
if (!File.directory? PRootDirA+hostDomain)
	Dir.mkdir(PRootDirA+hostDomain)
end
if (!File.directory? PRootDirR+hostDomain)
	Dir.mkdir(PRootDirR+hostDomain)
end
workingDir = hostDomain+"/"+hostURL+"/"
if (!File.directory? PRootDirA+workingDir)
	Dir.mkdir(PRootDirA+workingDir)
end
if (!File.directory? PRootDirR+workingDir)
	Dir.mkdir(PRootDirR+workingDir)
end
if (!File.directory? CRootDirR)
	Dir.mkdir(CRootDirR)
end
if (!File.directory? CRootDirA)
	Dir.mkdir(CRootDirA)
end
if (File.directory? PRootDirA+workingDir+"relaxed/")
	cleanDirectory(PRootDirA+workingDir+"relaxed/")
end
if (File.directory? PRootDirR+workingDir+"relaxed/")
	cleanDirectory(PRootDirR+workingDir+"relaxed/")
end
puts ""
puts "Initialized directory configuration, starting to run model building..."
puts ""
cleanDirectory(CRootDirA)
cleanDirectory(CRootDirR)
puts "Cleaned diff dir..."
#For now we make sure training data includes traces from all possible sources.
#necessaryFileList = Alldomain ? getNecessaryFile(workingDir) : Array.new
relativeXPATH = probeXPATH(RRootDir+workingDir)
p relativeXPATH
#
for i in (1..Running_times)
	modelTotalResult = 1.0
	puts "Running for the #{i}th time"
	#necFileList = Alldomain ? necessaryFileList : Array.new
	necFileList = Alldomain ? getNecessaryFile(workingDir) : (Sequential ? getSequentialFile(workingDir) : Array.new)
	extractedRecords = extractRecordsFromTrainingData(workingDir, necFileList)
	exportPolicy(extractedRecords,workingDir)
	model = Model.new
	tlds = Array.new
	p "done extracting records."
	p "Absolute Results:"
	p ""
	extractedRecords.recordsA.each_key{|tld|
		if ((domainOfInterest!="")&&(domainOfInterest!=tld)) 
			next
		end
		tempModel = buildStrictModel(extractedRecords.recordsA[tld], tld) 	#strictest model is actually just extractedRecord
		strictModelTestResult = checkStrictModel(tempModel, workingDir, extractedRecords, true)
		if ((strictModelTestResult.percentage > StrictModelThreshold) && (RelaxedModeEnabled))
			#we need a more relaxed model
			relaxedModel = learnRelaxedModel(tempModel)
			exportRelaxedModel(relaxedModel, workingDir)
			relaxedModelTestResult = checkRelaxedModel(relaxedModel, workingDir, extractedRecords, strictModelTestResult)
			modelTotalResult *= (1-relaxedModelTestResult.percentage)
			p "Relaxed Model : Difference at #{tld} domain is :"
			p relaxedModelTestResult.percentage.to_s
			model.adoptTLD(tld,relaxedModel)
			exportDiffArrayToSingleFile(relaxedModelTestResult, workingDir, tld, true)
		else
			modelTotalResult *= (1-strictModelTestResult.percentage)
			model.adoptTLD(tld,tempModel)
			exportDiffArrayToSingleFile(strictModelTestResult, workingDir, tld, true)
		end
		p "Strict Model : Difference at #{tld} domain is :"
		p strictModelTestResult.percentage.to_s
		tlds.push tld			#to record what tld(s) have been checked.
		#exportDiffArray(strictModelTestResult, workingDir, tld)
	}
	p ""
	p ""
	if (relativeXPATH)
		p "Relative Results:"
		extractedRecords.recordsR.each_key{|tld|
			if ((domainOfInterest!="")&&(domainOfInterest!=tld)) 
				next
			end
			tempModel = buildStrictModel(extractedRecords.recordsR[tld], tld) 	#strictest model is actually just extractedRecord
			strictModelTestResult = checkStrictModel(tempModel, workingDir, extractedRecords, false)
			if ((strictModelTestResult.percentage > StrictModelThreshold) && (RelaxedModeEnabled))
				#we need a more relaxed model
				relaxedModel = learnRelaxedModel(tempModel)
				exportRelaxedModel(relaxedModel, workingDir)
				relaxedModelTestResult = checkRelaxedModel(relaxedModel, workingDir, extractedRecords, strictModelTestResult)
				modelTotalResult *= (1-relaxedModelTestResult.percentage)
				p "Relaxed Model : Difference at #{tld} domain is :"
				p relaxedModelTestResult.percentage.to_s
				model.adoptTLD(tld,relaxedModel)
				exportDiffArrayToSingleFile(relaxedModelTestResult, workingDir, tld, false)
			else
				modelTotalResult *= (1-strictModelTestResult.percentage)
				model.adoptTLD(tld,tempModel)
				exportDiffArrayToSingleFile(strictModelTestResult, workingDir, tld, false)
			end
			p "Strict Model : Difference at #{tld} domain is :"
			p strictModelTestResult.percentage.to_s
			tlds.push tld			#to record what tld(s) have been checked.
			#exportDiffArray(strictModelTestResult, workingDir, tld)
		}
	end
	if ((!Alldomain)&&(domainOfInterest==""))
		#if alldomain option is off, we need to check if any other domain exists besides the domains existing in training data.
		p "All domain is set to false, we will check for potential domain lost in training data..."
		flag = false
		extractedRecords.tldsDetails.each_key{|tld|
			if (!extractedRecords.recordsA.keys.include? tld)
				p tld + " not found in training data."
				p "total numbers of records containing this domain is " + extractedRecords.tldsDetails[tld].length.to_s
				if (extractedRecords.tldsDetails[tld].length<100)
					p "they are:" + extractedRecords.tldsDetails[tld].to_s
				else
					p "too many of them, won't emnumerate here."
				end
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