class AccessStructure
	attr_accessor :functionName, :xpath, :arguments
	def initialize(functionName, xpath, arguments)
		@functionName = functionName
		@xpath = xpath
		@arguments = arguments
	end
end

class Assist
	attr_accessor :indexA, :prefix, :suffix
	def initialize(indexA, prefix, suffix)
		@indexA = indexA
		@prefix = prefix
		@suffix = suffix
	end
end

def exportRelaxedModel(relaxedModel, workingDir)
	if (!File.directory? PRootDir+workingDir+"relaxed")
		Dir.mkdir(PRootDir+workingDir+"relaxed")
	end
	f = File.open(PRootDir+workingDir+"relaxed/"+relaxedModel.tld+".txt","w")
	relaxedModel.structure.each{|access|
		f.puts (access)
	}
	f.close()
end

def learnRelaxedModel(strictModel)
	relaxedModelData = Array.new						#basically an array of strings, the strings indicates the details of the accesses
	group = Hash.new
	relaxedModelHash = Hash.new							#key: prefix+xpath w/o index+suffix; value: an array with a list of indices
	prefixArray = Hash.new
	suffixArray = Hash.new
	strictModel.accesses.each_index{|index|
		access = strictModel.accesses[index]
		if (access =~ /\//)
			#This access involves DOM nodes with XPATH
			prefix = ""
			currentXPath = ""
			suffix = ""
			if (access =~ /\/.*/)
				prefix = access.gsub(/(\/.*)/,"")
			end
			if (access =~ /.*?\/.*?\s.*/)
				currentXPath = access.gsub(/.*?(\/.*?)\s.*/,'\1')
			else
				currentXPath = access.gsub(/.*?(\/.*)$/,'\1')
			end
			if (access =~ /.*?\/.*?\s.*$/)
				suffix = access.gsub(/.*?\/.*?(\s.*)$/,'\1')
			end
			currentXPathStructure = currentXPath.gsub(/\[\d*?\]/,"")
			#tempAccessStructure = AccessStructure.new(prefix,currentXPath,suffix)
			if (group[prefix+currentXPathStructure+suffix] == nil)
				group[prefix+currentXPathStructure+suffix] = Assist.new(Array.new, prefix, suffix)
				group[prefix+currentXPathStructure+suffix].indexA.push(index)
			else
				#trying to group the accesses
				group[prefix+currentXPathStructure+suffix].indexA.push(index)
			end
		else
			#this access does not involve DOM node access, we simply forward it as we did in strict model
			relaxedModelData.push(access)
		end
	}
	group.each_value{|indexArray|
		#For each new structure
		xpathArray = Array.new					#temp array variable to hold each node info, e.g. "DIV[2]"
		diffXPath = Array.new					#temp array variable to hold the number, e.g. "2"
		diff = Array.new						#temp array variable to hold if the current number fluctuates.
		nodeType = Array.new					#temp array var used to reconstruct the old access structure.
		numberOfRecords = 0.0
		reconstructedAccess = ""
		indexArray.indexA.each{|index|
			#For each individual response in the same structure
			access = strictModel.accesses[index]
			currentXPath = ""
			if (access =~ /.*?\/.*?\s.*/)
				currentXPath = access.gsub(/.*?(\/.*?)\s.*/,'\1')
			else
				currentXPath = access.gsub(/.*?(\/.*)$/,'\1')
			end
			currentXPath = currentXPath[1, currentXPath.length]		#getting rid of the initial /
			currentDepth = 0			
			while (currentXPath.length!=0)							#how deep current node is
				if (currentXPath.index('/')!=nil)
					capturedNode = currentXPath[0, currentXPath.index('/')]
					currentXPath = currentXPath[currentXPath.index('/')+1, currentXPath.length]
				else
					capturedNode = currentXPath
					currentXPath = ""
				end
				if (capturedNode.index('[')==nil)
					xpathArray[currentDepth] = (xpathArray[currentDepth]==nil) ? 1 : xpathArray[currentDepth]+1
					nodeType[currentDepth] = capturedNode
					if (diffXPath[currentDepth] == nil)
						diffXPath[currentDepth] = 1
					elsif (diffXPath[currentDepth] != 1)
						diff[currentDepth] = true
					end
				else
					temp = capturedNode.gsub(/.*\[(\d+)\]/,'\1').to_i
					xpathArray[currentDepth] = (xpathArray[currentDepth]==nil) ? temp : xpathArray[currentDepth]+temp
					nodeType[currentDepth] = capturedNode.gsub(/(.*)\[\d+\]/,'\1')
					if (diffXPath[currentDepth] == nil)
						diffXPath[currentDepth] = temp
					elsif (diffXPath[currentDepth] != temp)
						diff[currentDepth] = true
					end
				end
				currentDepth += 1
			end
			numberOfRecords += 1.0
		}
		xpathArray2 = Array.new
		xpathArray.each_index{|ind|
			xpathArray[ind] /= numberOfRecords
			if (diff[ind]==true)
				#if index of a certain node fluctuates, we are going to compute the average index and store it.  The stored form is a float with only one extra precision
				reconstructedAccess = reconstructedAccess + "/" + nodeType[ind] + "[" + xpathArray[ind].round(1).to_s + "]"
				xpathArray2.push(xpathArray[ind].round(1))
			elsif (xpathArray[ind]==1)
				#otherwise if the node's index is fixed, we just store the integer value of that position
				reconstructedAccess = reconstructedAccess + "/" + nodeType[ind]
				xpathArray2.push(1)
			else
				reconstructedAccess = reconstructedAccess + "/" + nodeType[ind] + "[" + xpathArray[ind].round().to_s + "]"
				xpathArray2.push(xpathArray[ind].round())
			end
			#reconstruct the access string
		}
		temp = ""
		nodeType.each{|t|
			temp = temp + "/" + t
		}
		relaxedModelData.push(indexArray.prefix + reconstructedAccess + indexArray.suffix)
		relaxedModelHash[indexArray.prefix + temp + indexArray.suffix] = xpathArray2
		#p relaxedModelHash
	}
	relaxedModel = RelaxedModel.new(relaxedModelData, relaxedModelHash, strictModel.tld)
end

def compareRelaxedModel(relaxedModel, accessArray)
	#accessArray is the actual new recordings, relaxedModel is stored policies. Our job is to find the elements that's inside aArray but not inside pArray.
	diffArray = Array.new
	diff = false
	if (!accessArray.key? relaxedModel.tld)
		#this particular test case does not include this src file. we skip and return 'same'.
		return 0
	end
	accessArray[relaxedModel.tld].each{|what|
		if (what =~ /\//)
			#accesses that do involve DOM node XPATH
			prefix = ""
			currentXPath = ""
			suffix = ""
			if (what =~ /\/.*/)
				prefix = what.gsub(/(\/.*)/,"")
			end
			if (what =~ /.*?\/.*?\s.*/)
				currentXPath = what.gsub(/.*?(\/.*?)\s.*/,'\1')
			else
				currentXPath = what.gsub(/.*?(\/.*)$/,'\1')
			end
			if (what =~ /.*?\/.*?\s.*$/)
				suffix = what.gsub(/.*?\/.*?(\s.*)$/,'\1')
			end
			currentXPathStructure = currentXPath.gsub(/\[\d*?\]/,"")
			if (relaxedModel.relaxedModelHash[prefix+currentXPathStructure+suffix]==nil)
				#this structure is never seen, we should report this
				#p "never seen this structure before"
				diff = true
				diffArray.push(what + ", structural differences.")
			else
				#we have seen this structure, now we need to look at the indices closer.
				policyArray = relaxedModel.relaxedModelHash[prefix+currentXPathStructure+suffix]		#the array indices we learned in our model
				currentXPath = currentXPath[1, currentXPath.length]		#getting rid of the initial '/'
				currentArray = Array.new								#the actual recorded array
				while (currentXPath.length!=0)							#how deep current node is
					if (currentXPath.index('/')!=nil)
						capturedNode = currentXPath[0, currentXPath.index('/')]
						currentXPath = currentXPath[currentXPath.index('/')+1, currentXPath.length]
					else
						capturedNode = currentXPath
						currentXPath = ""
					end
					if (capturedNode.index('[')==nil)
						currentArray.push(1)
					else
						temp = capturedNode.gsub(/.*\[(\d+)\]/,'\1').to_i
						currentArray.push(temp)
					end
				end
				if (policyArray.length!=currentArray.length)
					p "error! policy array length is not equal to currentArray length"
					exit 0
				else
					policyArray.each_index{|i|
						if (policyArray[i].to_i.to_s==policyArray[i].to_s)
							#policyArray is integer, we should not apply relaxed checking here
							if (policyArray[i]!=currentArray[i])
								diff = true
								diffArray.push(what + ", difference happens at index #{i}, because relaxed model learnt is strict on this access (consistent).")
								break
							end
						elsif ((policyArray[i]-currentArray[i]).abs>RelaxedModelThreshold)
							#p "violation still happens at threshold = #{RelaxedModelThreshold}, current diff is #{(policyArray[i]-currentArray[i]).abs}"
							diff = true
							diffArray.push(what + ", difference happens at index #{i}, difference is #{(policyArray[i]-currentArray[i]).abs.round()}.")
							break
						end
					}
				end
			end
		else
			#accesses that do not involve DOM node XPATH are considered the same as the strict model
			if (!relaxedModel.structure.include? what)
				diff = true
				diffArray.push(what)
			end
		end
	}
	if diff == true
		#p "this access cannot pass both rounds"
		return diffArray
	else
		#p "this access cannot pass first round but passed second round"
		return 0
	end
end

def checkRelaxedModel(relaxedModel, workingDir, extractedRecords, strictModelTestResult)
	pFolder = PRootDir+workingDir
	rFolder = RRootDir+workingDir
	testingFiles = Dir.glob(rFolder+"*")
	numberOfCheckedRecords = 0
	numberOfDifferentRecords = 0
	diffRecords = DiffRecords.new(Hash.new, 0.0, Array.new)
	testingFiles.each{|file|
		fileNo = file.to_s.chomp.gsub(/.*record(\d*)\.txt$/,'\1')
		if (isTrainingData?(file,extractedRecords,rFolder))
			#we cannot use training data to test the model
			next
		end
		if (!strictModelTestResult.diffFileNo.include? fileNo)
			#we don't deal with files that already passed first round
			numberOfCheckedRecords += 1			# but we still did this right.
			next
		end
		numberOfCheckedRecords += 1
		accessArray = rLoad(file)
		diffArray = compareRelaxedModel(relaxedModel,accessArray)
		if (diffArray!=0)
			#There is difference in this record, we need to push into the diffRecords!
			numberOfDifferentRecords += 1
			diffRecords.records[fileNo] = diffArray
			diffRecords.diffFileNo.push(fileNo)
		end
	}
	if (numberOfCheckedRecords == 0)
		p "numberOfCheckedRecords is 0"
		exit -1
	end
	diffRecords.percentage = numberOfDifferentRecords/numberOfCheckedRecords.to_f
	return diffRecords
end