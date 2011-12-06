def rLoad(requestRecordFile)
	#load from recordings of a single request into accessArray
	accessArray = Hash.new
	f = File.open(requestRecordFile, 'r')
	while (line = f.gets)
		line=line.chomp
		_wholoc = line.index(" |:=> ")
		if (_wholoc!=nil)
			_what = line[0, _wholoc]
			_who = line[_wholoc+1,line.length]
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
	f.close()
	return accessArray
end

def cleanDirectory(param)
	#cleans everything in param directory! Use extreme caution!
	Dir.foreach(param) do |f|
		if f == '.' or f == '..' then next 
		elsif File.directory?(param+f) then FileUtils.rm_rf(param+f)      
		else FileUtils.rm(param+f)
		end
	end 
end

def exportDiffArray(diffRecords, hostD)
	#store diffrecords into hard drive (CRootDir).
	cleanDirectory(CRootDir)
	diffRecords.records.each_key{|fileName|
		outputFileName = CRootDir+"diff"+fileName+".txt"
		outputFile = File.open(outputFileName, 'w')
		diffRecords.records[fileName].each_key{|tld|
			if (diffRecords.records[fileName][tld].length>0)
				outputFile.puts("-----"+tld+"------")
				diffRecords.records[fileName][tld].each{|what|
					outputFile.puts(what.to_s)
				}
			end
		}
		outputFile.close()
	}
end