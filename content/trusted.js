function trustedSites() {
	var old_pref=[];
	var urlfile="";
	var cur_pref=[];
	this.initialize = function() {
		var mainDomain = window.mainDomain;
		if (mainDomain.indexOf("?")>0)
		{
			//Now we ignore the GET parameters
			mainDomain = mainDomain.substr(0,mainDomain.indexOf("?"));
		}
		urlfile = mainDomain.replace(/[^a-zA-Z0-9]/g,"");	//\W also does the trick.
		urlfile = urlfile.substr(0,63);						//restrict the file length
		Components.utils.import("resource://gre/modules/NetUtil.jsm");
		Components.utils.import("resource://gre/modules/FileUtils.jsm");
		var file = FileUtils.getFile("ProfD", ["DOMAR","site_preferences",urlfile+".txt"]);
		if (file.exists()==false) file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);
		// open an input stream from file
		var istream = Components.classes["@mozilla.org/network/file-input-stream;1"].
              createInstance(Components.interfaces.nsIFileInputStream);
		istream.init(file, 0x01, 0444, 0);
		istream.QueryInterface(Components.interfaces.nsILineInputStream);
		// read lines into array
		var line = {}, hasmore;
		do {
		  hasmore = istream.readLine(line);
		  old_pref.push(line.value); 
		} while(hasmore);
		istream.close();
		var i = 0;
		for (; i <old_pref.length; i++)
		{
			var newitem = document.createElement('listitem');
			newitem.setAttribute("label",old_pref[i]);
			document.getElementById('URLList').appendChild(newitem);
		}
	};
	this.add = function() {
		var toAdd = document.getElementById('input').value;
		if (toAdd == ''){
			alert("Don't give me an empty domain!");
			return;
		}
		var newitem = document.createElement('listitem');
		newitem.setAttribute("label",toAdd);
		document.getElementById('URLList').appendChild(newitem);
	};
	this.remove = function() {
		if(document.getElementById('URLList').getSelectedItem(0)!=null)
		{
			document.getElementById('URLList').removeChild(document.getElementById('URLList').getSelectedItem(0));
		}
	};
	this.save = function() {
		Components.utils.import("resource://gre/modules/NetUtil.jsm");
		Components.utils.import("resource://gre/modules/FileUtils.jsm");
		var file = FileUtils.getFile("ProfD", ["DOMAR","site_preferences",urlfile+".txt"]);
		if (file.exists()==false) file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);
		var items = document.getElementsByTagName('listitem');
		var i;
		for (i = 0; i < items.length; i++)
		{
			cur_pref.push(items[i].getAttribute("label"));
		}
		var data = cur_pref.join("\n");
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
		close();
	}
	return this;
};
var trustedSites = new trustedSites();
window.addEventListener("DOMContentLoaded", trustedSites.initialize, false);