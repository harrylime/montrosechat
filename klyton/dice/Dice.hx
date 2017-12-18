package dice;

class Dice {
  public static function roll(exp:String):Int {
    exp = exp.toLowerCase();
    //trace(exp);

    var candidates = exp.split("+");

    var sum:Array<String> = new Array();
    for (sets in candidates) {
      var items = sets.split("-");
      for (i in 0...items.length) {
        if (i == 0) {
          sum.push(items[i]);
        } else {
          sum.push("-" + items[i]);
        }
      }
    }

    //trace(sum);

    var total = 0;
    var high = 0;
    var low = 0;
    for (item in sum) {
      var sign = 1;
      if (item.charAt(0) == "-") {
        item = item.substring(1);
        sign = -1;
      }

      if (item.charAt(0) == "l") {
        total = total + low*sign;
        //trace('${sign} ${low}');
        continue;
      }
      if (item.charAt(0) == "h") {
        total = total + high*sign;
        //trace('${sign} ${high}');
        continue;
      }

      if (item.indexOf("d") != -1) {
        var args = item.split("d");
        var a = Std.parseInt(args[0]);
        if (a == null) a = 0;
        var b = Std.parseInt(args[1]);
        if (b == null) b = 0;
        var roll:Array<Int> = new Array();
        for (i in 0...a) {
          var r = Std.random(b)+1;
          total = total + r*sign;
          //trace('${sign} ${r}');
          roll.push(r);
        }
        roll.sort(function (a,b) {return a-b;});
        //trace(roll);
        low = roll[0];
        high = roll[roll.length-1];
        //trace('h: ${high} l: ${low}');
        continue;
      }

      var num = Std.parseInt(item);
      if (num == null) num = 0;
      total = total + num*sign;
      //trace('${sign} ${num}');

    }

    //trace(total);
    return total;
  }

}
