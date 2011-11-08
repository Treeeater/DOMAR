function DOMAccessRecorderOptions() {
	var old_pref = [];
	var cur_pref = [];
	var getDomain = function() {
		var rvalue = window.content.document.domain;
		//if (window.content.document.location.href.indexOf("https")>=0) rvalue = "https://"+rvalue;
		//else rvalue = "http://"+rvalue;
		//only record top tow level domains:
		rvalue = rvalue.replace(/(.*)\.(.*)\.(.*)$/,"$2.$3");
		return rvalue;
	};
	
	this.applySettings = function() {
		//var file = Components.classes["@mozilla.org/file/local;1"].createInstance(Components.interfaces.nsILocalFile);
		//file.initWithPath("preference.txt");
		Components.utils.import("resource://gre/modules/NetUtil.jsm");
		Components.utils.import("resource://gre/modules/FileUtils.jsm");
		var file = FileUtils.getFile("ProfD", ["DOMAR","DOMAR_preference.txt"]);
		if (file.exists()==false) file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);
		var domain = getDomain();
		//Get current preference -> cur_pref:
		var items = document.getElementsByTagName('listitem');
		var i;
		for (i = 0; i < items.length; i++)
		{
			cur_pref.push(items[i].getAttribute("label"));
		}
		//Add or remove the current domain to/from the cur_pref.
		var checked = document.getElementById('checkbx').checked;
		var exists = false;
		var count = -1;
		for (i = 0; i < cur_pref.length; i++)
		{
			if (cur_pref[i]==domain) {
				exists = true;
				count = i;
			}
		}
		if ((checked)&&(!exists))
		{
			cur_pref.push(domain);
		}
		else if ((!checked)&&(exists))
		{
			cur_pref.splice(count,1);
		}
		// file is nsIFile, data is a string
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
    };
	this.initialize = function() {
		document.getElementById("url").textContent = getDomain();
		Components.utils.import("resource://gre/modules/NetUtil.jsm");
		Components.utils.import("resource://gre/modules/FileUtils.jsm");
		var file = FileUtils.getFile("ProfD", ["DOMAR","DOMAR_preference.txt"]);
		if (file.exists()==false) file.create(Components.interfaces.nsIFile.NORMAL_FILE_TYPE,0);
		// open an input stream from file
		var istream = Components.classes["@mozilla.org/network/file-input-stream;1"].
              createInstance(Components.interfaces.nsIFileInputStream);
		istream.init(file, 0x01, 0444, 0);
		istream.QueryInterface(Components.interfaces.nsILineInputStream);
		var domain = getDomain();
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
			if (old_pref[i]==domain) {
				document.getElementById('checkbx').setAttribute("checked","true");
			}
		}
	};
	this.addCallBack = function(s) {
		var items = document.getElementsByTagName('listitem');
		var i;
		for (i = 0; i < items.length; i++)
		{
			if (items[i].getAttribute("label") == s) {alert('This domain already exists!'); return;}
		}
		var newitem = document.createElement('listitem');
		newitem.setAttribute("label",s);
		document.getElementById('URLList').appendChild(newitem);
	};
	this.add = function() {
		var addWindow = window.open("chrome://domar/content/add.xul", "", "chrome");
		addWindow.ref = this.addCallBack;
	};
	this.remove = function() {
		if(document.getElementById('URLList').getSelectedItem(0)!=null)
		{
			document.getElementById('URLList').removeChild(document.getElementById('URLList').getSelectedItem(0));
		}
	};
	this.trusted = function() {
		if (document.getElementById('URLList').getSelectedItem(0)!=null)
		{
			var addWindow = window.open("chrome://domar/content/trusted.xul", "", "chrome");
			addWindow.mainDomain = document.getElementById('URLList').getSelectedItem(0).label;
		}
		else alert('please select an URL to edit first!');
	}
	return this;
};
var DOMaccessRecorderOptions = new DOMAccessRecorderOptions();
window.addEventListener("DOMContentLoaded", DOMaccessRecorderOptions.initialize, false);