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

var ___record = (function (){
var seqID = 0;
if (/Firefox[\/\s](\d+\.\d+)/.test(navigator.userAgent))
{ //test for Firefox/x.x or Firefox x.x (ignoring remaining digits);
	var ffversion=new Number(RegExp.$1) // capture x.x portion and store as a number
}
if (!ffversion||(ffversion<5)) return null;
//private variable: records all DOM accesses
var record = new Array(new Array(), new Array(), new Array());
var DOMRecord = 0;
var windowRecord = 1;
var documentRecord = 2;
//Enumerates all types of elements to mediate properties like parentNode
//According to DOM spec level2 by W3C, HTMLBaseFontElement not defined in FF.
var allElementsType = [HTMLElement,HTMLHtmlElement,HTMLHeadElement,HTMLLinkElement,HTMLTitleElement,HTMLMetaElement,HTMLBaseElement,HTMLIsIndexElement,HTMLStyleElement,HTMLBodyElement,HTMLFormElement,HTMLSelectElement,HTMLOptGroupElement,HTMLOptionElement,HTMLInputElement,HTMLTextAreaElement,HTMLButtonElement,HTMLLabelElement,HTMLFieldSetElement,HTMLLegendElement,HTMLUListElement,HTMLDListElement,HTMLDirectoryElement,HTMLMenuElement,HTMLLIElement,HTMLDivElement,HTMLParagraphElement,HTMLHeadingElement,HTMLQuoteElement,HTMLPreElement,HTMLBRElement,HTMLFontElement,HTMLHRElement,HTMLModElement,HTMLAnchorElement,HTMLImageElement,HTMLParamElement,HTMLAppletElement,HTMLMapElement,HTMLAreaElement,HTMLScriptElement,HTMLTableElement,HTMLTableCaptionElement,HTMLTableColElement,HTMLTableSectionElement,HTMLTableRowElement,HTMLTableCellElement,HTMLFrameSetElement,HTMLFrameElement,HTMLIFrameElement,HTMLObjectElement,HTMLSpanElement];
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
var lookupTable = new Array();		//to store computed MD5 hashes.
function getCallerInfo(funcName)
{
	var callerInfo = "";
	var currentCaller = getCallerInfo.caller.caller;		//get the real caller by calling the caller twice.
	var depth = 0;
	while ((currentCaller!=null)&&(depth<=3))
	{
		depth++;			//currently just record 3 levels of caller
		cached = lookupTable[currentCaller.toString()];
		if (cached!=undefined) callerInfo = cached + " called " + callerInfo;
		else
		{
			toCache = faultylabs.MD5(currentCaller.toString());
			callerInfo = toCache + " called " + callerInfo;
			lookupTable[currentCaller.toString()]=toCache;		//push computed function hash to hashtable.
		}
		currentCaller = currentCaller.caller;
	}
	callerInfo = callerInfo + funcName + ".";
	return callerInfo;
}
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
		seqID++;
		//To record the calling stack
		var callerInfo = getCallerInfo("getElementById");
		//To record the acutal content.
		record[DOMRecord].push({what:thispath,when:seqID,who:callerInfo});
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
		seqID++;
		var callerInfo = getCallerInfo("getElementsByClassName");	
		record[DOMRecord].push({what:"getElementsByClassName: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
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
		seqID++;
		var callerInfo = getCallerInfo("getElementsByTagName");	
		record[DOMRecord].push({what:"getElementsByTagName: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
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
		seqID++;
		var callerInfo = getCallerInfo("getElementsByTagNameNS");	
		record[DOMRecord].push({what:"getElementsByTagNameNS: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
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
		seqID++;
		var callerInfo = getCallerInfo("getElementsByName");	
		record[DOMRecord].push({what:"getElementsByName: "+arguments[0]+", results: " + thispath,when:seqID,who:callerInfo});			//This is going to return all accessed elements.
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
		seqID++;
		var callerInfo = getCallerInfo("cookie_getter");	
		record[documentRecord].push({what:'document.cookie read!',when:seqID,who:callerInfo});
		return old_cookie_getter.apply(document);
	};
}
if (old_cookie_setter)
{
	var newCookieSetter = function(str){
		seqID++;
		var callerInfo = getCallerInfo("cookie_setter");	
		record[documentRecord].push({what:'document.cookie set!',when:seqID,who:callerInfo});
		return old_cookie_setter.call(document,str);
	};
}
if (oldImages)
{
	var newImages = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.images");	
		record[documentRecord].push({what:'document.images read!',when:seqID,who:callerInfo});
		return oldImages.apply(document);
	};
}
if (oldAnchors)
{
	var newAnchors = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.anchors");	
		record[documentRecord].push({what:'document.anchors read!',when:seqID,who:callerInfo});
		return oldAnchors.apply(document);
	};
}
if (oldLinks)
{
	var newLinks = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.links");	
		record[documentRecord].push({what:'document.links read!',when:seqID,who:callerInfo});
		return oldLinks.apply(document);
	};
}
if (oldForms)
{
	var newForms = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.forms");	
		record[documentRecord].push({what:'document.forms read!',when:seqID,who:callerInfo});
		return oldForms.apply(document);
	};
}
if (oldApplets)
{
	var newApplets = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.applets");	
		record[documentRecord].push({what:'document.applets read!',when:seqID,who:callerInfo});
		return oldApplets.apply(document);
	};
}
if (oldURL)
{
	var newURL = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.URL");	
		record[documentRecord].push({what:'document.URL read!',when:seqID,who:callerInfo});
		return oldURL.apply(document);
	};
}
if (oldDomain)
{
	var newDomain = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.domain");	
		record[documentRecord].push({what:'document.domain read!',when:seqID,who:callerInfo});
		return oldDomain.apply(document);
	};
}
if (oldTitle)
{
	var newTitle = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.title");	
		record[documentRecord].push({what:'document.title read!',when:seqID,who:callerInfo});
		return oldTitle.apply(document);
	};
}
if (oldReferrer)
{
	var newReferrer = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.referrer");	
		record[documentRecord].push({what:'document.referrer read!',when:seqID,who:callerInfo});
		return oldReferrer.apply(document);
	};
}
if (oldLastModified)
{
	var newLastModified = function(){
		seqID++;
		var callerInfo = getCallerInfo("document.lastModified");	
		record[documentRecord].push({what:'document.lastModified read!',when:seqID,who:callerInfo});
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
if (oldUserAgent) { var newUserAgent = function(){ seqID++;record[windowRecord].push({what:'navigator.userAgent read!',when:seqID,who:getCallerInfo("")}); return oldUserAgent.apply(navigator);};
}
if (oldPlatform) { var newPlatform = function(){ seqID++;record[windowRecord].push({what:'navigator.platform read!',when:seqID,who:getCallerInfo("")}); return oldPlatform.apply(navigator);};
}
if (oldAppCodeName) { var newAppCodeName = function(){ seqID++;record[windowRecord].push({what:'navigator.appCodeName read!',when:seqID,who:getCallerInfo("")}); return oldAppCodeName.apply(navigator);};
}
if (oldAppVersion) { var newAppVersion = function(){ seqID++;record[windowRecord].push({what:'navigator.appVersion read!',when:seqID,who:getCallerInfo("")}); return oldAppVersion.apply(navigator);};
}
if (oldAppName) { var newAppName = function(){ seqID++;record[windowRecord].push({what:'navigator.appName read!',when:seqID,who:getCallerInfo("")}); return oldAppName.apply(navigator);};
}
if (oldCookieEnabled) { var newCookieEnabled = function(){ seqID++;record[windowRecord].push({what:'navigator.cookieEnabled read!',when:seqID,who:getCallerInfo("")}); return oldCookieEnabled.apply(navigator);};
}
if (oldAvailWidth) { var newAvailWidth = function(){ seqID++;record[windowRecord].push({what:'screen.availWidth read!',when:seqID,who:getCallerInfo("")}); return oldAvailWidth.apply(screen);};
}
if (oldAvailHeight) { var newAvailHeight = function(){ seqID++;record[windowRecord].push({what:'screen.availHeight read!',when:seqID,who:getCallerInfo("")}); return oldAvailHeight.apply(screen);};
}
if (oldColorDepth) { var newColorDepth = function(){ seqID++;record[windowRecord].push({what:'screen.colorDepth read!',when:seqID,who:getCallerInfo("")}); return oldColorDepth.apply(screen);};
}
if (oldHeight) { var newHeight = function(){ seqID++;record[windowRecord].push({what:'screen.height read!',when:seqID,who:getCallerInfo("")}); return oldHeight.apply(screen);};
}
if (oldWidth) { var newWidth = function(){ seqID++;record[windowRecord].push({what:'screen.width read!',when:seqID,who:getCallerInfo("")}); return oldWidth.apply(screen);};
}
if (oldPixelDepth) { var newPixelDepth = function(){ seqID++;record[windowRecord].push({what:'screen.pixelDepth read!',when:seqID,who:getCallerInfo("")}); return oldPixelDepth.apply(screen);};
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
	allElementsType[i].prototype.__defineGetter__('parentNode',function(){var thispath = getXPath(oldParentNode.apply(this)); if (thispath!="") {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:getCallerInfo("parentNode")});} return oldParentNode.apply(this);});
	allElementsType[i].prototype.__defineGetter__('nextSibling',function(){var thispath = getXPath(oldNextSibling.apply(this)); if (thispath!="") {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:getCallerInfo("nextSibling")});} return oldNextSibling.apply(this);});
	allElementsType[i].prototype.__defineGetter__('previousSibling',function(){var thispath = getXPath(oldPreviousSibling.apply(this)); if (thispath!="") {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:getCallerInfo("previousSibling")});} return oldPreviousSibling.apply(this);});
	allElementsType[i].prototype.__defineGetter__('firstChild',function(){var thispath = getXPath(oldFirstChild.apply(this)); if (thispath!="") {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:getCallerInfo("firstChild")});} return oldFirstChild.apply(this);});
	allElementsType[i].prototype.__defineGetter__('lastChild',function(){var thispath = getXPath(oldLastChild.apply(this)); if (thispath!="") {seqID++;record[DOMRecord].push({what:thispath,when:seqID,who:getCallerInfo("lastChild")});} return oldLastChild.apply(this);});
	allElementsType[i].prototype.__defineGetter__('children',function(){var thispath = getXPath(this); if (thispath!="") {seqID++;record[DOMRecord].push({what:"Children of: "+ thispath +", results: "+getXPathCollection(oldChildren.apply(this)),when:seqID,who:getCallerInfo("children")});} return oldChildren.apply(this);});
	allElementsType[i].prototype.__defineGetter__('childNodes',function(){var thispath = getXPath(this); if (thispath!="") {seqID++;record[DOMRecord].push({what:"Children of: "+thispath+", results: "+getXPathCollection(oldChildNodes.apply(this)),when:seqID,who:getCallerInfo("childNodes")});} return oldChildNodes.apply(this);});	
	allElementsType[i].prototype.getElementsByTagName = function(){
		var func;
		var j;
		for (j=0; j < allElementsType.length; j++)
		{
			if (this.constructor==allElementsType[j]) 
			{
				func = oldEGetTagName[j];
			}
		}
		//record.push('Called someElement.getElementsByTagName('+arguments[0]+');');	//This is only going to add a English prose to record.
		var thispath = getXPath(this);
		if (thispath!="")
		{
			seqID++;
			record[DOMRecord].push({what:"someElement: "+thispath+" called .getElementsByTagName: "+arguments[0]+", results: "+getXPathCollection(func.apply(this,arguments)),when:seqID,who:getCallerInfo("getElementsByTagName")});			//This is going to return all accessed elements.
		}
		return func.apply(this,arguments);
	};
	allElementsType[i].prototype.getElementsByClassName = function(){
		var func;
		var j;
		for (j=0; j < allElementsType.length; j++)
		{
			if (this.constructor==allElementsType[j]) func = oldEGetClassName[j];
		}
		//record.push('Called someElement.getElementsByClassName('+arguments[0]+');');	//This is only going to add a English prose to record.
		var thispath = getXPath(this);
		if (thispath!="")
		{
			seqID++;
			record[DOMRecord].push({what:"someElement: "+thispath+" called .getElementsByClassName: "+arguments[0]+", results: "+getXPathCollection(func.apply(this,arguments)),when:seqID,who:getCallerInfo("getElementsByClassName")});			//This is going to return all accessed elements.
		}
		return func.apply(this,arguments);
	};
	allElementsType[i].prototype.getElementsByTagNameNS = function(){
		var func;
		var j;
		for (j=0; j < allElementsType.length; j++)
		{
			if (this.constructor==allElementsType[j]) func = oldEGetTagNameNS[j];
		}
		//record.push('Called someElement.getElementsByTagNameNS('+arguments[0]+');');	//This is only going to add a English prose to record.
		var thispath = getXPath(this);
		if (thispath!="")
		{
			seqID++;
			record[DOMRecord].push({what:"someElement: "+thispath+" called .getElementsByTagNameNS: "+arguments[0]+", results: "+getXPathCollection(func.apply(this,arguments)),when:seqID,who:getCallerInfo("getElementsByTagNameNS")});			//This is going to return all accessed elements.
		}
		return func.apply(this,arguments);
	};
	if (oldInnerHTMLGetter)
	{
		allElementsType[i].prototype.__defineGetter__('innerHTML',function(str){
		seqID++;
		record[DOMRecord].push({what:'Read innerHTML of this element: '+getXPath(this)+'!',when:seqID,who:getCallerInfo("innerHTML")});
		return oldInnerHTMLGetter.call(this,str);
		});
	}
	//allElementsType[i].prototype.__defineGetter__('attributes',function(){record.push(getXPathCollection(oldAttributes.apply(this)));return oldAttributes.apply(this);});		//attribute nodes are detached from the DOM tree. Currently we do not support mediation of this.
}
//document.head.removeChild(oldGetTagName.call(document,'script')[0]);			//remove myself
return (function(){return record;});
})();