package;

import sys.FileSystem;
import haxe.io.Path;
import haxe.io.Output;
import sys.io.File;
import sys.io.FileInput;
import sys.net.Socket;
import sys.net.Host;
import sys.io.Process;
import haxe.io.Bytes;
import haxe.crypto.Sha256;

import irc.Message;

import dice.Dice;

import hex.Hex;

class Klyton {
  public static var stdout:Output;
  public static var tmp:String;
  public static var queue:String;
  public static var weatherinfo:String;
  public static var urlinfo:String;
  public static var server:String;
  public static var server_port:Int;
  public static var address:String;
  public static var inotify_port:Int;
  public static var wordlist:Array<String>;
  public static var passphrase:String;
  public static var listener:Socket;
  public static var on = "../resources/scripts/lamp/on.sh";
  public static var off = "../resources/scripts/lamp/off.sh";
  public static var irc:Socket; 
  public static var tells:String;

  public static var buffer:Bytes;

  public static var logged:Bool;
  public static var trusted:Map<String,Bool>;
  public static var history:Map<String,Array<String>>;

  public static function main() {
    stdout = Sys.stdout();

    var pwd = FileSystem.absolutePath(".");

    tmp = FileSystem.absolutePath(
      Path.join([pwd,"../tmp/"])
    );

    queue = FileSystem.absolutePath(
      Path.join([pwd,"../queues/klyton/"])
    );

    weatherinfo = FileSystem.absolutePath(
      Path.join([pwd,"../queues/weatherinfo/"])
    );

    urlinfo = FileSystem.absolutePath(
      Path.join([pwd,"../queues/urlinfo/"])
    );


    server = FileSystem.absolutePath(
      Path.join([pwd,"../config/server"])
    );
    var file:FileInput = File.read(server);
    server = file.readLine();
    file.close();

    var server_portFile = FileSystem.absolutePath(
      Path.join([pwd,"../config/server_port"])
    );
    file = File.read(server_portFile);
    server_port = Std.parseInt(file.readLine());
    file.close();

    address = FileSystem.absolutePath(
      Path.join([pwd,"../config/address"])
    );
    file = File.read(address);
    address = file.readLine();
    file.close();

    var wordlistFile = FileSystem.absolutePath(
      Path.join([pwd,"../resources/wordlist"])
    );
    wordlist = File.getContent(wordlistFile).split("\r\n");
    wordlist.pop(); //extra empty line

    passphrase = FileSystem.absolutePath(
      Path.join([pwd,"../config/passphrase"])
    );
    file = File.read(passphrase);
    passphrase = file.readLine();
    file.close();

    tells = FileSystem.absolutePath(
      Path.join([pwd,"../tells/"])
    );

    listener = new Socket();
    listener.bind(new Host(address),0);
    listener.listen(1);

    inotify_port = listener.host().port;

    var inotify_portFile = FileSystem.absolutePath(
      Path.join([pwd,"../config/inotify_port"])
    );
    var writeFile = File.write(inotify_portFile);
    writeFile.writeString('${inotify_port}\n');
    writeFile.close();

    irc = new Socket();
    irc.connect(new Host(server), server_port);

    buffer = Bytes.alloc(1024);

    logged = false;
    trusted = new Map();
    trusted["tjay"] = true;
    trusted["kittyhawk"] = true;
    history = new Map();

    while(true) {
      process();
    }

  }

  public static function process() {
    var ready = Socket.select([listener,irc],[],[]);
    for (sock in ready.read) {
      if (sock == listener) {
        var incoming = listener.accept();
        incoming.close();
        var files = FileSystem.readDirectory(queue);
        for (file in files) {
          var inFilePath = FileSystem.absolutePath(
              Path.join([queue,file])
          );
          var inFile = File.read(inFilePath);
          send('${inFile.readLine()}\r\n');
          inFile.close();
          FileSystem.deleteFile(inFilePath);
        }
      }

      if (sock == irc) {
        var line = irc.input.readLine();
        stdout.writeString('${line}\n');
        var msg = new Message(line);
        handleMessage(msg);
      }
    }
  }

