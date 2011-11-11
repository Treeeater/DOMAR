/* DOM Access recording, author: Yuchen Zhou
Oct, 2011.  University of Virginia.*/

/*This version only works on Firefox*/

/*
Mediated APIs:
--document selectors--
document.getElementById
document.getElementsByClassName
document.getElementsByTagName
document.getElementsByName
--traversals--
parentNode
nextSibling
previousSibling
firstChild
lastChild
childNodes
children
--document special properties--
document.cookie
document.cookie=
document.images/anchors/links/applets/forms
--node special properties--
node.innerHTML
*/
function ___record(){
var seqID = 0;
if (/Firefox[\/\s](\d+\.\d+)/.test(navigator.userAgent))
{ //test for Firefox/x.x or Firefox x.x (ignoring remaining digits);
	var ffversion=new Number(RegExp.$1) // capture x.x portion and store as a number
}
if (!ffversion||(ffversion<5)) return null;
//private variable: records all DOM accesses
var record = new Array(new Array(), new Array(), new Array());
var trustedDomains = [];
var DOMRecord = 0;
var windowRecord = 1;
var documentRecord = 2;
//Enumerates all types of elements to mediate properties like parentNode
//According to DOM spec level2 by W3C, HTMLBaseFontElement not defined in FF.
var allElementsType = [HTMLElement,HTMLHtmlElement,HTMLHeadElement,HTMLLinkElement,HTMLTitleElement,HTMLMetaElement,HTMLBaseElement,HTMLStyleElement,HTMLBodyElement,HTMLFormElement,HTMLSelectElement,HTMLOptGroupElement,HTMLOptionElement,HTMLInputElement,HTMLTextAreaElement,HTMLButtonElement,HTMLLabelElement,HTMLFieldSetElement,HTMLLegendElement,HTMLUListElement,HTMLDListElement,HTMLDirectoryElement,HTMLMenuElement,HTMLLIElement,HTMLDivElement,HTMLParagraphElement,HTMLHeadingElement,HTMLQuoteElement,HTMLPreElement,HTMLBRElement,HTMLFontElement,HTMLHRElement,HTMLModElement,HTMLAnchorElement,HTMLImageElement,HTMLParamElement,HTMLAppletElement,HTMLMapElement,HTMLAreaElement,HTMLScriptElement,HTMLTableElement,HTMLTableCaptionElement,HTMLTableColElement,HTMLTableSectionElement,HTMLTableRowElement,HTMLTableCellElement,HTMLFrameSetElement,HTMLFrameElement,HTMLIFrameElement,HTMLObjectElement,HTMLSpanElement];
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

var getXPathCollection = function (collection) {
	if (collection.length>10) return "More than 10 elements!";		//Sometimes the trace gets too big. We try to avoid that.
	path = "";
	var i = 0;
	for (; i < collection.length; i++)
	{
		var thispath = getXPath(collection[i]);
		if (thispath!="")
		{
			path = path + thispath +"; ";
		}
	}
	return path;
}
//utilities:
/*
	If we only care about the top of the stack, which is not necessarily the case. Third-party scripts maybe called in the middle, e.g. Analytics provide APIs for host to call.  If this happens, we want to have a way to at least show that which third-party scripts touched which element.
		
var getCallerInfo = function() {
    try {
        this.undef();
        return null;
    } catch (e) {
		var lastline = e.stack;
		var ignored = "";
		if (lastline.length>3000) lastline = lastline.substr(lastline.length-3000,lastline.length);		//Assumes the total call stack is less than 3000 characters. avoid the situation when arguments becomes huge and regex operation virtually stalls the browser.  This could very well happen when innerHTML is changed. For example, flickr.com freezes our extension without this LOC.
		if (lastline!=e.stack) ignored = "; stack trace > 3000 chars.";					//notify the record that this message is not complete.
        lastline = lastline.replace(/[\s\S]*\n(.*)\n$/m,"$1");		//getting rid of other lines
		//var penultimateline = e.stack.replace(/[\s\S]*\n(.*)\n(.*)\n$/m,"$1");
		lastline = lastline.replace(/[\s\S]*@(.*)$/,"$1");				//get rid of the whole arguments
		//penultimateline = penultimateline.replace(/[\s\S]*@(.*)$/,"$1");
		if (lastline.match(/\?(.*)/,""))
		{
			lineNo = lastline.replace(/.*\:(.*)$/,"$1");				//extract the line number
			lastline = lastline.replace(/\?(.*)/,"");					//get rid of all the GET parameters
			lastline = lastline + ":" + lineNo;
		}
		
		//The following two cases are to indicate two corner cases which we do not cover for now. Flash-DOM access is very prevalent but it would be a disaster to focus on this.  Old setAttribute way of setting eventhandlers is deprecated and less used. For now we ignore these cases.
		//if (lastline.match(/:1$/)){
			//if (!lastline.match(/js:1$/))
			//{
				//alert(e.stack);
				//This probably is an event handler registered using old API (setAttribute onclick). FF cannot return correctly who registered it.
				//However according to MDN this registering method is deprecated.
				//Also worth noticing is that not all non js's 1st line access indicates an eventhandler.
			//}
		//}
		//if (lastline.match(/:0$/)) {
			//When actionscript in Flash/Flex tries to call related APIs, e.stack will return URI:0 as top stack, which is incorrect. However we ignore this bug because we are not specifically looking at Actionscript accesses.
			//We ignore this case for now.
			//alert(e.stack);
		//}
		
		return lastline+ignored;
    }
};
*/
//if getCallerInfo returns null, all recording functions will not record current access.
var getCallerInfo = function() {
    try {
        this.undef();
        return null;
    } catch (e) {
		var entireStack = e.stack;
		var ignored = "";
		var untrustedStack = "";
		var recordedDomains = [];
		if (entireStack.length>3000) 
		{
			entireStack = entireStack.substr(entireStack.length-3000,entireStack.length);		//Assumes the total call stack is less than 3000 characters. avoid the situation when arguments becomes huge and regex operation virtually stalls the browser.  This could very well happen when innerHTML is changed. For example, flickr.com freezes our extension without this LOC.
			ignored = "; stack trace > 3000 chars.";					//notify the record that this message is not complete.
		}
		while (entireStack != "")
		{
			//assuming a http or https protocol, which is true >99% of the time.
			var curLine = "";
			curLine = entireStack.replace(/([\s\S]*?@http.*\n)[\s\S]*/m, "$1");
			if (curLine=="") return null;		//giveup if it's not http/https protocol
			entireStack = entireStack.substr(curLine.length,entireStack.length);	//entireStack is adjusted to remove curLine
			curLine = curLine.replace(/[\s\S]*@(http.*\n)$/,"$1");				//get rid of the whole arguments
			curDomain = curLine.replace(/.*?\/\/(.*?)\/.*/,"$1");				//http://www.google.com/a.html, w/ third slash.
			if (curDomain==curLine) curDomain = curLine.replace(/.*?\/\/(.*)/,"$1");	//http://www.google.com, no third slash.
			if (curDomain==curLine) alert('error');								//WTF? is this a URL?
			curTopDomain = curDomain.replace(/.*\.(.*\..*)/,"$1");				//get the top domain
			if (curTopDomain[curTopDomain.length-1]=="\n") curTopDomain=curTopDomain.substr(0,curTopDomain.length-1);	//chomp
			var i = 0;
			var trusted = false;
			var recorded = false;
			for (i=0; i < trustedDomains.length; i++)
			{
				if (curLine.indexOf(trustedDomains[i])>-1)
				{
					trusted = true;
					break;
				}
			}
			if (!trusted)
			{
				for (i=0; i < recordedDomains.length; i++)
				{
					//See if we have already recorded this domain in this access.
					if (curLine.indexOf(recordedDomains[i])>-1)
					{
						recorded = true;
						break;
					}
				}
			}
			if ((!trusted)&&(!recorded)) 
			{
				untrustedStack += curLine;
				recordedDomains.push(curTopDomain);
			}
		}
		if (untrustedStack == "") return null;
		return untrustedStack+ignored;
    }
};
var getFullCallerInfo = function() {
    try {
        this.undef();
        return null;
    } catch (e) {
        return e.stack;
    }
};
//Original DOM-ECMAscript API
var oldGetId = document.getElementById;	
var oldGetClassName = document.getElementsByClassName;
var oldGetTagName = document.getElementsByTagName;
var oldGetName = document.getElementsByName;
var oldGetTagNameNS = document.getElementsByTagNameNS;
//New DOM-ECMAScript API
if (oldGetId)
{
	var newGetId = function(){
	var thispath = getXPath(oldGetId.apply(document,arguments));
	if (thispath!="")
	{
	//If this node is attached to the root DOM tree, but not something created out of nothing.
		//To record the sequence
		
		//To record the calling stack
		var callerInfo = getCallerInfo("getElementById");
		if (callerInfo!=null)
		//To record the acutal content.
		{
			seqID++;
			record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});
		}
	}
	return oldGetId.apply(document,arguments);
	};
}
if (oldGetClassName)
{
	var newGetClassName = function(){
	//record.push('Called document.getElementsByClassName('+arguments[0]+');');	//This is only going to add a English prose to record.
	var thispath = getXPathCollection(oldGetClassName.apply(document,arguments));
	if (thispath!="")
	{
		var callerInfo = getCallerInfo("getElementsByClassName");
		if (callerInfo!=null)
		{
			seqID++;
			record[DOMRecord].push({what:"getElementsByClassName: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
	}
	return oldGetClassName.apply(document,arguments);
	};
}
if (oldGetTagName)
{
	var newGetTagName = function(){
	//record.push('Called document.getElementsByTagName('+arguments[0]+');');	//This is only going to add a English prose to record.
	var thispath = getXPathCollection(oldGetTagName.apply(document,arguments));
	if (thispath!="")
	{
		var callerInfo = getCallerInfo("getElementsByTagName");	
		if (callerInfo!=null){
		seqID++;
		record[DOMRecord].push({what:"getElementsByTagName: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
	}
	return oldGetTagName.apply(document,arguments);
	};
}
if (oldGetTagNameNS)
{
	var newGetTagNameNS = function(){
	//record.push('Called document.getElementsByTagNameNS('+arguments[0]+');');	//This is only going to add a English prose to record.
	var thispath = getXPathCollection(oldGetTagNameNS.apply(document,arguments));
	if (thispath!="")
	{
		var callerInfo = getCallerInfo("getElementsByTagNameNS");	
		if (callerInfo!=null){
		seqID++;
		record[DOMRecord].push({what:"getElementsByTagNameNS: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
	}
	return oldGetTagNameNS.apply(document,arguments);
	};
}
if (oldGetName)
{
	var newGetName = function(){
	//record.push('Called document.getElementsByName('+arguments[0]+');');	//This is only going to add a English prose to record.
	var thispath = getXPathCollection(oldGetName.apply(document,arguments));
	if (thispath!="")
	{	
		var callerInfo = getCallerInfo("getElementsByName");	
		if (callerInfo!=null){
		seqID++;
		record[DOMRecord].push({what:"getElementsByName: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
	}
	return oldGetName.apply(document,arguments);
	};
}

//Get original property accessors
var oldFirstChild = Element.prototype.__lookupGetter__('firstChild');
var oldLastChild = Element.prototype.__lookupGetter__('lastChild');
var oldChildren = Element.prototype.__lookupGetter__('children');
var oldChildNodes = Element.prototype.__lookupGetter__('childNodes');
var oldAttributes = Element.prototype.__lookupGetter__('attributes');
//innerHTML
oldInnerHTMLGetter = HTMLElement.prototype.__lookupGetter__('innerHTML');
//Get original DOM special properties
var old_cookie_setter = HTMLDocument.prototype.__lookupSetter__ ('cookie');
var old_cookie_getter = HTMLDocument.prototype.__lookupGetter__ ('cookie');
var oldImages = HTMLDocument.prototype.__lookupGetter__('images');
var oldAnchors = HTMLDocument.prototype.__lookupGetter__('anchors');
var oldLinks = HTMLDocument.prototype.__lookupGetter__('links');
var oldApplets = HTMLDocument.prototype.__lookupGetter__('applets');
var oldForms = HTMLDocument.prototype.__lookupGetter__('forms');
var oldURL = HTMLDocument.prototype.__lookupGetter__('URL');
var oldDomain = HTMLDocument.prototype.__lookupGetter__('domain');
var oldTitle = HTMLDocument.prototype.__lookupGetter__('title');
var oldReferrer = HTMLDocument.prototype.__lookupGetter__('referrer');
var oldLastModified = HTMLDocument.prototype.__lookupGetter__('lastModified');
//Define new DOM Special Properties
if (old_cookie_getter)
{
	var newCookieGetter = function(){
		var callerInfo = getCallerInfo("cookie_getter");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.cookie read!',when:seqID,who:callerInfo});
		}
		return old_cookie_getter.apply(document);
	};
}
if (old_cookie_setter)
{
	var newCookieSetter = function(str){
		var callerInfo = getCallerInfo("cookie_setter");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.cookie set!',when:seqID,who:callerInfo});
		}
		return old_cookie_setter.call(document,str);
	};
}
if (oldImages)
{
	var newImages = function(){
		var callerInfo = getCallerInfo("document.images");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.images read!',when:seqID,who:callerInfo});
		}
		return oldImages.apply(document);
	};
}
if (oldAnchors)
{
	var newAnchors = function(){
		var callerInfo = getCallerInfo("document.anchors");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.anchors read!',when:seqID,who:callerInfo});
		}
		return oldAnchors.apply(document);
	};
}
if (oldLinks)
{
	var newLinks = function(){
		var callerInfo = getCallerInfo("document.links");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.links read!',when:seqID,who:callerInfo});
		}
		return oldLinks.apply(document);
	};
}
if (oldForms)
{
	var newForms = function(){
		var callerInfo = getCallerInfo("document.forms");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.forms read!',when:seqID,who:callerInfo});
		}
		return oldForms.apply(document);
	};
}
if (oldApplets)
{
	var newApplets = function(){
		var callerInfo = getCallerInfo("document.applets");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.applets read!',when:seqID,who:callerInfo});
		}
		return oldApplets.apply(document);
	};
}
if (oldURL)
{
	var newURL = function(){
		var callerInfo = getCallerInfo("document.URL");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.URL read!',when:seqID,who:callerInfo});
		}
		return oldURL.apply(document);
	};
}
if (oldDomain)
{
	var newDomain = function(){
		var callerInfo = getCallerInfo("document.domain");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.domain read!',when:seqID,who:callerInfo});
		}
		return oldDomain.apply(document);
	};
}
if (oldTitle)
{
	var newTitle = function(){
		var callerInfo = getCallerInfo("document.title");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.title read!',when:seqID,who:callerInfo});
		}
		return oldTitle.apply(document);
	};
}
if (oldReferrer)
{
	var newReferrer = function(){
		var callerInfo = getCallerInfo("document.referrer");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.referrer read!',when:seqID,who:callerInfo});
		}
		return oldReferrer.apply(document);
	};
}
if (oldLastModified)
{
	var newLastModified = function(){
		var callerInfo = getCallerInfo("document.lastModified");	
		if (callerInfo!=null){
		seqID++;
		record[documentRecord].push({what:'document.lastModified read!',when:seqID,who:callerInfo});
		}
		return oldLastModified.apply(document);
	};
}
//Set default DOM special Properties to newly defined APIs.
if (newCookieGetter)
{
	HTMLDocument.prototype.__defineGetter__("cookie",newCookieGetter);
}
if (newCookieSetter)
{
	HTMLDocument.prototype.__defineSetter__("cookie",newCookieSetter);
}
if (newImages)
{
	HTMLDocument.prototype.__defineGetter__("images",newImages);
}
if (newAnchors)
{
	HTMLDocument.prototype.__defineGetter__("anchors",newAnchors);
}
if (newForms)
{
	HTMLDocument.prototype.__defineGetter__("forms",newForms);
}
if (newLinks)
{
	HTMLDocument.prototype.__defineGetter__("links",newLinks);
}
if (newApplets)
{
	HTMLDocument.prototype.__defineGetter__("applets",newApplets);
}
if (newTitle)
{
	HTMLDocument.prototype.__defineGetter__("title",newTitle);
}
if (newDomain)
{
	HTMLDocument.prototype.__defineGetter__("domain",newDomain);
}
if (newURL)
{
	HTMLDocument.prototype.__defineGetter__("URL",newURL);
}
if (newReferrer)
{
	HTMLDocument.prototype.__defineGetter__("referrer",newReferrer);
}
if (newLastModified)
{
	HTMLDocument.prototype.__defineGetter__("lastModified",newLastModified);
}
//old window-associated special property accessors:
oldUserAgent = Navigator.prototype.__lookupGetter__("userAgent");
oldPlatform = Navigator.prototype.__lookupGetter__("platform");
oldAppCodeName = Navigator.prototype.__lookupGetter__("appCodeName");
oldAppVersion = Navigator.prototype.__lookupGetter__("appVersion");
oldAppName = Navigator.prototype.__lookupGetter__("appName");
oldCookieEnabled = Navigator.prototype.__lookupGetter__("cookieEnabled");
oldAvailHeight = Screen.prototype.__lookupGetter__("availHeight");
oldAvailWidth = Screen.prototype.__lookupGetter__("availWidth");
oldColorDepth = Screen.prototype.__lookupGetter__("colorDepth");
oldHeight = Screen.prototype.__lookupGetter__("height");
oldPixelDepth = Screen.prototype.__lookupGetter__("pixelDepth");
oldWidth = Screen.prototype.__lookupGetter__("width");
//define new window special property accessors:
if (oldUserAgent) { var newUserAgent = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'navigator.userAgent read!',when:seqID,who:callerInfo});} return oldUserAgent.apply(navigator);};
}
if (oldPlatform) { var newPlatform = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'navigator.platform read!',when:seqID,who:callerInfo});} return oldPlatform.apply(navigator);};
}
if (oldAppCodeName) { var newAppCodeName = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'navigator.appCodeName read!',when:seqID,who:callerInfo});} return oldAppCodeName.apply(navigator);};
}
if (oldAppVersion) { var newAppVersion = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'navigator.appVersion read!',when:seqID,who:callerInfo});} return oldAppVersion.apply(navigator);};
}
if (oldAppName) { var newAppName = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'navigator.appName read!',when:seqID,who:callerInfo});} return oldAppName.apply(navigator);};
}
if (oldCookieEnabled) { var newCookieEnabled = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'navigator.cookieEnabled read!',when:seqID,who:callerInfo});} return oldCookieEnabled.apply(navigator);};
}
if (oldAvailWidth) { var newAvailWidth = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'screen.availWidth read!',when:seqID,who:callerInfo});} return oldAvailWidth.apply(screen);};
}
if (oldAvailHeight) { var newAvailHeight = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'screen.availHeight read!',when:seqID,who:callerInfo});} return oldAvailHeight.apply(screen);};
}
if (oldColorDepth) { var newColorDepth = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'screen.colorDepth read!',when:seqID,who:callerInfo});} return oldColorDepth.apply(screen);};
}
if (oldHeight) { var newHeight = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'screen.height read!',when:seqID,who:callerInfo});} return oldHeight.apply(screen);};
}
if (oldWidth) { var newWidth = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'screen.width read!',when:seqID,who:callerInfo});} return oldWidth.apply(screen);};
}
if (oldPixelDepth) { var newPixelDepth = function(){ var callerInfo = getCallerInfo(""); if (callerInfo!=null) {seqID++; record[windowRecord].push({what:'screen.pixelDepth read!',when:seqID,who:callerInfo});} return oldPixelDepth.apply(screen);};
}
//override the old window special property accessors:
if (newUserAgent) { Navigator.prototype.__defineGetter__("userAgent",newUserAgent); }
if (newPlatform) { Navigator.prototype.__defineGetter__("platform",newPlatform); }
if (newAppCodeName) { Navigator.prototype.__defineGetter__("appCodeName",newAppCodeName); }
if (newAppVersion) { Navigator.prototype.__defineGetter__("appVersion",newAppVersion); }
if (newAppName) { Navigator.prototype.__defineGetter__("appName",newAppName); }
if (newCookieEnabled) { Navigator.prototype.__defineGetter__("cookieEnabled",newCookieEnabled); }
if (newAvailWidth) { Screen.prototype.__defineGetter__("availWidth",newAvailWidth); }
if (newAvailHeight) { Screen.prototype.__defineGetter__("availHeight",newAvailHeight); }
if (newColorDepth) { Screen.prototype.__defineGetter__("colorDepth",newColorDepth); }
if (newHeight) { Screen.prototype.__defineGetter__("height",newHeight); }
if (newWidth) { Screen.prototype.__defineGetter__("width",newWidth); }
if (newPixelDepth) { Screen.prototype.__defineGetter__("pixelDepth",newPixelDepth); }

