class ExtractedRecords
	attr_accessor :records, :trainingData
	def initialize(records, trainingData)
		@records = records
		@trainingData = trainingData
	end
end

class DiffRecords
	attr_accessor :records, :percentage
	def initialize(records, percentage)
		@records = records
		@percentage = percentage
	end
end