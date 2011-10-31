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

window.addEventListener("load", function(e) { DOMAccessRecorder.onLoad(e); }, false);