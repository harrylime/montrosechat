package hex;

class Hex {
  static public function main():Void {
    var cases:Array<String> = ["This is a test.",
                               "So is this.",
                               "And this...",
                               "!@#$%^&*()_+",
                              ];
    for (cse in cases) {
      trace('${cse}: ${encode(cse)} ${decode(encode(cse))}');
    }
  }

  static public function encode(raw:String):String {
    var out:Array<String> = new Array();
    for (i in 0...raw.length) {
      var c:Int = raw.charCodeAt(i);
      var h:Int = c >> 4;
      var l:Int = c & 15;
      if (h > 9) h = h + 7; //difference between A and 0 is 17 (+17-10)
      if (l > 9) l = l + 7;
      h = h + 48; //0-9 starts at 48
      l = l + 48;
      out.push(String.fromCharCode(h));
      out.push(String.fromCharCode(l));
    }
    return out.join("");
  }

  static public function decode(enc:String):String {
    var out:Array<String> = new Array();
    var i = 0;
    while ((i+1) < enc.length) {
      var h = enc.charCodeAt(i);
      var l = enc.charCodeAt(i+1);

      i = i + 2;

      if (h < 48 || l < 48) continue;
      if (h > 57 && h < 65 || l > 57 && l < 65) continue;
      if (h > 70 || l > 70) continue;

      if (h > 57) h = h - 7; //65 (A) - 48 (0) = 17 7 = 17-10 (0-9)
      if (l > 57) l = l - 7;
      h = h - 48;
      l = l - 48;
      
      var c:Int = h << 4;
      c = c + l;
      out.push(String.fromCharCode(c));
    }
    return out.join("");
  }
}
