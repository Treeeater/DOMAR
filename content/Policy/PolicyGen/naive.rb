def exportStrictModel(extractedRecords, hostD)
	pFolder = PRootDir+hostD
	cleanDirectory(pFolder)
	accessArray = extractedRecords.records
	accessArray.each_key{|tld|
		f = File.open(pFolder+tld+".txt","w")
		accessArray[tld].each_key{|xpath|
			f.puts (xpath+"|:=>"+accessArray[tld][xpath].to_s)
		}
		f.close()
	}
end

def compareStrictModel(pArray, aArray)
	#aArray is the actual new recordings, pArray is stored policies. Our job is to find the elements that's inside aArray but not inside pArray.
	diffArray = Hash.new
	diff = false
	aArray.each_key{|tld|
		if (pArray[tld]==nil)
			#script from new source detected. We want to copy all accesses from this script to diff.
			diff = true
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
					diff = true
					diffArray[tld][what]=aArray[tld][what]
				end
			}
		end
	}
	if diff == true
		return diffArray
	else
		return 0
	end
end

def isTrainingData?(file,strictModel,rFolder)
	i = 0
	while (i < strictModel.trainingData.length)
		if (file == rFolder+"record"+strictModel.trainingData[i].to_s+".txt")
			return true
		end
		i+=1
	end
	return false
end

def checkStrictModel(strictModel, hostD)
	pFolder = PRootDir+hostD
	rFolder = RRootDir+hostD
	testingFiles = Dir.glob(rFolder+"*")
	numberOfCheckedRecords = 0
	numberOfDifferentRecords = 0
	diffRecords = DiffRecords.new(Hash.new, 0.0)
	testingFiles.each{|file|
		fileNo = file.to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')
		if (isTrainingData?(file,strictModel,rFolder))
			#we cannot use training data to test the model
			next
		end
		numberOfCheckedRecords += 1
		accessArray = rLoad(file)
		diffArray = compareStrictModel(strictModel.records,accessArray)
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