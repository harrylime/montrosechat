package sound;

import haxe.io.Bytes;
import sys.io.File;
import sys.io.Process;

typedef Amp = {
  var i:Int;
  var a:Float;
}

class ChatSounds {
  static inline var r:Int = 44100;
  static inline var samples:Int = 65536;
  static var wavHeader = Bytes.ofString("RIFF\x08\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x01\x00D\xac\x00\x00\x88X\x01\x00\x02\x00\x10\x00data\x00\x00\x00\x00"); //44100 16 bit mono | 44 bytes 
  static var envelopes:Array<Array<Amp>> = [
    [{i:0,a:0},{i:300,a:0.6},{i:1100,a:0.4},{i:21900,a:0}],
    [{i:0,a:0},{i:100,a:0.6},{i:1400,a:0.1},{i:4100,a:0.2},{i:7900,a:0.1},{i:20900,a:0}],
    [{i:0,a:0.5},{i:200,a:0.3},{i:1000,a:0.2},{i:4700,a:0.1},{i:10400,a:0}]
  ];

  public static function main() {

    //add 3 stretched envelopes
    for (i in 0...3) {
      var envelope:Array<Amp> = new Array();
      for (j in 0...envelopes[i].length) {
        envelope.push({
                        i: Math.round(envelopes[i][j].i*4/3+r/2),
                        a: envelopes[i][j].a
                      });
      }
      envelopes.push(envelope);
    }

    var buffer = Bytes.alloc(samples*2+wavHeader.length);
    buffer.blit(0,wavHeader,0,wavHeader.length);
    buffer.setInt32(4,samples*2+wavHeader.length-8); 
    buffer.setInt32(40,samples*2); 

    var inc:Array<Float> = [1/r*466.16*1,
                            1/r*466.16*2,
                            1/r*466.16*4,
                            1/r*369.99*1,
                            1/r*369.99*2,
                            1/r*369.99*4
                           ]; //base notes: A#4 & F#4
    var pos:Array<Float> = [0,0,0,0,0,0];

    var sample:Float = 0;
    var bytes:Int;
    for (i in 0...samples) {

      sample = 0;
      for (j in 0...pos.length)
        sample += triangle(pos[j])*modulate(i,j);

      bytes = float16toLEBytes(sample);
      buffer.set(wavHeader.length+i*2, bytes & 0xFF);
      buffer.set(wavHeader.length+i*2+1, (bytes >> 8) & 0xFF);

      for (j in 0...pos.length) {
        pos[j] += inc[j];
        while (pos[j] > 1) pos[j] -= 1;
      }

    }

    File.saveBytes("resources/wav/mention.wav",buffer);

    inc[0] = 1/r*1760; //A6 
    pos = [0];
    var amp:Float = 1;
    var step:Int = Math.floor(r/100); //hundreth of a second

    for (i in 0...samples) {

      sample = triangle(pos[0])*amp*0.75;

      bytes = float16toLEBytes(sample);
      buffer.set(wavHeader.length+i*2, bytes & 0xFF);
      buffer.set(wavHeader.length+i*2+1, (bytes >> 8) & 0xFF);

      pos[0] += inc[0];
      while (pos[0] > 1) pos[0] -= 1;
      if (i > 0 && i < step*6 && i % step == 0) inc[0] = inc[0]*Math.pow(2,1/5); 
      if (i < step*6) continue;
      amp = amp - 1/step;
      if (amp < 0) amp = 0;

    }

    File.saveBytes("resources/wav/message.wav",buffer);

    var proc = new Process("lame --preset standard resources/wav/mention.wav resources/mp3/mention.mp3");
    proc.exitCode(true);
    proc.close();
    proc = new Process("lame --preset standard resources/wav/message.wav resources/mp3/message.mp3");
    proc.exitCode(true);
    proc.close();
    proc = new Process("oggenc -o resources/ogg/mention.ogg resources/wav/mention.wav");
    proc.exitCode(true);
    proc.close();
    proc = new Process("oggenc -o resources/ogg/message.ogg resources/wav/message.wav");
    proc.exitCode(true);
    proc.close();
    
  }

  public static function float16toLEBytes(f:Float):Int {
    if (f < 0) return Math.floor((1+f)*32767+32768);
    return Math.floor(f*32767);
  }

  public static function modulate(i:Int,idx:Int):Float {
    var envelope = envelopes[idx];
    if (i < envelope[0].i || i >= envelope[envelope.length-1].i) return 0;
    var a = 0; 
    while (i >= envelope[a].i) a++; //dangerous but guard above should make safe
    a--;
    var b = a + 1;
    var span = envelope[b].i - envelope[a].i;
    var af = envelope[a].a;
    var bf = envelope[b].a;
    return af*(envelope[b].i-i)/span + bf*(i-envelope[a].i)/span;
  }

  public static function triangle(x:Float):Float {
    if (x < 0.25) return x/0.25;
    if (x < 0.5) return 1-(x-0.25)/0.25;
    if (x < 0.75) return -(x-0.5)/0.25;
    return -1+(x-0.75)/0.25;
  }

}
