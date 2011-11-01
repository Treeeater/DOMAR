(function(){
Components.utils.import("resource://gre/modules/NetUtil.jsm");
Components.utils.import("resource://gre/modules/FileUtils.jsm");
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
	//find the first head or HEAD or body or BODY
	var insertIndex = response.toLowerCase().indexOf('<head>');
	if (insertIndex == -1) insertIndex = response.toLowerCase().indexOf('<body>');
	if (insertIndex > 0)
	{
		var headpos = insertIndex+6;
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
				var file = FileUtils.getFile("ProfD", ["DOMAR","DOMAR_preference.txt"]);
				if (file.exists()==false) file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);
				// open an input stream from file
				var istream = Components.classes["@mozilla.org/network/file-input-stream;1"].
					createInstance(Components.interfaces.nsIFileInputStream);
				istream.init(file, 0x01, 0444, 0);
				istream.QueryInterface(Components.interfaces.nsILineInputStream);
				// read lines into array
				var line = {}, lines = [], hasmore;
				do {
					hasmore = istream.readLine(line);
					lines.push(line.value); 
				} while(hasmore);
				istream.close();
				var modifythis = false;
				var i;
				for (i = 0; i < lines.length; i++)
				{
					//var url = request.originalURI.scheme+"://"+request.originalURI.host+request.originalURI.path;
					var domain = request.originalURI.scheme+"://"+request.originalURI.host;
					if (lines[i]==domain) 
					{
						modifythis = true;
						break;
					}
						
				}
                //if (request.originalURI.path.indexOf("yz8ra") > 0) {
				if (modifythis) {
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

//register an eventhandler at window.onunload to write ___record() to disk.
function writePolicy()
{
	var win=window.content.document.defaultView.wrappedJSObject;
	var url = win.document.URL;
	var domain = win.document.domain;
	if (url.indexOf("?")>0)
	{
		//Now we ignore the GET parameters
		url = url.substr(0,url.indexOf("?"));
	}
	urlfile = url.replace(/[^a-zA-Z0-9]/g,"");	//\W also does the trick.
	urlfile = urlfile.substr(0,63);						//restrict the file length
	domain = domain.replace(/[^a-zA-Z0-9]/g,"");
	domain = domain.substr(0,63);
	if (win.___record!=undefined)
	{
		var rawdata = win.___record();
		var historycount = 1;
		var file = FileUtils.getFile("ProfD", ["DOMAR","policy",domain,urlfile,"policy"+historycount+".txt"]);
		while (file.exists()==true) 
		{
			historycount++;
			file = FileUtils.getFile("ProfD", ["DOMAR","policy",domain,urlfile,"policy"+historycount+".txt"]);
		}
		file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);		//Create different file each time
		//policy extraction
		
		
		//done policy extraction
		// From here down: writing bytes to file. file is nsIFile, data is a string
		var rawstring = "";
		var i;
		for (i = 0; i < rawdata[0].length; i++)
		{
			//0 means DOM node accesses;
			rawstring = rawstring + "DOM Node access: ID = "+rawdata[0][i].when+" XPath = "+rawdata[0][i].what+"\n";
		}
		rawstring = rawstring + "\nEnd of DOM node access\n---------------------------------------\n";
		for (i = 0; i < rawdata[1].length; i++)
		{
			//1 means DOM node accesses;
			rawstring = rawstring + "window special property access: ID = "+rawdata[1][i].when+" Property = "+rawdata[1][i].what+"\n";
		}
		rawstring = rawstring + "\nEnd of window special property access\n---------------------------------------\n";
		for (i = 0; i < rawdata[2].length; i++)
		{
			//2 means DOM node accesses;
			rawstring = rawstring + "document special property access: ID = "+rawdata[2][i].when+" Property = "+rawdata[2][i].what+"\n";
		}
		rawstring = rawstring + "\nEnd of document special property access\n---------------------------------------\n";
		var data = rawstring;
		// You can also optionally pass a flags parameter here. It defaults to
		// FileUtils.MODE_WRONLY | FileUtils.MODE_CREATE | FileUtils.MODE_TRUNCATE;
		var ostream = FileUtils.openSafeFileOutputStream(file)

		var converter = Components.classes["@mozilla.org/intl/scriptableunicodeconverter"].
						createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
		converter.charset = "UTF-8";
		var istream = converter.convertToInputStream(data);

		// The last argument (the callback) is optional.
		NetUtil.asyncCopy(istream, ostream, function(status) {
		  if (!Components.isSuccessCode(status)) {
			// Handle error!
			return;
		  }

		  // Data has been written to the file.
		});
	}
}

//only register the eventhandler after page has been loaded, otherwise window.content is null.
window.addEventListener("DOMContentLoaded",function(){window.content.addEventListener('beforeunload',writePolicy,false);},false);
})();