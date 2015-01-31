// Generated by CoffeeScript 1.6.3
(function() {
  var EXAMPLEINPUT, keyboardrows, root, visualizekeyboard;

  keyboardrows = ["1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"];

  EXAMPLEINPUT = {
    "W": "up",
    "S": "down"
  };

  visualizekeyboard = function(mappings) {
    var key, output, row, text, _i, _j, _len, _len1;
    output = "<div class='keyboardlayout'>";
    for (_i = 0, _len = keyboardrows.length; _i < _len; _i++) {
      row = keyboardrows[_i];
      output += "<div>";
      for (_j = 0, _len1 = row.length; _j < _len1; _j++) {
        key = row[_j];
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