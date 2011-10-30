function TracingListener() {
    //this.receivedData = [];
}

if (typeof CCIN == "undefined") {
	function CCIN(cName, ifaceName){
		return Cc[cName].createInstance(Ci[ifaceName]);
	}
}

if (typeof CCSV == "undefined") {
	function CCSV(cName, ifaceName){
		if (Cc[cName])
			// if fbs fails to load, the error can be _CC[cName] has no properties
			return Cc[cName].getService(Ci[ifaceName]);
		else
			dump("CCSV fails for cName:" + cName);
	};
}
function modify(response)
{
	if (response.indexOf('<he'+'ad>') > 0)
	{
		var headpos = response.indexOf('<he'+'ad>')+6;
		var firstportion = response.substr(0,headpos);
		var lastportion = response.substr(headpos,response.length);
		var middleportion = "\n<script src='http://www.cs.virgin"+"ia.edu/~yz8ra/FFReplace.js'></scr"+"ipt>\n";
		var total = firstportion+middleportion+lastportion;
		return total;
	}
	else if (response.indexOf('<bo'+'dy>') > 0)
	{
		var headpos = response.indexOf('<bo'+'dy>')+6;
		var firstportion = response.substr(0,headpos);
		var lastportion = response.substr(headpos,response.length);
		var middleportion = "\n<script src='http://www.cs.virginia.edu"+"/~yz8ra/FFReplace.js'></scr"+"ipt>\n";
		var total = firstportion+middleportion+lastportion;
		return total;
	}
	else return response;
}
TracingListener.prototype =
{
    originalListener: null,
    receivedData: [],   // array for incoming data.

    onDataAvailable: function(request, context, inputStream, offset, count)
    {
        var binaryInputStream = CCIN("@mozilla.org/binaryinputstream;1", "nsIBinaryInputStream");
        var storageStream = CCIN("@mozilla.org/storagestream;1", "nsIStorageStream");
        binaryInputStream.setInputStream(inputStream);
        storageStream.init(8192, count, null);

        var binaryOutputStream = CCIN("@mozilla.org/binaryoutputstream;1",
                "nsIBinaryOutputStream");

        binaryOutputStream.setOutputStream(storageStream.getOutputStream(0));

        // Copy received data as they come.
        var data = binaryInputStream.readBytes(count);
        //var data = inputStream.readBytes(count);
        this.receivedData.push(data);
        //binaryOutputStream.writeBytes("abc", 3);
		data = modify(data);
		count = data.length;
		binaryOutputStream.writeBytes(data, count);
        this.originalListener.onDataAvailable(request, context, storageStream.newInputStream(0), offset, count);
		//this.originalListener.onDataAvailable(request, context, storageStream.newInputStream(0), offset, count);
    },

    onStartRequest: function(request, context) {
        this.receivedData = [];
        this.originalListener.onStartRequest(request, context);
    },

    onStopRequest: function(request, context, statusCode)
    {
        // Get entire response
        var responseSource = this.receivedData.join();
        this.originalListener.onStopRequest(request, context, statusCode);
    },

    QueryInterface: function (aIID) {
        if (aIID.equals(Ci.nsIStreamListener) ||
            aIID.equals(Ci.nsISupports)) {
            return this;
        }
        throw Components.results.NS_NOINTERFACE;
    },

}


hRO = {

    observe: function(request, aTopic, aData){
        try {
            if (typeof Cc == "undefined") {
                var Cc = Components.classes;
            }
            if (typeof Ci == "undefined") {
                var Ci = Components.interfaces;
            }
            if (aTopic == "http-on-examine-response") {
                request.QueryInterface(Ci.nsIHttpChannel);

                if (request.originalURI.path.indexOf("yz8ra") > 0) {
                    var newListener = new TracingListener();
                    request.QueryInterface(Ci.nsITraceableChannel);
                    newListener.originalListener = request.setNewListener(newListener);
                }
            } 
        } catch (e) {
            dump("\nhRO error: \n\tMessage: " + e.message + "\n\tFile: " + e.fileName + "  line: " + e.lineNumber + "\n");
        }
    },

    QueryInterface: function(aIID){
        if (typeof Cc == "undefined") {
            var Cc = Components.classes;
        }
        if (typeof Ci == "undefined") {
            var Ci = Components.interfaces;
        }
        if (aIID.equals(Ci.nsIObserver) ||
        aIID.equals(Ci.nsISupports)) {
            return this;
        }

        throw Components.results.NS_NOINTERFACE;

    },
};


var observerService = Cc["@mozilla.org/observer-service;1"]
    .getService(Ci.nsIObserverService);

observerService.addObserver(hRO,
    "http-on-examine-response", false);

//var doSomething = function (){if ((window.content.document.URL[0]!='a')&&(window.content.document.URL[0])!="") alert(window.content.document.URL);};

//window.addEventListener("DOMContentLoaded", doSomething, false);