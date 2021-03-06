#Change this to train different models
#HostDomain = "yelpcom"
#HostURL = "httpwwwyelpcomcharlottesvilleva"
#HostURL = "httpwwwyelpcomfairfaxva"
#HostURL = "httpwwwyelpcomuserdetails"
#HostDomain = "nytimescom"
#HostURL = "httpwwwnytimescompagestodayspaperindexhtml"
#HostURL = "httpwwwnytimescom"
#HostURL = "httpwwwnytimescom20111205technologyxboxlivechallengesthecablebo"
#HostURL = "httpthecaucusblogsnytimescom20120109daleytostepdownwhitehouseof"
HostDomain = "techcrunchcom"
#HostURL = "httptechcrunchcom"
#HostURL = "httptechcrunchcom20120113bloombergipad3tohavequadcorecpultehigh"
HostURL = "httptechcrunchcom20120202visualizingfacebooksmediastorehowbigis"
#HostDomain = "overstockcom"
#HostURL = "httpwwwoverstockcom"
#HostDomain = "slashdotorg"
#HostURL = "httpslashdotorg"
#HostDomain = "wsjcom"
#HostURL = "httpblogswsjcomdeals20120109freshlowforzyngashares"
#HostDomain = "neweggcom"
#HostURL = "httpwwwneweggcomProductProductaspx"
#HostDomain = "timecom"
#HostURL = "httpwwwtimecomtime"

#########################################################

P_inst = 0.05							#instrumentation frequency: when Alldomain is set to true, this maybe overriden to a higher value.
Thres = 0.1									#allowed maximum false positive
Alldomain = false							#allow the model builder to first scan all records and record all files that contain a previously unrecorded domain. Those files will be automatically considered in training phase.  *After discussing with Dave this option should be set to false all the time.*
Sequential = true							#set to true if we need to sample training data sequentially, i.e. 1, 2, 3....
MinRep = 5									#Only effective when Alldomain is set to true. Instead of having one representative for each domain, a minimum number of representatives are required for each domain.
Running_times = 1							#how many times we are going to run the whole program
StrictModelThreshold = 0.01					#the maximum accepted FP threshold per-page per-TLD.
RelaxedModelThreshold = 0					#the maximum accepted distance of indices to deem two records as the same
RelaxedModeEnabled = false					#to enable relaxed mode
DiffTolerance = 0							#Even if learnt model is integer, we still allow this number of differences in indices.