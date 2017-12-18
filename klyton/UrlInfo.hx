package;

import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;
import haxe.Http;
import haxe.io.Input;
import haxe.io.Output;
import haxe.Json;
import haxe.crypto.Sha256;
import sys.net.Host;
import haxe.io.Bytes;
import sys.io.Process;
import haxe.io.Eof;

class UrlInfo {
    public static var stdout:Output;
    public static var stdin:Input;
    public static var outgoing:String;
    public static var tmp:String;
    public static var span:Int = 8192;
    public static var buffer:Bytes;

  public static function main() {
    stdout = Sys.stdout();
    stdin = Sys.stdin();

    var pwd = FileSystem.absolutePath(".");
    var queue = FileSystem.absolutePath(
      Path.join([pwd,"../queues/urlinfo/"])
    );
    outgoing = FileSystem.absolutePath(
      Path.join([pwd,"../queues/klyton/"])
    );
    tmp = FileSystem.absolutePath(
      Path.join([pwd,"../tmp/"])
    );


    buffer = Bytes.alloc(span);
    var files:Array<String>;
    while(true) {
      stdin.readLine(); //ignored
      files = FileSystem.readDirectory(queue);
      for (file in files) {
        var filePath = FileSystem.absolutePath(
          Path.join([queue,file])
        );
        var input = File.read(filePath);
        var from = input.readLine();
        var to = input.readLine();
        var query = input.readLine();
        input.close();
        FileSystem.deleteFile(filePath);

        process(to,query);
      }
    }

  }

  public static function process(to:String,query:String) {
    var prefix = query.substring(0,5).toLowerCase();
    var sock:sys.net.Socket;
    var port = 80;
    if (prefix == "https") {
      var sslSock = new sys.ssl.Socket();
      sslSock.verifyCert = false;
      sock = sslSock;
      port = 443;
    } else {
      sock = new sys.net.Socket();
    }

    var frags = query.split("/");
    var host = "";
    if (frags.length > 2) host = frags[2];
    frags.shift();
    frags.shift();
    frags.shift();
    var req = '/${frags.join("/")}';
    if (req.indexOf("#") != -1) {
      req = req.substring(0,req.indexOf("#"));
    }

    var id = "";
    if (host.indexOf("youtube.com") != -1) {
      var vid = req.indexOf("?v=");
      if (vid == -1) 
        vid = req.indexOf("&v=");
      if (vid != -1) {
        vid = vid + 3;
        if (vid < req.length) {
          var sub = req.substring(vid);
          var amp = sub.indexOf("&");
          if (amp != -1) {
            id = sub.substring(0,amp);
          } else {
            id = sub;
          }
        }
      }
    }
    if (query.indexOf("https://youtu.be/") == 0) {
      id = StringTools.replace(req,"/","");
    }
    id = StringTools.replace(id,"'","");

    try {
      var buf = "";
      var title = "";
      if (id == "") {
        sock.connect(new Host(host),port);
        sock.output.writeString('GET ${req} HTTP/1.0\r\n');
        sock.output.writeString('Host: ${host}\r\n');
        sock.output.writeString('Referer: http://montrose.is/\r\n');
        sock.output.writeString("\r\n");


        var bufFrags:Array<String> = new Array();
        var totalRead = 0;
        var sizeRead = 0;
        var str:String;
        do {
          try {
            sizeRead = sock.input.readBytes(buffer,0,span);
          } catch (e:Dynamic) {
            break;
          }
          totalRead = totalRead + sizeRead;
          str = buffer.getString(0,sizeRead);
          bufFrags.push(str);
        } while (totalRead < span && sizeRead != 0);
        buf = bufFrags.join("");
        //stdout.writeString('Read in: ${buf.length}\n${buf}');

      } else {
        var proc = new Process(
          "youtube-dl --get-title --skip-download 'https://www.youtube.com/watch?v=" + id + "'"
        );
        title = proc.stdout.readLine();
        proc.close();
      }

      sock.close();

      var frags = buf.split("\r\n");
      var length = 0;
      var content = "";
      for (frag in frags) {
        if (frag.indexOf("Content-Type:") == 0)
          content = frag.substring(14);
        if (frag.indexOf("Content-Length:") == 0)
          length = Std.parseInt(frag.substring(15));
      }

      var search = buf.toLowerCase();
      var openTitle = search.indexOf("<title>");
      var closeTitle = search.indexOf("</title>");
      if (title == "" && openTitle != -1 && closeTitle != -1)
        title = buf.substring(openTitle+7,closeTitle);
      title = StringTools.replace(title,"\r","");
      title = StringTools.replace(title,"\n","");

      stdout.writeString('URL: ${query}\n');
      stdout.writeString('title: ${title}\n');
      stdout.writeString('content: ${content}\n');
      stdout.writeString('length: ${length}\n');
      stdout.writeString('id: ${id}\n\n');

      var msg = "";
  
      if (id != "") {
        msg = 'NOTICE #webserv :youtube ${to} ${query} ${title}';
        if (title != "")
          send('NOTICE ${to} :${query} ${title}');
      }

      if (id == "" && content.indexOf("image") != -1 && length < 1048576) {
        msg = 'NOTICE #webserv :image ${to} ${query}';
      }

      if (id == "" && content.indexOf("image") == -1) {
        msg = 'NOTICE #webserv :link ${to} ${query} ${title}';
        if (title != "")
          send('NOTICE ${to} :${query} ${title}');
      }

      if (msg != "") send(msg);

    } catch (e:Dynamic) {
      stdout.writeString('Problem getting URL info: ${e}\n');
    }

  }

  public static function send(msg:String) {
    var sha = Sha256.encode(msg);
    var tmpFilePath = FileSystem.absolutePath(
      Path.join([tmp,sha])
    );
    var outFilePath = FileSystem.absolutePath(
      Path.join([outgoing,sha])
    );
    var tmpFile = File.write(tmpFilePath);
    tmpFile.writeString(msg);
    tmpFile.close();
    FileSystem.rename(tmpFilePath,outFilePath);
  }

}
