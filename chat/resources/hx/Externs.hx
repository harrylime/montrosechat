package; 

extern class Window {
  public var document:Document;
  public var innerWidth:Int;
  public var innerHeight:Int;
  public var scrollX:Int;
  public var scrollY:Int;
  public var onkeypress:KeyboardEvent -> Void;
  public var onbeforeunload:BeforeUnloadEvent -> Null<String>;
  public function addEventListener(typ:String, func:Event -> Void):Void;
  public function setTimeout(func:Void -> Void,delay:Int):Int;
  public function clearTimeout(id:Int):Void;
  public function scrollTo(x:Int,y:Int):Void;
}

extern class Location {
  public var host:String;
}

extern class Document {
  public var ip:String;
  public var location:Location;
  public var body:BodyElement;
  public var activeElement:Element;
  public function getElementById(id:String):Null<Element>;
  public function getElementsByClassName(nm:String):Array<Element>;
  public function createElement(typ:String):Null<Element>;
  public function createTextNode(typ:String):Element;
}

extern class Hls {
  public function new();
  public static function isSupported():Bool;
  public static var Events:HLSEventCollection;
  public function loadSource(url:String):Void;
  public function attachMedia(video:VideoElement):Void;
  public function on(e:HLSEvent,f:Void -> Void):Void;
}

extern class HLSEvent {}

extern class HLSEventCollection {
  public var MANIFEST_PARSED:HLSEvent;
}

extern class Element {
  public var id:String;
  public var parentNode:Element;
  public var firstElementChild:Null<Element>;
  public var innerHTML:String;
  public var onclick:Event -> Void;
  public function getAttribute(attr:String):String;
  public function setAttribute(attr:String,val:String):Void;
  public function appendChild(element:Element):Void;
  public function removeChild(child:Element):Void;
}

extern class ImageElement extends Element {
  public var src:String;
  public var onload:Void -> Void;
}

extern class LinkElement extends Element {
  public var href:String;
  public var target:String;
}

extern class SoundElement extends Element {
  public var preload:String;
  public var volume:Float;
  public function load():Void;
  public function play():Void;
}

extern class SourceElement extends Element {
  public var src:String;
  public var type:String;
}

extern class InputElement extends Element {
  public var value:String;
}

extern class VideoElement extends Element {
  public function play():Void;
  public function pause():Void;
}

extern class BodyElement extends Element {
  public var scrollHeight:Int;
}

extern class Event {
  public function preventDefault():Void;
}

extern class KeyboardEvent extends Event {
  public var charCode:Null<Int>;
  public var which:Null<Int>;
}

extern class ErrorEvent extends Event {
  public var data:String;
}

extern class CloseEvent extends Event {}

extern class MessageEvent extends Event {
  public var data:String;
}

extern class BeforeUnloadEvent extends Event {
  public var returnValue:String;
}

extern class WebSocket {
  public var onopen:Void -> Void;
  public var onmessage:MessageEvent -> Void;
  public var onerror:ErrorEvent -> Void;
  public var onclose:CloseEvent -> Void;
  public function new(str:String);
  public function send(msg:String):Void;
}
