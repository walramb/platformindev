// Generated by CoffeeScript 1.10.0
(function() {
  var EXAMPLEINPUT, keyboardrows, root, visualizekeyboard;

  keyboardrows = ["1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];

  EXAMPLEINPUT = {
    "W": "up",
    "S": "down"
  };

  visualizekeyboard = function(mappings) {
    var i, j, key, len, len1, output, row, text;
    output = "<div class='keyboardlayout'>";
    for (i = 0, len = keyboardrows.length; i < len; i++) {
      row = keyboardrows[i];
      output += "<div>";
      for (j = 0, len1 = row.length; j < len1; j++) {
        key = row[j];
        if (mappings[key] != null) {
          text = mappings[key];
          output += "<span class='highlight' title='" + text + "'>" + key + "</span>";
        } else {
          output += "<span>" + key + "</span>";
        }
      }
      output += "</div>";
    }
    return output;
  };

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  root.keyboardlayout = {};

  root.keyboardlayout.visualize = visualizekeyboard;

}).call(this);

//# sourceMappingURL=keyboarddisplay.js.map