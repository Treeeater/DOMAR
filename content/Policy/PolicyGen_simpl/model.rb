class ExtractedRecords
	attr_accessor :records, :trainingData
	def initialize(records, trainingData)
		@records = records
		@trainingData = trainingData
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

class RelaxedModel										#accesses: learns the structures but ignore some of the numbers.
	attr_accessor :structure, :type, :tld				#type = 2
	def initialize(structure, tld)
		@structure = structure
		@type = 2
		@tld = tld
	end
end

class DiffRecords
	attr_accessor :records, :percentage
	def initialize(records, percentage)
		@records = records
		@percentage = percentage
	end
end