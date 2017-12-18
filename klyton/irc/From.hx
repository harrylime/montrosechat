package irc;

class From {
  public var nick:String = "";
  public var user:String = "";
  public var host:String = "";

  public function new(str:String) {
    var len = str.length;
    if (len == 0) return;

    var i = 0;
    if (str.charAt(0) == ":") i = 1;
    var buf:Array<String>;
    var chr:String = "";

    buf = new Array();
    while (i < len) {
      chr = str.charAt(i++);
      if (chr == "!" || chr == "@") break;
      buf.push(chr);
    }
    nick = buf.join("");

    if (chr == "!") {
      buf = new Array();
      while (i < len) {
        chr = str.charAt(i++);
        if (chr == "@") break;
        buf.push(chr);
      }
      user = buf.join("");
    }

    buf = new Array();
    while (i < len) 
      buf.push(str.charAt(i++));
    host = buf.join("");

    if (nick.indexOf(".") != -1) {
      host = nick;
      nick = "";
    }

  }
}