  public static function handleMessage(msg:Message):Void {

    if (logged == false &&
        msg.command.command == "NOTICE" && 
        msg.command.args[0].toUpperCase() == "AUTH") {

        send("NICK klyton\r\n");
        send('USER klyton 0 * :Klyton H. FreeBot\r\n');
        logged = true;

        return;

    }

    if (msg.command.command == "PING") {
      send('PONG klyton :${msg.command.args[0]}\r\n');
      return;
    }

    //carry out any needed tells
    var hex = Hex.encode(msg.from.nick.toLowerCase().split("_").join(""));
    if (msg.command.command == "JOIN")
      hex = "";
    if (msg.command.command == "PART")
      hex = "";
    if (msg.command.command == "QUIT")
      hex = "";
    var box = FileSystem.absolutePath(
      Path.join([tells,hex])
    );
    if (hex.length > 0 && FileSystem.exists(box)) {
      var sofar = FileSystem.readDirectory(box);
      for (tell in sofar) {
        var a = FileSystem.absolutePath(
          Path.join([box,tell])
        );
        var b = FileSystem.absolutePath(
          Path.join([queue,'${hex}_${tell}'])
        );
        
        var tellFile:FileInput = File.read(a);
        var potentialTell = tellFile.readLine();
        tellFile.close();

        if (potentialTell.substring(7,potentialTell.indexOf(":")).indexOf(msg.command.args[0]) != -1) 
          FileSystem.rename(a,b);

      }
    }

    //carry out any needed whispers
    if (msg.command.command == "JOIN") {
      if (history[msg.command.args[0]] != null) {
        send('NOTICE ${msg.from.nick} :Previously on ${msg.command.args[0]}...\r\n');
        for (utterance in history[msg.command.args[0]]) {
          send('NOTICE ${msg.from.nick} :${utterance}\r\n');
        }
      }
    }

    //add PRIVMSGs to history
    if (msg.command.command == "PRIVMSG" &&
        msg.command.args[0].indexOf("#") == 0 &&
        msg.command.args[0].indexOf("#webserv") == -1) {
      var utters = history[msg.command.args[0]];
      if (utters == null) 
        history[msg.command.args[0]] = new Array();
      if (history[msg.command.args[0]].length >= 5)
        history[msg.command.args[0]].shift();
      history[msg.command.args[0]].push(
        '${msg.from.nick}: ${msg.command.args[msg.command.args.length-1]}'
      );
    }

    var payload = msg.command.args[msg.command.args.length-1];

    if (msg.command.command == "NOTICE" || 
        msg.command.command == "PRIVMSG" &&
        msg.command.args[0].toLowerCase() == "klyton" ||
        payload.toLowerCase().indexOf("klyton:") == 0) {

      var pm = true;
      if (msg.command.args[0].toLowerCase() != "klyton") {
        payload = payload.substring(8);
        pm = false;
      }

      //auth
      if (payload.split(passphrase).length == 4) {
        stdout.writeString('Trusting ${msg.from.nick}\n');
        trusted[msg.from.nick] = true;
        if (pm) {
          send('NOTICE ${msg.from.nick} :You seem trustworthy.\r\n');
        } else {
          send('NOTICE ${msg.command.args[0]} :${msg.from.nick}: You seem trustworthy.\r\n');
        }
        return;
      }

      //quote
      if (trusted[msg.from.nick] &&
          payload.indexOf("/quote ") == 0) {
        send('${payload.substring(7)}\r\n');
        return;
      }
      
      //tell
      if (payload.toLowerCase().indexOf("tell") == 0) {
        var tell = payload.substring(5);
        var frags:Array<String> = new Array();
        var to = "";
        var i = 0;
        while (i < tell.length) {
          if (tell.charAt(i) == ":") {
            to = frags.join("");
            break;
          }
          frags.push(tell.charAt(i));
          i++;
        }
        if (i < tell.length-3) {
          tell = tell.substring(i+2);
        } else {
          tell = "";
        }

        if (tell == "") return;

        if (msg.command.args[0].indexOf("#") != 0) {
          send('NOTICE ${msg.from.nick} :Sorry. I do not perform private tells.\r\n');
          return;
        }

        hex = Hex.encode(to.toLowerCase().split("_").join(""));

        //create directory if needed
        box = FileSystem.absolutePath(
          Path.join([tells,hex])
        );
        if (!FileSystem.exists(box)) 
          FileSystem.createDirectory(box);

        var sofar = FileSystem.readDirectory(box);
        i = sofar.length;
        var id = '${i}';
        while (id.length < 3)
          id = "0" + id;

        //tellLimit
        if (i >= 30) {
          if (pm) {
            send('NOTICE ${msg.from.nick} :Sorry. ${to}\'s tellbox is full.\r\n');
          } else {
            send('NOTICE ${msg.command.args[0]} :${msg.from.nick}: Sorry. ${to}\'s tellbox is full.\r\n');
          }
          return;
        }

        var nw = FileSystem.absolutePath(
          Path.join([box,id])
        );
        var nwFile = File.write(nw);
        nwFile.writeString('NOTICE ${msg.command.args[0]} :${to}, ${msg.from.nick} said to tell you: ${tell}\n');
        nwFile.close();

        if (pm) {
          send('NOTICE ${msg.from.nick} :Okay. I will.\r\n');
        } else {
          send('NOTICE ${msg.command.args[0]} :${msg.from.nick}: Okay. I will.\r\n');
        }

        return;
      }

      //dice
      if (payload.toLowerCase().indexOf("roll") == 0) {
        var roll = "";
        try {
          roll = 'Your roll resulted in ${Dice.roll(payload.substring(5))}.';
        } catch (e:Dynamic) {
          stdout.writeString('Problem rolling: ${e}.\n');
          return;
        }
        if (pm) {
          send('NOTICE ${msg.from.nick} :${roll}\r\n');
        } else {
          send('NOTICE ${msg.command.args[0]} :${msg.from.nick}: ${roll}\r\n');
        }
        return;
      }

      //adlib
      if (payload.toLowerCase().indexOf("adlib") == 0) {
        var word = wordlist[Std.random(wordlist.length)];
        if (pm) {
          send('NOTICE ${msg.from.nick} :${word}\r\n');
        } else {
          send('NOTICE ${msg.command.args[0]} :${msg.from.nick}: ${word}\r\n');
        }
        return;
      }

      //weather
      if (payload.toLowerCase().indexOf("weather") != -1) {
        var sha = Sha256.encode(payload);
        var tmpFilePath = FileSystem.absolutePath(
          Path.join([tmp,sha])
        );
        var tmpFile = File.write(tmpFilePath);
        tmpFile.writeString('${msg.from.nick}\n');
        if (pm) {
          tmpFile.writeString('${msg.from.nick}\n');
        } else {
          tmpFile.writeString('${msg.command.args[0]}\n');
        }
        tmpFile.writeString('${payload}\n');
        tmpFile.close();
        var outFilePath = FileSystem.absolutePath(
          Path.join([weatherinfo,sha])
        );
        FileSystem.rename(tmpFilePath,outFilePath);
      }

      //lamp
      if (trusted[msg.from.nick] &&
          payload.toLowerCase().indexOf("lamp") != -1) {
        if (payload.toLowerCase().indexOf("off") != -1) {
          var proc = new Process(off);
          proc.exitCode();
          proc.close();
        } else {
          var proc = new Process(on);
          proc.exitCode();
          proc.close();
        }
        return;
      }

      return;
      
    }

    //URLinfo
    if (msg.command.command == "PRIVMSG") {
      if (msg.command.args[0].toLowerCase() == "#webserv") 
        return;
      if (payload.toLowerCase().indexOf("http") == -1)
        return;
      var url = payload.substring(payload.toLowerCase().indexOf("http"));
      var i = 0;
      while (i <= url.length-1) {
        if (url.charAt(i) == " " || 
            url.charAt(i) == "\t" ||
            url.charAt(i) == "\r" ||
            url.charAt(i) == "\n")
          break;
        i++;
      }
      url = url.substring(0,i);

      stdout.writeString('Found URL: ${url}\n');

      var announce = '${msg.from.nick}\n${msg.command.args[0]}\n${url}\n';
      var sha = Sha256.encode(announce);

      var tmpFilePath = FileSystem.absolutePath(
        Path.join([tmp,sha])
      );
      var tmpFile = File.write(tmpFilePath);
      tmpFile.writeString(announce);
      tmpFile.close();

      var urlFilePath = FileSystem.absolutePath(
        Path.join([urlinfo,sha])
      );
      FileSystem.rename(tmpFilePath,urlFilePath);

      return;
    }

  }

  public static function send(msg:String) {
    stdout.writeString(msg);
    irc.output.writeString(msg);
  }

}
