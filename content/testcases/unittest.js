var yuchen = (function(){
var seqID = 0;
var record = new Array(new Array(), new Array(), new Array());
var DOMRecord = 0;
var windowRecord = 1;
var documentRecord = 2;
var stack = new Array();
var oldUserAgent = Navigator.prototype.__lookupGetter__("userAgent");
var newUserAgent = function(){ 
	//if (seqID>1000) return;
	//stack.push(seqID);
	//seqID++;
	//record[windowRecord].push({what:'navigator.userAgent read!',when:seqID}); 
		return oldUserAgent.apply(navigator)+"yuchen";
	};
Navigator.prototype.__defineGetter__("userAgent",newUserAgent);
return (function(){return stack;});
})();
//document.head.removeChild(document.getElementsByTagName('script')[0]);
//if (document.body!=null) document.body.removeChild(document.getElementsByTagName('script')[0]);