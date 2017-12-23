package;

import irc.Message;

import Externs;

using StringTools;

using Chat.Softener;
using Chat.Scrubber;
using Chat.OWASP;

@:expose class Softener {
  static public var softener:String = "<wbr/>";
  static public function soften(str:String):String {
    var words = str.split(" ");
    var newWords:Array<String> = [];
    for (word in words) {
      if (word.length > 32) 
        word = word.split("").join(softener);
      newWords.push(word);
    }
    return newWords.join(" ");
  }
}

@:expose class Scrubber {
  static public function scrub(str:String):String {
    var clean:Array<String> = [];
    var i = 0;
    while (i < str.length) {
      var letter = str.charAt(i);
      var code = str.charCodeAt(i);

      if (code < 2 || code > 31) {
        clean.push(letter);
        i++;
        continue;
      }

      if (code != 3) {
        i++;
        continue;
      }

      if (str.charCodeAt(i+1) < 48 ||
          str.charCodeAt(i+1) > 57) {
        i++;
        continue;
      }

      i++;

      if (str.charCodeAt(i+1) >= 48 &&
          str.charCodeAt(i+1) <= 57) i++;

      if (str.charAt(i+1) != ",") {
        i++;
        continue;
      }

      i++;

      if (str.charCodeAt(i+1) < 48 ||
          str.charCodeAt(i+1) > 57) continue;

      i++;

      if (str.charCodeAt(i+1) < 48 ||
          str.charCodeAt(i+1) > 57) {
        i++;
        continue;
      }

      i = i + 2;

    }
    return clean.join("");
  }
}

@:expose class OWASP {
  static public function mincode(str:String):String {
    var strings = str.split(Softener.softener);
    var mincoded:Array<String> = [];
    for (string in strings) {
      mincoded.push(
        string.split("&").join("&amp;").split("<").join("&lt;").split(">").join("&gt;").split('"').join("&quot;").split("'").join("&#x27;").split("/").join("&#x2F;")
      );
    }
    return mincoded.join(Softener.softener);
  }

  static public function fix(str:String):String {
    return str.scrub().soften().mincode();
  }
}



class Post {
  public var message:String;
  private var chat:Chat;
  private var document:Document;

  public function new(msg:String, cht:Chat, doc:Document) {
    message = msg;
    chat = cht;
    document = doc;
  }

}

class ServerPost extends Post {
  public function new(msg:String, cht:Chat, doc:Document) {
    super(msg,cht,doc);
    var div = document.createElement("div");
    div.innerHTML = msg.fix();
    div.setAttribute("class","ServerPost chat");
    chat.chat.appendChild(div);
    chat.bottomOut();
  }
}

class NoticePost extends Post {
  public function new(msg:Message, cht:Chat, doc:Document) {
    super("",cht,doc);
    var div = document.createElement("div");
    var txt = msg.command.args[msg.command.args.length-1].fix();
    var ctrlA = String.fromCharCode(1);
    var split = txt.indexOf(': ${ctrlA}ACTION');
    if (split != -1) {
      txt = txt.split(ctrlA).join("");
      div.innerHTML = '-${msg.from.nick}- * ${txt.substring(0,split)} ${txt.substring(split+9)}';
    } else {
      div.innerHTML = '-${msg.from.nick}- ${txt}';
    }
    div.setAttribute("class","NoticePost chat");
    chat.chat.appendChild(div);
    chat.bottomOut();
    if (msg.command.args[msg.command.args.length-1].toLowerCase().split("_").join("").indexOf(chat.nick.toLowerCase().split("_").join("")) != -1) {
      chat.playMention();
    } else {
      chat.playMessage();
    }
  }
}