//Set default accessors to newly defined APIs.

if (newGetId)
{
	document.getElementById = newGetId;
}
if (newGetClassName)
{
	document.getElementsByClassName = newGetClassName;
}
if (newGetTagName)
{
	document.getElementsByTagName = newGetTagName;
}
if (newGetTagNameNS)
{
	document.getElementsByTagNameNS = newGetTagNameNS;
}
if (newGetName)
{
	document.getElementsByName = newGetName;
}
//Set property accessors to new traversal APIs.
var i = 0;
var oldEGetTagName = new Array();
var oldEGetClassName = new Array();
var oldEGetTagNameNS = new Array();
for (; i<allElementsType.length; i++)
{
	//store element.getElementsByTagName to old value
	oldEGetTagName[i] = allElementsType[i].prototype.getElementsByTagName;
	oldEGetClassName[i] = allElementsType[i].prototype.getElementsByClassName;
	oldEGetTagNameNS[i] = allElementsType[i].prototype.getElementsByTagNameNS;
	allElementsType[i].prototype.__defineGetter__('parentNode',function(){var thispath = getXPath(oldParentNode.apply(this)); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});} return oldParentNode.apply(this);});
	allElementsType[i].prototype.__defineGetter__('nextSibling',function(){var thispath = getXPath(oldNextSibling.apply(this)); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});} return oldNextSibling.apply(this);});
	allElementsType[i].prototype.__defineGetter__('previousSibling',function(){var thispath = getXPath(oldPreviousSibling.apply(this)); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});} return oldPreviousSibling.apply(this);});
	allElementsType[i].prototype.__defineGetter__('firstChild',function(){var thispath = getXPath(oldFirstChild.apply(this)); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});} return oldFirstChild.apply(this);});
	allElementsType[i].prototype.__defineGetter__('lastChild',function(){var thispath = getXPath(oldLastChild.apply(this)); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});} return oldLastChild.apply(this);});
	allElementsType[i].prototype.__defineGetter__('children',function(){var thispath = getXPath(this); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:"Children of: "+ thispath +", results: "+getXPathCollection(oldChildren.apply(this)),when:seqID,who:callerInfo});} return oldChildren.apply(this);});
	allElementsType[i].prototype.__defineGetter__('childNodes',function(){var thispath = getXPath(this); var callerInfo = getCallerInfo(); if ((thispath!="")&&(callerInfo!=null)) {seqID++;record[DOMRecord].push({what:"Children of: "+thispath+", results: "+getXPathCollection(oldChildNodes.apply(this)),when:seqID,who:callerInfo});} return oldChildNodes.apply(this);});	
}
//assign element.getElementsByTagName to new value
for (i=0; i<allElementsType.length; i++)
{
	allElementsType[i].prototype.getElementsByTagName = function(){
		var func = oldEGetTagName[50];		//HTMLObjectElement in FF has a bug. This is a ad hoc workaround.
		var j;
		for (j=0; j < allElementsType.length; j++)
		{
			if ((this.constructor==allElementsType[j])||(this.__proto__==allElementsType[j].prototype))
			{
				func = oldEGetTagName[j];
			}
		}
		//record.push('Called someElement.getElementsByTagName('+arguments[0]+');');	//This is only going to add a English prose to record.
		var thispath = getXPath(this);
		var callerInfo = getCallerInfo();
		if ((thispath!="")&&(callerInfo!=null))
		{
			seqID++;
			record[DOMRecord].push({what:"someElement: "+thispath+" called .getElementsByTagName: "+arguments[0]+", results: "+getXPathCollection(func.apply(this,arguments)),when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
		return func.apply(this,arguments);
	};
	allElementsType[i].prototype.getElementsByClassName = function(){
		var func;
		var j;
		for (j=0; j < allElementsType.length; j++)
		{
			if ((this.constructor==allElementsType[j])||(this.__proto__==allElementsType[j].prototype)) func = oldEGetClassName[j];
		}
		//record.push('Called someElement.getElementsByClassName('+arguments[0]+');');	//This is only going to add a English prose to record.
		var thispath = getXPath(this);
		var callerInfo = getCallerInfo();
		if ((thispath!="")&&(callerInfo!=null))
		{
			seqID++;
			record[DOMRecord].push({what:"someElement: "+thispath+" called .getElementsByClassName: "+arguments[0]+", results: "+getXPathCollection(func.apply(this,arguments)),when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
		return func.apply(this,arguments);
	};
	allElementsType[i].prototype.getElementsByTagNameNS = function(){
		var func;
		var j;
		for (j=0; j < allElementsType.length; j++)
		{
			if ((this.constructor==allElementsType[j])||(this.__proto__==allElementsType[j].prototype)) func = oldEGetTagNameNS[j];
		}
		//record.push('Called someElement.getElementsByTagNameNS('+arguments[0]+');');	//This is only going to add a English prose to record.
		var thispath = getXPath(this);
		var callerInfo = getCallerInfo();
		if ((thispath!="")&&(callerInfo!=null))
		{
			seqID++;
			record[DOMRecord].push({what:"someElement: "+thispath+" called .getElementsByTagNameNS: "+arguments[0]+", results: "+getXPathCollection(func.apply(this,arguments)),when:seqID,who:callerInfo});			//This is going to return all accessed elements.
		}
		return func.apply(this,arguments);
	};
	if (oldInnerHTMLGetter)
	{
		allElementsType[i].prototype.__defineGetter__('innerHTML',function(str){
		var thispath = getXPath(this);
		var callerInfo = getCallerInfo();
		if ((thispath!="")&&(callerInfo!=null))
		{
			seqID++;
			record[DOMRecord].push({what:'Read innerHTML of this element: '+thispath+'!',when:seqID,who:callerInfo});
		}
		return oldInnerHTMLGetter.call(this,str);
		});
	}
	//allElementsType[i].prototype.__defineGetter__('attributes',function(){record.push(getXPathCollection(oldAttributes.apply(this)));return oldAttributes.apply(this);});		//attribute nodes are detached from the DOM tree. Currently we do not support mediation of this.
}
//document.head.removeChild(oldGetTagName.call(document,'script')[0]);			//remove myself
return (function(){this.getRecord = function(){return record;}; this.Push = function(a){trustedDomains.push(a)}; this.Get = function() {return trustedDomains}; return this;});
}

__record = new ___record();
_record = __record();