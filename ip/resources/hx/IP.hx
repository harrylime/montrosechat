package;

import php.Lib.print;
import php.Web;

class IP {
  public static function main():Void {
    Web.setReturnCode(200);
    Web.setHeader("Content-Type","text/javascript");
    print('document.ip = "${Web.getClientIP()}";');
  }
}