class PlainPost extends Post {
  public function new(msg:Message, cht:Chat, doc:Document) {
    super("",cht,doc);
    var div = document.createElement("div");
    var txt = msg.command.args[msg.command.args.length-1].fix();
    var ctrlA = String.fromCharCode(1);
    if (txt.indexOf('${ctrlA}ACTION') != -1) {
      txt = txt.split('${ctrlA}ACTION').join("").split(ctrlA).join("");
      div.innerHTML = '<i>* ${msg.from.nick} ${txt}</i>';
    } else {
      div.innerHTML = '<b>${msg.from.nick}:</b> ${txt}';
    }
    div.setAttribute("class","PlainPost chat");
    chat.chat.appendChild(div);
    chat.bottomOut();
    if (txt.toLowerCase().split("_").join("").indexOf(chat.nick.toLowerCase().split("_").join("")) != -1) {
      chat.playMention();
    } else {
      chat.playMessage();
    }
  }
}

class SelfPost extends Post {
  public function new(msg:String, cht:Chat, doc:Document) {
    super(msg,cht,doc);
    var div = document.createElement("div");
    div.innerHTML = msg; //we don't care what awfulness you do with your own client.
    div.setAttribute("class","SelfPost chat");
    chat.chat.appendChild(div);
    chat.bottomOut();
  }
}

class LinkPost extends Post {
  public function new(msg:Message, cht:Chat, doc:Document) {
    super("",cht,doc);
    var payload = msg.command.args[msg.command.args.length-1];
    var frags = payload.split(" ");
    if (frags.length < 2) return;
    var url = frags[2];
    var txt = url;
    if (frags.length > 2) 
      txt = frags.slice(3).join(" ");
    if (txt == "")
      txt = url;
    var div = document.createElement("div");
    div.appendChild(
      document.createTextNode('-${msg.from.nick}- ')
    );
    var a:LinkElement = cast document.createElement("a");
    a.href = url;
    a.target = "_blank";
    a.innerHTML = txt.fix();
    a.setAttribute("class","chat");
    div.appendChild(a);
    div.setAttribute("class","LinkPost NoticePost chat");
    chat.chat.appendChild(div);
    chat.bottomOut();
  }
}

class ImagePost extends Post {
  public function new(src:String, link:String, cht:Chat, doc:Document) {
    super(src,cht,doc);

    var img:ImageElement = cast document.createElement("img");
    img.src = src;
    img.setAttribute("class","aspectContent");

    var a:LinkElement = cast document.createElement("a");
    a.href = link;
    a.target = "_blank";
    img.setAttribute("class","aspectContent");
    a.appendChild(img);

    var aspect = document.createElement("div");
    aspect.setAttribute("class","aspect");
    aspect.setAttribute("style","padding: 75% 0 0 0;");
    aspect.appendChild(a);

    var div = document.createElement("div");
    div.setAttribute("class","ImagePost chat");
    div.appendChild(aspect);

    chat.chat.appendChild(div);
    chat.bottomOut();
  }
}

class ToggleButton {
  public var state(default, null):Bool;
  private var prefix:String;
  private var image:ImageElement;
  private var path:String = "resources";

  public function new(prfx:String, start:Bool, doc:Document) {
    prefix = prfx;
    var element = doc.getElementById('${prefix}Button');
    image = cast element.firstElementChild;
    element.onclick = function(e:Event) {
      e.preventDefault();
      toggle();
    }
    state = !start;
    toggle();
  }

  public function toggle() {
    state = !state;
    var power = "on";
    if (!state) power = "off";
    image.src = '${path}/svg/${prefix}_${power}.svgz';
  }

}

class ToggleSound extends ToggleButton {
  private var chat:Chat;
  private var sounds:Element;
  private var document:Document;

  public function new(prfx:String, start:Bool, cht:Chat, doc:Document) {
    chat = cht;
    document = doc;
    sounds = document.getElementById("sounds");
    super(prfx,start,doc);
  }

