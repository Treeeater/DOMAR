var DOMAccessRecorder = {
  onLoad: function() {
    // initialization code
    this.initialized = true;
  },
  
  onMenuItemCommand: function() {
    var optionWindow = window.open("chrome://DOMAR/content/options.xul", "", "chrome");
	optionWindow.content = window.content;
  }
};

var mainC = function() {
	var enabled = true;
	this.loadP = function(){
	};
	this.toggleP = function(){
		enabled = !enabled;
		document.getElementById('enabled').label = enabled ? "Enabled":"Disabled";
	};
	this.getStatus = function(){
		return enabled;
	}
};

var mainControl = new mainC();
window.addEventListener("load", function(e) { DOMAccessRecorder.onLoad(e); }, false);