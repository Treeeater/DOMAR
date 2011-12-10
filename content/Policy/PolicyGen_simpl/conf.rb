#Change this to train different models
#HostDomain = "yelpcom"
#HostURL = "httpwwwyelpcomcharlottesvilleva"
#HostURL = "httpwwwyelpcomuserdetails"
#------------------------------------------------------
HostDomain = "nytimescom"
HostURL = "httpwwwnytimescom20111205technologyxboxlivechallengesthecablebo"
P_inst = 0.05								#instrumentation frequency: when Alldomain is set to true, this maybe overriden to a higher value.
Thres = 0.1									#allowed maximum false positive
Alldomain = true							#allow the model builder to first scan all records and record all files that contain a previously unrecorded domain. Those files will be automatically considered in training phase.
MinRep = 5									#Only effective when Alldomain is set to true. Instead of having one representative for each domain, a minimum number of representatives are required for each domain.
Running_times = 1							#how many times we are going to run the whole program