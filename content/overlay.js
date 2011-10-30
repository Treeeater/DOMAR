var DOMAccessRecorder = {
  onLoad: function() {
    // initialization code
    this.initialized = true;
  },
  
  onMenuItemCommand: function() {
    window.open("chrome://helloworld/content/options.xul", "", "chrome");
  }
};

window.addEventListener("load", function(e) { DOMAccessRecorder.onLoad(e); }, false);