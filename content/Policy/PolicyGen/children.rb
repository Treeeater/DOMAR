def buildChildrenModel(accessArray,hostD)
	pFolder = PRootDir+hostD
	accessArray.each_key{|tld|
		f = File.open(pFolder+tld+".txt","w")
		accessArray[tld].each_key{|xpath|
			f.puts (xpath+"|:=>"+accessArray[tld][xpath].to_s)
		}
		f.close()
	}
end