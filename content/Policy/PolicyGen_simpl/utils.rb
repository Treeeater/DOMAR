#require 'amatch'

def relaxedCompare(what,accesses)
	#'what' is the acutal recording, accesses contains the model information
	#return false on a match
	if (accesses.include? what) 
		return false
	end
	whatstructure = what.gsub(/\[\d*\]/,'')
	whatIndex = what.gsub(/\]\//,'').gsub(/\[/,'').gsub(/\]$/,'').gsub(/\//,'1').split(/\D+/)
	accesses.each{|acc|
		matched = false
		accstructure = acc.gsub(/\[\d*\]/,'')
		if (accstructure == whatstructure)
=begin
			accArr = acc.split('/')
			accArrI = Array.new
			whatArrI = Array.new
			accArr.each{|a|
				temp = a.gsub(/.*\[(\d*)\]/,'\1')
				if (temp == a)
					accArrI.push(1)
				else
					accArrI.push(temp.to_i)
				end
			}
			whatArr = what.split('/')
			whatArr.each{|a|
				temp = a.gsub(/.*\[(\d*)\]/,'\1')
				if (temp == a)
					whatArrI.push(1)
				else
					whatArrI.push(temp.to_i)
				end
			}
=end
			accIndex = acc.gsub(/\]\//,'').gsub(/\[/,'').gsub(/\]$/,'').gsub(/\//,'1').split(/\D+/)
			min = DiffTolerance
			accIndex.each_index{|i|
				if (accIndex[i]!=whatIndex[i])
					min -= 1
					if (min < 0)
						break
					end
				end
			}
			if (min >= 0) 
				return false
			end
		end
	}
	return true
end

def permute_array(a)
	1.upto(a.length - 1) do |i|
		j = rand(i + 1)
		a[i], a[j] = a[j], a[i]
	end
	a
end

def rLoad(requestRecordFile, absolute)
	#load from recordings of a single request into accessArray
	accessArray = Hash.new
	f = File.open(requestRecordFile, 'r')
	if (absolute)
		while (line = f.gets)
			line=line.chomp
			_wholoc1 = line.index(" |:=> ")
			_wholoc2 = line.index(" <=:| ")
			if (_wholoc1!=nil)
				if (_wholoc2==nil)
					_what = line[0.. _wholoc1]
				else
					_what = line[_wholoc2+6.._wholoc1]
				end
				_who = line[_wholoc1+6..line.length]
				_tld = getTLD(_who)
				if (accessArray[_tld]==nil)
					#2-level array
					#accessArray[_tld] = Hash.new
					accessArray[_tld] = Array.new
				end
				#accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
				if (!accessArray[_tld].include? _what)
					accessArray[_tld].push(_what)
				end
			end
		end
	else
		while (line = f.gets)
			line=line.chomp
			_wholoc1 = line.index(" |:=> ")
			_wholoc2 = line.index(" <=:| ")
			if ((_wholoc1!=nil)&&(_wholoc2!=nil))
				_what = line[0.. _wholoc2]
				_who = line[_wholoc1+6..line.length]
				_tld = getTLD(_who)
				if (accessArray[_tld]==nil)
					#2-level array
					#accessArray[_tld] = Hash.new
					accessArray[_tld] = Array.new
				end
				#accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
				if (!accessArray[_tld].include? _what)
					accessArray[_tld].push(_what)
				end
			elsif ((_wholoc1!=nil)&&(_wholoc2==nil))
				#not a DOM related access
				_what = line[0.. _wholoc1]
				_who = line[_wholoc1+6..line.length]
				_tld = getTLD(_who)
				if (accessArray[_tld]==nil)
					#2-level array
					#accessArray[_tld] = Hash.new
					accessArray[_tld] = Array.new
				end
				#accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
				if (!accessArray[_tld].include? _what)
					accessArray[_tld].push(_what)
				end
			end
		end
	end
	f.close()
	return accessArray
end

def cleanDirectory(param)
	#cleans everything in param directory! Use extreme caution!
	if File.directory?(param)
		Dir.foreach(param) do |f|
			if f == '.' or f == '..' then next 
			elsif File.directory?(param+f) then FileUtils.rm_rf(param+f)      
			else FileUtils.rm(param+f)
			end
		end 
	end
end

def exportDiffArrayToFiles(diffRecords, hostD, tld)
	#store diffrecords into hard drive (CRootDir).
	#cleanDirectory(CRootDir)
	if (diffRecords.records.length == 0)
		return
	end
	if (!File.directory? CRootDir+tld)
		Dir.mkdir(CRootDir+tld)
	end
	diffRecords.records.each_key{|fileName|
		outputFileName = CRootDir+tld+"/diff"+fileName+".txt"
		outputFile = File.open(outputFileName, 'a')
		outputFile.puts("-----"+tld+"------")
		diffRecords.records[fileName].each{|what|
			outputFile.puts(what.to_s)
		}
		outputFile.close()
	}
end

def exportDiffArrayToSingleFile(diffRecords, hostD, tld, absolute)
	#store diffrecords into hard drive (CRootDir).
	#cleanDirectory(CRootDir)
	if (diffRecords.records.length == 0)
		return
	end
	outputFileName = ((absolute)? CRootDirA : CRootDirR)+tld+".txt"
	outputFile = File.open(outputFileName, 'w')
	diffRecords.records.each_key{|fileName|
		outputFile.puts("-----"+fileName+"------")
		diffRecords.records[fileName].each{|what|
			outputFile.puts(what.to_s)
		}
	}
	outputFile.close()
end