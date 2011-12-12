class AccessStructure
	attr_accessor :functionName, :xpath, :arguments
	def initialize(functionName, xpath, arguments)
		@functionName = functionName
		@xpath = xpath
		@arguments = arguments
	end
end

def learnRelaxedModel(strictModel)
	relaxedModel = RelaxedModel.new(Array.new, strictModel.tld)
	group = Hash.new
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
				suffix = access.gsub(/.*?\/.*?\s(.*)$/,'\1')
			end
			currentXPathStructure = currentXPath.gsub(/\[\d*?\]/,"")
			#tempAccessStructure = AccessStructure.new(prefix,currentXPath,suffix)
			if (group[prefix+currentXPathStructure+suffix] == nil)
				group[prefix+currentXPathStructure+suffix] = Array.new
				group[prefix+currentXPathStructure+suffix].push(index)
			else
				#trying to group the accesses
				group[prefix+currentXPathStructure+suffix].push(index)
			end
		end
	}
	group.each_value{|indexArray|
		#For each new structure
		indexArray.each{|index|
			#For each individual response in the same structure
			access = strictModel.accesses[index]
			currentXPath = ""
			if (access =~ /.*?\/.*?\s.*/)
				currentXPath = access.gsub(/.*?(\/.*?)\s.*/,'\1')
			else
				currentXPath = access.gsub(/.*?(\/.*)$/,'\1')
			end
			currentXPath = currentXPath[1, currentXPath.length]		#getting rid of the initial /
			while (currentXPath.length!=0)
				if (currentXPath.index('/')!=nil)
					capturedNode = currentXPath[0, currentXPath.index('/')]
					currentXPath = currentXPath[currentXPath.index('/')+1, currentXPath.length]
				else
					capturedNode = currentXPath
					currentXPath = ""
				end
				p capturedNode
				p currentXPath
			end
		}
	}
end