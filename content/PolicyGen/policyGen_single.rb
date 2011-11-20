PRootDir=ENV["Desktop"]+"DOMAR/policy/"	#root directory for generated policy
RRootDir=ENV["Desktop"]+"DOMAR/records/"	#root directory for collected records.

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def pGen(hostD, thirdPD)
	accessArray = Hash.new
	hostDir = RRootDir+hostD;
	files = Dir.glob(hostDir+"/*")
	files.each{|file|
		f = File.open(file, 'r')
		while (line = f.gets)
			line=line.chomp
			_whatloc = line.index(" What = ")
			_wholoc = line.index(" Who = ")
			if ((_whatloc!=nil)&&(_wholoc!=nil))
				_when = line[0,_whatloc]
				_what = line[_whatloc+1, _wholoc-_whatloc]
				_who = line[_wholoc+1,line.length]
				if (getTLD(_who)==thirdPD)
					#this is what we want to capture
					accessArray[_what] = (accessArray[_what]==nil) ? 1 : accessArray[_what]+1
				end
			end
		end
		puts accessArray
	}
	puts thirdPD
end

hostDomain = ""
thirdPDomain = ""
if ARGV.length==2
	#arguments provided
	hostDomain = ARGV[0]
	thirdPDomain = ARGV[1]
elsif ARGV.length == 0
	puts "What is the intended host domain to generate policy?"
	hostDomain = gets.chomp
	puts "What is the intended third party domain to generate policy?"
	thirdPDomain = gets.chomp
else
	#puts "Either give me no arguments or give me two, the first one is host domain and the second one is third party domain. Other arguments are not accepted."
	#Process.exit
	hostDomain = "yelpcom/httpwwwyelpcomuserdetailslists"
	thirdPDomain = "googleadservices.com"
end

pGen(hostDomain, thirdPDomain)
