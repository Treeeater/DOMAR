class ExtractedRecords
	attr_accessor :recordsR, :recordsA, :trainingData, :tldsDetails
	def initialize(recordsR, recordsA, trainingData, tldsDetails)
		@recordsR = recordsR
		@recordsA = recordsA
		@trainingData = trainingData
		@tldsDetails = tldsDetails
	end
end

class Model
	attr_accessor :model						#model should be an hashmap with keys being the TLDs.
	def initialize(model)
		@model = model
	end
	def initialize()
		@model = Hash.new
	end
	def adoptTLD(tld,tempmodel)
		@model[tld] = tempmodel					#tempmodel: other model classes defined here.
	end
end

class StrictModel										#accesses: just all the accesses seen.
	attr_accessor :accesses, :type, :tld				#type = 1
														#accesses: Array
	def initialize(accesses, tld)
		@accesses = accesses
		@type = 1
		@tld = tld
	end
end

class RelaxedModel														#learns the structures but ignore some of the numbers.
	attr_accessor :structure, :relaxedModelHash, :type, :tld			#type = 2 structure: string data. relaxedModelHash: see children.rb
	def initialize(structure, relaxedModelHash, tld)
		@structure = structure
		@relaxedModelHash = relaxedModelHash
		@type = 2
		@tld = tld
	end
end

class DiffRecords
	attr_accessor :records, :percentage, :diffFileNo
	def initialize(records, percentage, diffFileNo)
		@records = records
		@percentage = percentage
		@diffFileNo = diffFileNo
	end
end