(function(){
Components.utils.import("resource://gre/modules/NetUtil.jsm");
Components.utils.import("resource://gre/modules/FileUtils.jsm");
var startTime;
var endTime;

//getXPath necessities
//These need to be here because getXPath relies on this.
var oldParentNode = Element.prototype.__lookupGetter__('parentNode');
var oldNextSibling = Element.prototype.__lookupGetter__('nextSibling');
var oldPreviousSibling = Element.prototype.__lookupGetter__('previousSibling');

//XPATH getter: usage: getXPath(document.getElementById('something'))
/*
//this one uses jQuery, however jQuery uses nextSibling. dead lock.

function getXPath( element )
{
    var xpath = '';
	if (element)
	{
		if (element.item)		
		{
			//this is a collection, we return all xpaths accessed, separated by semicolons.
			var i = 0;
			for (; i < element.length; i++)
			{
				cur_element = element.item(i);
				cur_xpath = '';
				for ( ; cur_element && cur_element.nodeType == 1; cur_element = oldParentNode.apply(cur_element) )
				{
					var id = $(oldParentNode.apply(cur_element)).children(cur_element.tagName).index(cur_element) + 1;
					id > 1 ? (id = '[' + id + ']') : (id = '');
					cur_xpath = '/' + cur_element.tagName.toLowerCase() + id + cur_xpath;
				}
				xpath += cur_xpath + ';';
			}
		}
		else {
			//this is an element
			for ( ; element && element.nodeType == 1; element = oldParentNode.apply(element) )
			{
				var id = $(oldParentNode.apply(element)).children(element.tagName).index(element) + 1;
				id > 1 ? (id = '[' + id + ']') : (id = '');
				xpath = '/' + element.tagName.toLowerCase() + id + xpath;
			}
		}
		return xpath;
	}
};	*/
var getXPath = function(elt)
{
     var path = "";
     for (; elt && (elt.nodeType == 1||elt.nodeType == 3||elt.nodeType == 2); elt = oldParentNode.apply(elt))
     {
		idx = getElementIdx(elt);
		if (elt.nodeType ==1) xname = elt.tagName;
		else if (elt.nodeType == 3) xname = "TEXT";
		else if (elt.nodeType == 2) xname = "ATTR";
		if (idx > 1) xname += "[" + idx + "]";
		path = "/" + xname + path;
     }
	 //if ((path=="")&&(elt!=null)) alert(elt);		//for debug purposes.
     if (path.substr(0,5)!="/HTML") return "";		//right now, if this node is not originated from HTMLDocument (e.g., some script calls createElement which does not contain any private information, we do not record this access.
	 return path;
};

var getElementIdx = function(elt)
{
    var count = 1;
	if (elt.nodeType==1)
	{
		for (var sib = oldPreviousSibling.apply(elt); sib ; sib = oldPreviousSibling.apply(sib))
		{
			if(sib.nodeType == 1 && sib.tagName == elt.tagName)	count++;
		}
	}
	else if (elt.nodeType==3)
	{
		for (var sib = oldPreviousSibling.apply(elt); sib ; sib = oldPreviousSibling.apply(sib))
		{
			if(sib.nodeType == 3)	count++;
		}
	}
	else if (elt.nodeType==2)
	{
		for (var sib = oldPreviousSibling.apply(elt); sib ; sib = oldPreviousSibling.apply(sib))
		{
			if(sib.nodeType == 2)	count++;
		}
	}
    return count;
};
//end of getXPath necessities

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
function detect_response_beginning(response)
{
	//sometimes responses are divided into chunks, we only want to modify the beginning of the response.
	if ((response.match(/^\s*<[hH]/)!=null)||(response.match(/^\s*<!DOCTYPE/i)!=null)) return true;
	else return false;
}
function if_already_modified(response)
{
	//sometimes responses are divided into chunks, we only want to modify the beginning of the response.
	if (response.match(/FFReplace/)) return true;
	else return false;
}
function getTrustedDomain(domain)
{
	Components.utils.import("resource://gre/modules/NetUtil.jsm");
	Components.utils.import("resource://gre/modules/FileUtils.jsm");
	var file = FileUtils.getFile("Desk", ["DOMAR","site_preferences",domain+".txt"]);
	if (file.exists()==false) {console.log("No trusted domains registered for this site!"); return []};
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
	return lines;
}
function modify(response,trustedDomains)
{
	if (!detect_response_beginning(response)) return response;
	if (if_already_modified(response)) return response;
	//FIXED:find the first head or HEAD or body or BODY, currently we do not deal with <head some attribute> case. That is trivial but i'm too lazy to do it.
	var lowerResponse = response.toLowerCase();
	var insertIndex = lowerResponse.indexOf('<head');
	if (insertIndex == -1) insertIndex = lowerResponse.indexOf('<body');
	insertIndex = lowerResponse.indexOf('>',insertIndex);
	if (insertIndex > 0)
	{
		startTime = new Date().getTime();
		if (!mainControl.getStatus()) {
			return response;
		}
		var headpos = insertIndex+1;
		var firstportion = response.substr(0,headpos);
		var lastportion = response.substr(headpos,response.length);
		//var middleportion = "<script src='http://www.cs.virginia.edu/~yz8ra/FFReplace.js'></script>";
		var middleportion = "<script src='http://127.0.0.1/FFReplace_simpl.js'></script><script>";
		while (trustedDomains.length>0)
		{
			middleportion = middleportion + "__record().Push(\"" + trustedDomains.pop() + "\");\n";
		}
		middleportion = middleportion + "__record().Push(\"127.0.0.1\");</script>";
		//var middleportion = "\n<script src='chrome://domar/content/FFReplace.js'></script>\n";	//This will not work.
		var total = firstportion+middleportion+lastportion;
		return total;
	}
	/*customized modification*/
	/*
	if (response.indexOf('http://ajax.googleapis.com/ajax/libs/jquery/1.4.0/jquery.min.js'))
	{
		var s = response.indexOf('http://ajax.googleapis.com/ajax/libs/jquery/1.4.0/jquery.min.js');
		response = response.replace(/http:\/\/ajax\.googleapis\.com\/ajax\/libs\/jquery\/1\.4\.0\/jquery\.min\.js/, 
		"http://www.cs.virginia.edu/~yz8ra/jquery-1.4.js");
		return response;
	}
	*/
	/*end of customization*/
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
		var domain = request.originalURI.host.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
		domain = domain.replace(/[^a-zA-Z0-9]/g,"");
		domain = domain.substr(0,63);
		var trustedDomains = getTrustedDomain(domain);
		data = modify(data,trustedDomains);
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

function isLegitURL(url){
	var legitSuffix = ["js","css","jpg","gif","png","ico"];
	var i = 0;
	for (; i<legitSuffix.length;i++)
	{
		if (url.substr(url.length-legitSuffix[i].length,url.length)==legitSuffix[i]) return false;
	}
	return true;
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
				var file = FileUtils.getFile("Desk", ["DOMAR","DOMAR_preference.txt"]);
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
				var url = request.originalURI.scheme+"://"+request.originalURI.host+request.originalURI.path;
				//var domain = request.originalURI.scheme+"://"+request.originalURI.host;
				var domain = request.originalURI.host;
				domain = domain.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
				//only works if domain does not use direct ip. For example, 192.168.0.1 -> 0.1
				for (i = 0; i < lines.length; i++)
				{
					if ((lines[i]==domain)&&(isLegitURL(url)))
					{
						//alert(url+" , "+domain);
						//Do not modify js requests! This will mess up a lot of sites!
						modifythis = true;
						break;
					}
				}
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
	if (!mainControl.getStatus()) {return;}
	var win=window.content.document.defaultView.wrappedJSObject;
	if (win.___record==undefined) return;
	var url = win.document.URL;
	var domain = win.document.domain;
	domain = domain.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
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
		var i;
		var rawdata = win._record.getRecord();
		var historycount = 1;
		var file = FileUtils.getFile("Desk", ["DOMAR","records",domain,urlfile,"record"+historycount+".txt"]);
		while (file.exists()==true) 
		{
			historycount++;
			file = FileUtils.getFile("Desk", ["DOMAR","records",domain,urlfile,"record"+historycount+".txt"]);
		}
		file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);		//Create different file each time
		//policy extraction
		/*
		var j = 0;
		for (j = 0; j < rawdata[0].length; j++)
		{
			raw = rawdata[0][j].who.replace(/(.*?)\/\/(.*?)\/(.*)/,"$2");
			raw = raw.replace(/(.*?)\/\/(.*)/,"$2");
			raw = raw.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
			for (i = 0; i < trustedDomains.length; i++)
			{
				if (trustedDomains[i]==raw) rawdata[0][j].who = "trusted";
			}
		}
		for (j = 0; j < rawdata[1].length; j++)
		{
			raw = rawdata[1][j].who.replace(/(.*?)\/\/(.*?)\/(.*)/,"$2");
			raw = raw.replace(/(.*?)\/\/(.*)/,"$2");
			raw = raw.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
			for (i = 0; i < trustedDomains.length; i++)
			{
				if (trustedDomains[i]==raw) rawdata[1][j].who = "trusted";
			}
		}
		for (j = 0; j < rawdata[2].length; j++)
		{
			raw = rawdata[2][j].who.replace(/(.*?)\/\/(.*?)\/(.*)/,"$2");
			raw = raw.replace(/(.*?)\/\/(.*)/,"$2");
			raw = raw.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
			for (i = 0; i < trustedDomains.length; i++)
			{
				if (trustedDomains[i]==raw) rawdata[2][j].who = "trusted";
			}
		}*/
		//done policy extraction
		// From here down: writing bytes to file. file is nsIFile, data is a string
		var rawstring = "";
		for (i = 0; i < rawdata[0].length; i++)
		{
			//0 means DOM node accesses;
			if ((rawdata[0][i].what!="")&&(rawdata[0][i].who!="trusted"))
			{
				//Rigth now we only track accesses on element node, text node and attribute node. If the node is 'others', xpath is gonna return "",
				//so we ignore it here.
				//We also ignore sequence info now.
				//rawstring = rawstring + "When = "+rawdata[0][i].when+" What = "+rawdata[0][i].what+" Who = "+rawdata[0][i].who+"\n";
				rawstring = rawstring + rawdata[0][i].what+" |:=> "+rawdata[0][i].who+"\n";
			}
		}
		rawstring = rawstring + "\nEnd of DOM node access\n---------------------------------------\n";
		for (i = 0; i < rawdata[1].length; i++)
		{
			//1 means window accesses;
			if ((rawdata[1][i].what!="")&&(rawdata[1][i].who!="trusted"))
			{
				rawstring = rawstring + rawdata[1][i].what+" |:=> "+rawdata[1][i].who+"\n";
			}
		}
		rawstring = rawstring + "\nEnd of window special property access\n---------------------------------------\n";
		for (i = 0; i < rawdata[2].length; i++)
		{
			//2 means document accesses;
			if ((rawdata[2][i].what!="")&&(rawdata[2][i].who!="trusted"))
			{
				rawstring = rawstring + rawdata[2][i].what+" |:=> "+rawdata[2][i].who+"\n";
			}
		}
		rawstring = rawstring + "\nEnd of document special property access\n";
		//record the embedding location of all scripts
		scriptLoc = ""
		var scripts = win.document.getElementsByTagName('script');
		for (i = 0; i < scripts.length; i++)
		{
			if (scripts[i].src!="")
			{
				//record all non-inlined scripts
				scriptLoc = scriptLoc + scripts[i].src + " <=|=> " + getXPath(scripts[i]) + "\n";
			}
		}
		var data = scriptLoc + "\n--------------DOMAR_Separator---------------\n\n" + rawstring;
		// You can also optionally pass a flags parameter here. It defaults to
		// FileUtils.MODE_WRONLY | FileUtils.MODE_CREATE | FileUtils.MODE_TRUNCATE;
		var ostream = FileUtils.openSafeFileOutputStream(file)

		var converter = Components.classes["@mozilla.org/intl/scriptableunicodeconverter"].
						createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
		converter.charset = "UTF-8";
		var istream = converter.convertToInputStream(data);

		// The last argument (the callback) is optional.
		NetUtil.asyncCopy(istream, ostream, function(status) {
		  istream.close();
		  if (!Components.isSuccessCode(status)) {
			// Handle error!
			alert("error writing policy to disk!");
			return;
		  }
		  // Data has been written to the file.
		});
	}
};
function recordTime(){
	var win=window.content.document.defaultView.wrappedJSObject;
	//if (win.___record==undefined) return;			//uncomment this line if we want to record instrumented performance only.
	endTime=new Date().getTime();
	//alert(endTime-startTime);						//uncomment this line if we want to alert the time in real-time.
}
//only register the eventhandler after page has been loaded, otherwise window.content is null.
window.addEventListener("DOMContentLoaded",function(){window.content.addEventListener('beforeunload',writePolicy,false);window.content.addEventListener('load',recordTime,false);},false);
})();