def exportAllRecords(extractedRecords, hostD)
	pFolder = PRootDir+hostD
	cleanDirectory(pFolder)
	accessArray = extractedRecords.records
	accessArray.each_key{|tld|
		f = File.open(pFolder+tld+".txt","w")
		accessArray[tld].each{|xpath|
			f.puts (xpath)#+"|:=>"+accessArray[tld][xpath].to_s)
		}
		f.close()
	}
end

def buildStrictModel(accesses, tld)
	return StrictModel.new(accesses, tld)
end

def compareStrictModel(strictModel, aArray)
	#aArray is the actual new recordings, pArray is stored policies. Our job is to find the elements that's inside aArray but not inside pArray.
	diffArray = Array.new
	diff = false
	if (!aArray.key? strictModel.tld)
		#this particular test case does not include this src file. we skip and return 'same'.
		return 0
	end
	aArray[strictModel.tld].each{|what|
		if (!strictModel.accesses.include?(what))
			#This access has never happened before
			#This is illegal, record
			diff = true
			diffArray.push(what)
		end
	}
	if diff == true
		return diffArray
	else
		return 0
	end
end

def isTrainingData?(file,extractedRecords,rFolder)
	i = 0
	while (i < extractedRecords.trainingData.length)
		if (file == rFolder+"record"+extractedRecords.trainingData[i].to_s+".txt")
			return true
		end
		i+=1
	end
	return false
end

def checkStrictModel(strictModel, hostD, extractedRecords)
	pFolder = PRootDir+hostD
	rFolder = RRootDir+hostD
	testingFiles = Dir.glob(rFolder+"*")
	numberOfCheckedRecords = 0
	numberOfDifferentRecords = 0
	diffRecords = DiffRecords.new(Hash.new, 0.0)
	testingFiles.each{|file|
		fileNo = file.to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')
		if (isTrainingData?(file,extractedRecords,rFolder))
			#we cannot use training data to test the model
			next
		end
		numberOfCheckedRecords += 1
		accessArray = rLoad(file)
		diffArray = compareStrictModel(strictModel,accessArray)
		if (diffArray!=0)
			#There is difference in this record, we need to push into the diffRecords!
			numberOfDifferentRecords += 1
			diffRecords.records[fileNo] = diffArray
		end
	}
	if (numberOfCheckedRecords == 0)
		p "numberOfCheckedRecords is 0"
		exit -1
	end
	diffRecords.percentage = numberOfDifferentRecords/numberOfCheckedRecords.to_f
	return diffRecords
end