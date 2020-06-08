package xz.du.board;
import haxe.Json;
import php.Global.*;
import php.SuperGlobal.*;
import Sys.println;
import haxe.crypto.*;
import haxe.io.Bytes;

class Board {
  public static function Handler():Void {
    if(array_key_exists('method',_GET) && _GET['method'] != "" && _GET['method'] != " ") {
      switch(_GET['method']) {
#if board_board
        case "NewBoard":
          NewBoard();
        case "RemoveBoard":
          RemoveBoard();
        case "JoinBoard":
          JoinBoard();
        case "LeaveBoard":
          LeaveBoard();
        case "UpdateBoard":
          UpdateBoard();
#elseif board_user
       case "RegisterUser":
          RegisterUser();
        case "LoginUser":
          LoginUser();
        case "DeleteUser": // omg you can delete your account on this app?!11!1!
          DeleteUser();
        case "RefreshToken":
          RefreshToken();
#end
        default:
          throw new php.Exception("not a method");
      }
      return;
    } else {
      throw new php.Exception("nothing to do");
    }
  }

  public static function TokenValidity(): Bool {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB");
    } else if(!array_key_exists('board-user-session',_COOKIE)) {
      throw new php.Exception("unauthorized");
    }
    redis.select(2);
    var validity = redis.get(_COOKIE['board-user-session']);
    if(validity != false || (validity != "" && validity != " ")) {
      if(validity == "1") {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }


#if board_board
  public static function NewBoard(): Void {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB");
    }
    if(TokenValidity()) {
      // construct board and add uid to participating members
      if(!array_key_exists("api-board-data",getallheaders())) { // client should provide valid board data in json format
        throw new php.Exception("an unknown error occurred");
      } else {
        redis.select(3); // board DB number
        var board: Dynamic;
        try {
          board = Json.parse(getallheaders()['api-board-data']);
          var valids = 0;
          var fields = Reflect.fields(board);
          var needed_fields = ["name","owner","lists","participants","graph","tasks"];
          for(needed in needed_fields) {
            if(fields.indexOf(needed) == -1) {
              throw new php.Exception("field '"+needed+"' is missing from board data");
            }
          }
          for(field in fields) {
            if(needed_fields.indexOf(field) == -1) {
              throw new php.Exception("field '"+field+"' is excessive");
            }
          }
          if(redis.get(board.name) && redis.get(board.name+"_participants")) {
            throw new php.Exception("board exists");
          } else if(redis.get(board.name) && !redis.get(board.name+"_participants")) {
            // check owner first
            var existing = Json.parse(redis.get(board.name));
            if(array_key_exists('api-board-username',getallheaders()) && existing.owner == getallheaders()['api-board-username']) {
              for(participant_field in Reflect.fields(board.participants)) {
                redis.rPush(board.name+"_participants",Reflect.field(board.participants,participant_field)); // just gotta be usernames
              }
            } else {
              // why tho
              throw new php.Exception("unowned board");
            }
          } else if(!redis.get(board.name) && redis.get(board.name+"_participants")) {
            // wee dint cleanup well enough????
            // atleast we have board data :  )
            redis.set(board.name,Json.stringify(board));
            var resp = {ok: false, msg:"corrupted board",action: "REMAKE_board"};
            println(Json.stringify(resp));
          } else if(!redis.get(board.name) && !redis.get(board.name+"_participants")) {
            // ah yes, a new board
            redis.set(board.name,Json.stringify(board));
            for(participant_field in Reflect.fields(board.participants)) {
              redis.rPush(board.name+"_participants",Reflect.field(board.participants,participant_field));
            }
            var resp = {ok: true, msg: "null"};
            println(Json.stringify(resp));
          }
        } catch(e:php.Exception) {
          throw new php.Exception(e.getMessage());
        }
      }
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  public static function RemoveBoard():Void {
    if(TokenValidity()) {
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  public static function JoinBoard():Void {
    if(TokenValidity()) {
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  public static function LeaveBoard():Void {
    if(TokenValidity()) {
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  public static function UpdateBoard():Void {
    if(TokenValidity()) {
    } else {
      throw new php.Exception("unauthorized");
    }
  }
#elseif board_user
  public static function RegisterUser(): Void {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB");
    }
    redis.select(1); // user DB number
    if(array_key_exists('api-registration-token',getallheaders()) && array_key_exists('api-registration-password',getallheaders()) && array_key_exists('api-registration-email',getallheaders()) && array_key_exists('api-registration-username',getallheaders()) && !redis.get(getallheaders()['api-registration-username'])) {
      if(!redis.get(getallheaders()['api-registration-token'])) {
        throw new php.Exception("unauthorized");
      } else if(Std.parseInt(redis.get(getallheaders()['api-registration-token'])) == 0) {
        throw new php.Exception("unauthorized");
      }
      var lastuserid = redis.get('lastuserid');
      var user = {id: (lastuserid == false) ? "0" : lastuserid , email: getallheaders()['api-registration-email'], password: Sha256.encode(getallheaders()['api-registration-password'])}
      redis.set(getallheaders()['api-registration-username'],Json.stringify(user));
      var res = {ok: true, msg: "null"};
      println(Json.stringify(res));
      redis.incr('lastuserid');
      redis.decr(getallheaders()['api-registration-token']);
    } else {
      throw new php.Exception("an unknown error occurred");
    }
  }

  public static function LoginUser(): Void {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB");
    }
    redis.select(2); // token DB number
    if(array_key_exists('api-login-username',getallheaders()) && array_key_exists('api-login-password',getallheaders())) {
      if(getallheaders()['api-login-username'] == "" || getallheaders()['api-login-username'] == " ") {
        throw new php.Exception("invalid username");
      } else if(getallheaders()['api-login-password'] == "" || getallheaders()['api-login-password'] == " ") {
        throw new php.Exception("invalid password");
      } else {
        if(!array_key_exists('board-user-session',_COOKIE)) {
          redis.select(1);
          var user = redis.get(getallheaders()['api-login-username']);
          redis.select(2);
          if(user == false) {
            throw new php.Exception("user not found");
          } else {
            if(Sha256.encode(getallheaders()['api-login-password']) == Json.parse(user).password) {
	      var sessiontoken = Base64.encode(Bytes.ofString(Sha256.encode(Json.parse(user).id+":"+Json.parse(user).name)+Sha256.encode(DateTools.format(Date.now(),"%Y-%m-%d|%H:%M:%S"))));
              redis.set(sessiontoken,"1");
              setcookie('board-user-session',sessiontoken,0,"/");
              redis.select(1);
              var uid = Json.parse(redis.get(getallheaders()['api-login-username'])).id;
              redis.select(2);
              var resp = {
                ok: true,
                msg: "null",
                user:
                {
                  id: uid,
                  name: getallheaders()['api-login-username']
                }
              };
              println(Json.stringify(resp));
            } else {
              throw new php.Exception("incorrect password");
            }
          }
        } else {
          if(!redis.get(_COOKIE['board-user-session'])) {
            var resp = {ok: true, msg: "already logged in", action: "WIPE_TOKEN_AND_RETRY"};
            println(Json.stringify(resp));
            return;
          }
          var resp = {ok: true, msg: "already logged in"};
          println(Json.stringify(resp));
        }
      }
    } else {
      throw new php.Exception("no username or password specified");
    }
  }

  public static function DeleteUser(): Void {
    return;
  }

  public static function RefreshToken(): Void {
    if(TokenValidity()) {
      // set it to another X amount of hours
    } else {
      throw new php.Exception("unauthorized or token expired");
    }
  }
#end
}
