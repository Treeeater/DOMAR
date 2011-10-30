var DOMAccessRecorder = {
  onLoad: function() {
    // initialization code
    this.initialized = true;
  },
  
  onMenuItemCommand: function() {
    var optionWindow = window.open("chrome://helloworld/content/options.xul", "", "chrome");
	optionWindow.content = window.content;
	optionWindow.addEventListener("DOMContentLoaded", function(){optionWindow.document.getElementById("url").textContent = window.content.document.location.href;},false);
  }
};

window.addEventListener("load", function(e) { DOMAccessRecorder.onLoad(e); }, false);