package;

import sys.FileSystem;
import haxe.io.Path;
import sys.io.File;
import sys.io.FileInput;
import haxe.Http;
import haxe.io.Input;
import haxe.io.Output;
import haxe.Json;
import haxe.crypto.Sha256;

class WeatherInfo {
    public static var stdout:Output;
    public static var stdin:Input;
    public static var outgoing:String;
    public static var tmp:String;
    public static var appid:String;

  public static function main() {
    stdout = Sys.stdout();
    stdin = Sys.stdin();

    var pwd = FileSystem.absolutePath(".");
    var queue = FileSystem.absolutePath(
      Path.join([pwd,"../queues/weatherinfo/"])
    );
    outgoing = FileSystem.absolutePath(
      Path.join([pwd,"../queues/klyton/"])
    );
    tmp = FileSystem.absolutePath(
      Path.join([pwd,"../tmp/"])
    );

    appid = FileSystem.absolutePath(
      Path.join([pwd,"../config/appid"])
    );
    var file:FileInput = File.read(appid);
    appid = file.readLine();
    file.close();

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

        process(from,to,query);
      }
    }

  }

  public static function process(from:String,to:String,query:String) {
    var frags = ['https://api.wolframalpha.com/v2/query?appid=${appid}&output=JSON&format=plaintext&includepodid=InstantaneousWeather:WeatherData&input=',""];
    frags[1] = StringTools.urlEncode(query);
    var url = frags.join("");

    var answer = "";
    try {
      var json = Json.parse(Http.requestUrl(url));
      if (Reflect.hasField(json,"queryresult") &&
          Reflect.hasField(json.queryresult,"pods") &&
          Reflect.hasField(json.queryresult.pods[0],"title") &&
          Reflect.hasField(json.queryresult.pods[0],"subpods") &&
          Reflect.hasField(json.queryresult.pods[0].subpods[0],"plaintext")) {
        var title = json.queryresult.pods[0].title;
        var info = json.queryresult.pods[0].subpods[0].plaintext;
        info = StringTools.replace(info," |",":");
        info = StringTools.replace(info,"\n"," | ");
        info = StringTools.replace(info," \xc2\xb0","");
        answer = '${title}: ${info}';
      } else {
        answer = "I'm having trouble with finding that.";
      }
      var msg:String;
      if (to == "klyton") {
        msg = 'NOTICE ${from} :${answer}'; 
      } else {
        msg = 'NOTICE ${to} :${from}: ${answer}'; 
      }
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

    } catch(e:Dynamic) {
      stdout.writeString('Problem with query: ${e}\n');
    }

  }

}
