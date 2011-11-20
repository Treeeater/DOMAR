require 'fileutils'

#PRootDir="../../../../DOMAR/policy/"	#root directory for generated policy
#RRootDir="../../../../DOMAR/records/"	#root directory for collected records.
PRootDir="C:/Users/Yuchen/Desktop/DOMAR/policy/"	#root directory for generated policy
RRootDir="C:/Users/Yuchen/Desktop/DOMAR/records/"	#root directory for collected records.

def getTLD(url)
	domain = url.gsub(/.*?\/\/(.*?)\/.*/,'\1')
	tld = domain.gsub(/.*\.(.*\..*)/,'\1')
	return tld
end

def pGen(hostD)
	pFolder = PRootDir+hostD
	accessArray = Hash.new
	hostDir = RRootDir+hostD
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
				_tld = getTLD(_who)
				if (accessArray[_tld]==nil)
					#2-level array
					accessArray[_tld] = Hash.new
				end
				accessArray[_tld][_what] = (accessArray[_tld][_what]==nil) ? 1 : accessArray[_tld][_what]+1
			end
		end
		f.close()
	}
	accessArray.each_key{|tld|
		f = File.open(pFolder+tld+".txt","w")
		accessArray[tld].each_key{|xpath|
			f.puts (xpath+"|:=>"+accessArray[tld][xpath].to_s)
		}
		f.close()
	}
end

#main program
hostDomain = ""
hostURL = ""
if ARGV.length==2
	#arguments provided
	hostDomain = ARGV[0]
	hostURL=ARGV[1]
elsif ARGV.length == 0
	puts "What is the intended host domain to generate policy?"
	hostDomain = gets.chomp
	puts "What is the intended host URL to generate policy?"
	hostURL = gets.chomp
else
	#puts "Either give me no arguments or give me two, the first one is host domain and the second one is third party domain. Other arguments are not accepted."
	#Process.exit
	hostDomain = "yelpcom"
	hostURL = "httpwwwyelpcomuserdetails/"
end
if (!File.directory? PRootDir) 
	Dir.mkdir(PRootDir)
end
if (!File.directory? PRootDir+hostDomain)
	Dir.mkdir(PRootDir+hostDomain)
end
if (!File.directory? PRootDir+hostDomain+"/"+hostURL)
	Dir.mkdir(PRootDir+hostDomain+"/"+hostURL)
end
pGen(hostDomain+"/"+hostURL)
