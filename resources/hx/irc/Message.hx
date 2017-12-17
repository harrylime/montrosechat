package irc;

import irc.From;
import irc.Replies;

typedef Command = {
  var command:String;
  var args:Array<String>;
}

class Message {
  public var from:From;
  public var command:Command;

  public function new(str:String) {
    var buf:Array<String>;
    var chr:String = "";

    var i = 0;
    var len = str.length;
    command = {command: "", args: new Array()};

    buf = new Array();
    if (str.charAt(0) == ":") {
      while(i < len) {
        chr = str.charAt(i++);
        if (chr == " ") break;
        buf.push(chr);
      }
    }
    from = new From(buf.join(""));

    buf = new Array();
    while(i < len) {
      chr = str.charAt(i++);
      if (chr == " ") break;
      buf.push(chr);
    }
    command.command = buf.join("");

    var reply = Replies.replies[command.command];
    if (reply != null) command.command = reply;

    command.command = command.command.toUpperCase();

    buf = new Array();
    while(i < len) {
      chr = str.charAt(i++);
      if (chr == " ") {
        command.args.push(buf.join(""));
        buf = new Array();
      }
      if (chr == ":") break;
      buf.push(chr);
    }

    if (buf.length > 0)
      command.args.push(buf.join(""));

    if (i >= len) return;

    command.args.push(str.substring(i));

  }
}