  public override function toggle() {
    sounds.innerHTML = "";
    chat.message = null;
    chat.mention = null;

    var goal = !state; //i.e. we're transition *to* !state
    if (goal) {
      var details = [
        {id:"messageSound",
          media:[
                  {file: '${path}/mp3/message.mp3', type: "audio/mpeg"},
                  {file: '${path}/ogg/message.ogg', type: "audio/ogg; codecs=vorbis"},
                ],
        },
        {id:"mentionSound",
          media:[
                  {file: '${path}/mp3/mention.mp3', type: "audio/mpeg"},
                  {file: '${path}/ogg/mention.ogg', type: "audio/ogg; codecs=vorbis"},
                ],
        },
      ];
      for (snd in details) {
        var sound:SoundElement = cast document.createElement("audio");
        sound.id = snd.id;
        for (media in snd.media) {
          var med:SourceElement = cast document.createElement("source");
          med.src = media.file;
          med.type = media.type;
          sound.appendChild(med);
        }
        sound.preload = "auto";
        sounds.appendChild(sound);
      }
      chat.message = cast document.getElementById("messageSound");
      chat.mention = cast document.getElementById("mentionSound");
    }

    super.toggle();
  }

}

@:expose class Chat {
  public var version = "0.0.6";
  public var message:Null<SoundElement>;
  public var mention:Null<SoundElement>;

  private var ip:String;
  private var chan:String;
  public var nick:String;
  private var connected:Bool;
  private var authorized:Bool;
  private var websocket:Null<WebSocket>;

  private var window:Window;
  private var document:Document;

  private var soundToggle:ToggleButton;
  private var picToggle:ToggleButton;
  private var usersButton:Element;

  private var resizeHandler:Null<Int>;
  private var reconnectHandler:Null<Int>;

  private var cli:InputElement;
  private var nickInput:InputElement;
  private var connectButton:Element;
  private var usersRequested:Bool;

  private var prelude:Element;

  public var chat:Element;
  private var userlist:Element;

  public function new(chn:String,win:Window) {
    chan = chn;
    window = win;
    document = window.document;
    ip = document.ip;

    connected = false;
    authorized = false;
    usersRequested = true;

    soundToggle = new ToggleSound("sound",false,this,document);
    picToggle = new ToggleButton("pic",true,document);

    var element;
    element = document.getElementById("usersButton");
    usersButton = element;
    element.onclick = function(e) {
      e.preventDefault();
      users();
    }

    connectButton = document.getElementById("connectButton");
    connectButton.onclick = function(e) {
      e.preventDefault();
      login();
    }

    nickInput = cast document.getElementById("nickInput");
    nickInput.value = 'chatMonkey${Math.round(Math.random()*9)}${Math.round(Math.random()*9)}${Math.round(Math.random()*9)}';
    cli = cast document.getElementById("prompt");
    window.onkeypress = function(e) {
      if (e.charCode != 13 && e.which != 13) return;
      e.preventDefault();
      if (document.activeElement == cli) {
        parse(cli.value);
        cli.value = "";
        window.scrollTo(window.scrollX,window.scrollY);
        window.setTimeout(bottomOut,250);
      }
      if (document.activeElement == nickInput ||
          document.activeElement == connectButton) {
        login();
      }
    }

    window.onbeforeunload = quit;

    prelude = document.getElementById("prelude");
    chat = document.getElementById("chat");
    userlist = document.getElementById("userlist");

    window.addEventListener("resize", function(ign) {
      if (resizeHandler != null) window.clearTimeout(resizeHandler);
      resizeHandler = window.setTimeout(function() {
        checkSize();
      },250);
    });
    checkSize();

  }

  private function parse(input:String) {
    if (!connected) return;
    if (input.toLowerCase().indexOf("/quote ") == 0) {
      websocket.send('${input.substring(7)}\r');
      return;
    }
    if (input.toLowerCase().indexOf("/nick ") == 0) {
      websocket.send('NICK ${input.substring(6)}\r');
      return;
    }
    if (input.toLowerCase().indexOf("/topic") == 0) {
      websocket.send('TOPIC #${chan}\r');
      return;
    }
    if (input.toLowerCase().indexOf("/clear") == 0) {
      var posts = document.getElementsByClassName("chat");
      while(posts.length > 0) {
        posts[0].parentNode.removeChild(posts[0]);
        posts = document.getElementsByClassName("chat");
      }
      new SelfPost("<br/>",this,document);
      new ServerPost("Cleared chat backlog.",this,document);
      return;
    }
    if (input.toLowerCase().indexOf("/me ") == 0) {
      var ctrlA = String.fromCharCode(1);
      websocket.send('PRIVMSG #${chan} :${ctrlA}ACTION ${input.substring(4)}${ctrlA}\r');
      new SelfPost('<i class="self">* ${nick} ${input.substring(4).fix()}</i>',this,document);
      return;
    }
    if (input.toLowerCase().indexOf("/xyzzy") == 0) {
      new ServerPost("Nothing happens.",this,document);
      return;
    }
    if (input.toLowerCase().indexOf("/") == 0) {
      new ServerPost("Commands are: /me , /nick , /topic , /clear , and /quote .",this,document);
      return;
    }
    if (input.length < 1) return;
    websocket.send('PRIVMSG #${chan} :${input}\r');
    new SelfPost('<span class="self"><b>${nick}</b>:</span> ${input.fix()}',this,document);
  }

  public function playMessage() {
    if (!soundToggle.state) return;
    message.load();
    message.play();
  }

  public function playMention() {
    if (soundToggle.state) {
      mention.load();
      mention.play();
    }
  }

  private function login() {
    var nickc = nickInput.value;
    var newChars:Array<String> = [];
    for (i in 0...nickc.length) {
      var chr = nickc.charAt(i);
      var code = nickc.charCodeAt(i);
      if (newChars.length == 0 &&
          (code < 65 || 
           code > 90 && code < 97 ||
           code > 122))
        newChars.push("x");
      if ((code > 64 && code < 126) ||
          (code > 47 && code < 58))
        newChars.push(chr);
    }
    nick = newChars.join("");
    var widget = document.getElementById("connectionWidget");
    widget.parentNode.removeChild(widget);
    new SelfPost("<br/>",this,document);
    if (!soundToggle.state) 
      new ServerPost("Chat sounds muted. Click upper-left bell icon to unmute.",this,document);
    connect();
  }

  private function connect() {
    new ServerPost('montrosechat version ${version}.',this,document);
    new ServerPost("Attempting to connect.",this,document);
    websocket = new WebSocket('ws://${document.location.host}/irc');
    websocket.onopen = onopen;
    websocket.onmessage = onmessage;
    websocket.onerror = onerror;
    websocket.onclose = onclose;
  }

  private function onopen() {
    new ServerPost("Connection successful.",this,document);
    new ServerPost("Attempting to authenticate.",this,document);
  }

  private function onmessage(raw:MessageEvent) {
    trace('in: ${raw.data}');

    var msg = new Message(raw.data);

    if (msg.command.command == "PING") {
      websocket.send('PONG ${nick} :${msg.command.args[0]}\r');
      return;
    }

    if (authorized == false &&
        msg.command.command == "NOTICE" && 
        msg.command.args[0].toUpperCase() == "AUTH") {

      websocket.send('NICK ${nick}\r');
      websocket.send('USER ${nick} 0 * :Onion Knight [${ip}] v${version}\r');
      new ServerPost("Authenticated.",this,document);
      authorized = true;
      websocket.send('JOIN #webserv\r');
      websocket.send('JOIN #${chan}\r');

      new ServerPost('Joining #${chan}. This may take a few moments...',this,document);

      return;
    }

    if (msg.command.command == "JOIN" &&
        msg.command.args[0].indexOf('#${chan}') != -1 &&
        msg.from.nick == nick) {
      connected = true;
      new ServerPost('Joined #${chan}. You are now chatting live!',this,document);
      return;
    }

    if (msg.command.command == "ERR_NICKNAMEINUSE") {
      nick += "_";
      new ServerPost("Nickname is already in use.",this,document);
      return;
    }

    if (msg.command.command == "NOTICE" &&
        msg.from.nick == "" || msg.from.nick == "Global") return;

    if (msg.command.command == "RPL_TOPIC" &&
        msg.command.args[1].indexOf('#${chan}') != -1) {
      new ServerPost('Channel topic: ${msg.command.args[msg.command.args.length-1]}',this,document);
      return;
    }

    if (msg.command.command == "RPL_TOPIC" &&
        msg.command.args[1].indexOf("#webserv") != -1) {
      special(msg);
      return;
    }

    if (msg.command.command == "TOPIC" &&
        msg.command.args[0].indexOf('#${chan}') != -1) {
      new ServerPost('Channel topic: ${msg.command.args[msg.command.args.length-1]}',this,document);
      return;
    }

    if (msg.command.command == "TOPIC" &&
        msg.command.args[0].indexOf("#webserv") != -1) {
      special(msg);
      return;
    }

    if (msg.command.command == "JOIN" &&
        msg.command.args[msg.command.args.length-1].indexOf('#${chan}') != -1) {
      new ServerPost('${msg.from.nick} joined.',this,document);
      websocket.send('NAMES #${chan}\r');
      return;
    }

    if (msg.command.command == "PART" &&
        msg.command.args[msg.command.args.length-1].indexOf('#${chan}') != -1) {
      new ServerPost('${msg.from.nick} left.',this,document);
      websocket.send('NAMES #${chan}\r');
      return;
    }

    if (msg.command.command == "NICK") {
      if (userlist.innerHTML.indexOf(msg.from.nick) == -1) return;
      if (nick == msg.from.nick) nick = msg.command.args[msg.command.args.length-1];
      new ServerPost('${msg.from.nick}  is now known as ${msg.command.args[msg.command.args.length-1]}.',this,document);
      websocket.send('NAMES #${chan}\r');
      return;
    }

    if (msg.command.command == "MODE") {
      websocket.send('NAMES #${chan}\r');
      return;
    }

    if (msg.command.command == "QUIT") {
      if (userlist.innerHTML.indexOf(msg.from.nick) == -1) return;
      new ServerPost('${msg.from.nick} has left.',this,document);
      websocket.send('NAMES #${chan}\r');
      return;
    }

    if (msg.command.command == "NOTICE" &&
        msg.from.nick == "klyton") {
      if (userlist.innerHTML.indexOf("@klyton") != -1) {
        if (special(msg)) return;
      }
      new NoticePost(msg,this,document);
      return;
    }

    if (msg.command.command == "NOTICE" &&
        msg.command.args[0].indexOf('#${chan}') != -1) {
      new NoticePost(msg,this,document);
      return;
    }

    if (msg.command.command == "PRIVMSG" &&
        msg.command.args[0].indexOf('#${chan}') != -1) {
      new PlainPost(msg,this,document);
      return;
    }

    if (msg.command.command == "NOTICE" ||
        msg.command.command == "PRIVMSG") {
      websocket.send('NOTICE ${msg.from.nick} :This IRC client cannot accept direct messages. Please ask them to upgrade their IRC client.\r');
    }

    if (msg.command.command == "RPL_NAMREPLY" &&
        msg.command.args[2].indexOf('#${chan}') != -1) {

      var names = msg.command.args[msg.command.args.length-1];
      var list = names.split(" ");
      var html:Array<String> = [];
      for (name in list) {
        html.push('<br/>${name.fix()}');
      }
      userlist.innerHTML = html.join("");

      if (!usersRequested) return;
      new ServerPost(
        'Currently chatting: ${names}',
        this,document
      );
      usersRequested = false;
      return;
    }

    if (msg.command.command == "RPL_TOPICWHOTIME" ||
        msg.command.command == "RPL_ENDOFNAMES") return;

    if (!connected) return;

    if (msg.from.nick.length != 0) return;

    new ServerPost(
      '${msg.command.command}: ${msg.command.args.join(" ")}',
      this,document
    );

  }

  private function onerror(e:ErrorEvent) {
    new ServerPost('Connection Error: ${e.data}',this,document);
  }

  private function onclose(e:CloseEvent) {
    connected = false;
    authorized = false;
    usersRequested = true;
    new ServerPost("Connection failed.",this,document);
    new ServerPost("Reconnecting in 20 seconds...",this,document);
    if (reconnectHandler != null) window.clearTimeout(reconnectHandler);
    reconnectHandler = window.setTimeout(function() {
      new ServerPost("Attempting to reconnect.",this,document);
      connect();
    },20000);
  }

  private function special(msg:Message):Bool {
    var payload = msg.command.args[msg.command.args.length-1];

    if (payload.indexOf("http://") == 0 ||
        payload.indexOf("https://") == 0) {
      return true;
    }

    if (payload.indexOf("link ") == 0) {
      if (payload.indexOf('#${chan}') == -1) return true;
      new LinkPost(msg,this,document);
      return true;
    }

    if (payload.indexOf("image ") == 0) {
      if (payload.indexOf('#${chan}') == -1) return true;
      if (!picToggle.state) {
        new LinkPost(msg,this,document);
        return true;
      }
      var frags = payload.split(" ");
      if (frags.length < 2) return true;
      var img = frags[2];
      new ImagePost(img,img,this,document);
      return true;
    }

    if (payload.indexOf("youtube ") == 0) {
      if (payload.indexOf('#${chan}') == -1) return true;
      var id = "";
      var frags = payload.split(" ");
      if (frags.length < 2) return true;
      var link = frags[2];
      frags = link.split("v=");
      if (frags.length > 1) id = frags[1];
      if (id == "") frags = link.split("youtu.be/");
      if (id == "" && frags.length > 1) id = frags[1];
      if (id == "") return true;
      id = id.split("?")[0];
      var img = 'http://i3.ytimg.com/vi/${id}/hqdefault.jpg';
      if (picToggle.state)
        new ImagePost(img,link,this,document);
      new LinkPost(msg,this,document);
      return true;
    }

    if (payload.indexOf("stream ") == 0) {
      if (payload.indexOf('#${chan}') == -1) return true;
      var frags = payload.split(" ");
      if (frags.length < 3) return true;
      if (frags[1].indexOf('#${chan}') == -1) return true;
      var player:VideoElement = cast document.getElementById("player");
      player.pause();
      player.parentNode.innerHTML = '<video id="player" class="aspectContent" width="848" height="480" preload="none" autoplay="true" controls playsinline></video>';
      player = cast document.getElementById("player");
      var url = frags[2];
      if (url.indexOf("stop") == 0) {
        disable("streaming");
      } else {
        enable("streaming");
      }
      if(Hls.isSupported()) {
        var hls = new Hls();
        hls.loadSource(url);
        hls.attachMedia(player);
        hls.on(Hls.Events.MANIFEST_PARSED,function() {
          player.play();
        });
      } else {
        var src:SourceElement = cast document.createElement("source");
        src.type = "application/x-mpegURL";
        src.src = url;
        player.appendChild(src);
      }
      return true;
    }

    if (payload.indexOf("script ") == 0) {
      if (payload.indexOf('#${chan}') == -1) return true;
      return true;
    }

    return false;

  }

  private function quit(e:BeforeUnloadEvent):Null<String> {
    if (websocket == null) return null;
    var dialog = "Leave the chat?";
    e.returnValue = dialog;
    return dialog;
  }

  public function bottomOut() {
    window.scrollTo(window.scrollX, document.body.scrollHeight);
  }

  private function users() {
    if (!connected) return;
    if (usersRequested) return;
    usersRequested = true;
    websocket.send('NAMES #${chan}\r');
  }

  private function checkSize() {
    if (window.innerWidth >= 1280) {
      enable("userlist");
      usersButton.setAttribute("style","display: none;");
    } else {
      disable("userlist");
      usersButton.setAttribute("style","");
    }
    prelude.setAttribute("style",'height: ${window.innerHeight}px;');
    bottomOut();
  }

  private function replaceClass(cls:String,from:String,to:String):Void {
    var elements = document.getElementsByClassName(cls);
    for (element in elements)
      element.setAttribute("class",element.getAttribute("class").replace(from,to));
  }

  public function enable(cls:String) {
    replaceClass(cls,"disabled","enabled");
  }

  public function disable(cls:String) {
    replaceClass(cls,"enabled","disabled");
  }

}
