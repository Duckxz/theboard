package xz.du.board;
import xz.du.board.Redis;
import xz.du.board.Board;
import haxe.Json;
import php.Global.*;
import php.SuperGlobal.*;
import Sys.println;

class Main {
  public static function main():Void {
    var redis: Redis = new Redis();
    var redis_connected: Bool = false;
    try {
      if(redis.connect("localhost")) {
        redis_connected = true;
      }
    } catch(e: php.Exception) {
    }
    try {
      if(!array_key_exists('api-access-method',getallheaders()) || getallheaders()['api-access-method'] == "" || getallheaders()['api-access-method'] == " " || getallheaders()['api-access-method'] != 'api-call') {
        var displayed_custom_message: Bool = false;
#if board_board
        println("<head><title>board api</title></head>");
#elseif board_user
        println("<head><title>user api</title></head>");
#end
        println("<div style=\"position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);border:double 3px black;\">");
        println("  <h6 style=\"text-align:center;padding:4px\">something isn't quite right</h6>");
#if board_user
        if(array_key_exists('board-user-session',_COOKIE)) {
          redis.select(2);
          if(redis.get(_COOKIE['board-user-session']) == "1") {
	    println("  <h6 style=\"text-align:center;padding:4px\">atleast you're logged in</h6>");
            displayed_custom_message = true;
          }
        }
#end
        if(!displayed_custom_message) {
          println("  <h6 style=\"text-align:center;padding:4px\">...yet</h6>");
        }
	println("</div>");
      } else {
        Board.Handler();
      }
    } catch(e: php.Exception) {
      if(!array_key_exists('api-access-method',getallheaders()) || getallheaders()['api-access-method'] != "api-call") {
        println("<h1>oop, something went wrong. see below</h1>");
        println("<h6 style=\"position: fixed; transform: translate(-50%,-50%); top: 94%; left: 50%;\">technical details: "+e.getMessage()+"</h6>");
      } else {
        var object: Dynamic = { ok: false, msg: e.getMessage() };
        println(Json.stringify(object));
      }
    }
  }
}
