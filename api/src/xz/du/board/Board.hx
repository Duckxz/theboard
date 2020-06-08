// TODO(!!!): associate a user to a token so that users can't manipulate any user with a valid token (DONE)
// TODO: 16 bytes max for names but passwords may be as big as 4096 bytes (for user security if they want)
// TODO: rate limiting (!!!)
// TODO: make js delete the auth token and refresh when it's expired
// TODO: set X amount of hours for each token to be valid so it automatically expires
// TODO(?): web worker for continuous synchronization
// TODO: somehow start using cookies instead of headers
// TODO: profile pics are fancy and should definetly be implemented sometime
// TODO: leaving notes under boards/cards (mainly cards) whould be nice too
// TODO: BoardInfo, UserInfo and LogOut method

// schema:
// 1: user and registration token info
  // <user>: JSON data about user
  // <user>_boards: list of boards they're in (by name)
// 2: token info
  // <user>:<hashed and B64 encoded token> (unhashed format: <id>:<username>%Y-%m-%d|%H:%M:%S(of login date))

// 3: board info
// 4: maybe statistics (api calls per X for load overview, non-intrusive and fully anonymous analytics and etc)

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
        case "BoardInfo":
          BoardInfo();
#elseif board_user
       case "RegisterUser":
          RegisterUser();
        case "LoginUser":
          LoginUser();
        case "DeleteUser": // omg you can delete your account on this app?!11!1! (but for real it's kinda annoying when sites don't let you.)
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
      throw new php.Exception("could not connect to Redis DB while checking security");
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

  public static function TokenOwner(owner: String): Bool {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB while checking security");
    } else if(!array_key_exists('board-user-session',_COOKIE)) {
      throw new php.Exception("unauthorized");
    }
    redis.select(2);
    var candidates: Array<String> = cast(php.Lib.toHaxeArray(redis.keys(owner+':*')));
    if(candidates.length > 1) {
      var split: Array<String> = candidates[0].split(':');
      if(split[0] == owner && split[1] == _COOKIE['board-user-session'].split(':')[1]) {
        return true;
      } else {
        throw new php.Exception("unowned token");
      }
    } else {
      return false;
    }
  }

#if board_board
  //  /api/board/?method=NewBoard
  //    api-board-data: {
  //      name: <board name>,
  //      owner: <username>,
  //      lists: [<names>],
  //      participants: [<usernames>],
  //      graph: [<numbers>],
  //      tasks: [{
  //        name: <name>,
  //        points: <number>
  //      }]
  //    }
  //  returns: {
  //    ok: true | false,
  //    msg: "null" | <errormessage>
  //  }
  public static function NewBoard(): Void {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB");
    }
    if(TokenValidity()) {
      // construct board
      if(!array_key_exists("api-board-data",getallheaders())) { // client should provide valid board data in json format, naïve but if we check it _should_ be fine
        throw new php.Exception("an unknown error occurred");
      } else {
        redis.select(3);
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
          if(redis.get(board.name)) {
            throw new php.Exception("board exists");
          }
          if(TokenOwner(board.owner)) {
            redis.set(board.name,getallheaders()['api-board-data']);
            redis.select(1);
            redis.sAdd(board.owner+"_boards",board.name);
            var participants: Array<String> = php.Lib.toHaxeArray(board.participants);
            for(participant in participants.iterator()) {
              if(!redis.get(participant) && redis.sIsMember(board.name,participant)) {
                continue; // skip all non-existent members or already participating
              }
              redis.sAdd(participant+"_boards",board.name);
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

  // owner must destroy board
  public static function RemoveBoard():Void {
    if(TokenValidity()) {
    } else {
      throw new php.Exception("unauthorized");
    }
  }
  //  /api/board/?method=JoinBoard
  //    api-join-board: <boardname>
  //    api-join-user: <username>
  //  returns: {
  //    ok: true | false,
  //    msg: "null" | <errormessage>
  //  }
  // push board name to participating (might need some kind of invite token)
  public static function JoinBoard():Void {
    var redis: Redis = new Redis();
    if(!redis.connect('localhost')) {
      throw new php.Exception("could not connect to local Redis DB");
    }
    if(TokenValidity()) {
      if(array_key_exists("api-join-board",getallheaders()) && array_key_exists("api-join-user",getallheaders())) {
        if(TokenOwner(getallheaders()['api-join-user'])) {
          if(redis.sIsMember(getallheaders()['api-join-user']+"_boards",getallheaders()['api-join-board'])) {
            var resp = {
              ok: true,
              msg: "null"
            }
            println(Json.stringify(resp));
            return;
          }
          redis.select(3);
          if(!redis.get(getallheaders()['api-join-board'])) {
            throw new php.Exception("tried to join non-existent board");
          }
          redis.select(1);
          redis.sAdd(getallheaders()['api-join-user']+"_boards",getallheaders()['api-join-board']);
          var resp = {
            ok: true,
            msg: "null"
          }
          println(Json.stringify(resp));
        } else {
          throw new php.Exception("missing header field");
        }
      }
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  //  /api/board/?method=LeaveBoard
  //    api-leave-board: <boardname>
  //    api-leave-user: <user leaving>
  //  returns:
  //  {
  //    ok: true | false,
  //    msg: "null" |  <errormessage>
  //  }
  // leave from a board, should use LREM to delete the board name from the list, js side should remove it from the DOM
  public static function LeaveBoard():Void {
    var redis: Redis = new Redis();
    if(!redis.connect('localhost')) {
      throw new php.Exception("could not connect to local Redis DB");
    }
    if(TokenValidity()) {
      redis.select(1);
      if(array_key_exists("api-leave-board",getallheaders()) && array_key_exists("api-leave-user",getallheaders())) {
        if(TokenOwner(getallheaders()['api-leave-user'])) {
          if(!redis.sIsMember(getallheaders()['api-leave-user']+"_boards",getallheaders()['api-leave-board'])) {
            throw new php.Exception("not a participant of board '"+getallheaders()['api-leave-board']+"'");
          }
          redis.sRem(getallheaders()['api-leave-user']+"_boards",getallheaders()['api-leave-board']);
          var resp = {
            ok: true,
            msg: "null"
          }
          println(Json.stringify(resp));
        }
      } else {
        throw new php.Exception("missing header field");
      }
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  // this is going to be tricky because of desynchronization if two clients edit the same thing
  public static function UpdateBoard():Void {
    if(TokenValidity()) {
    } else {
      throw new php.Exception("unauthorized");
    }
  }

  //  /api/board/?method=BoardInfo
  //    api-boardinfo-user: <username>
  //    api-boardinfo-board: <boardname>
  //  returns: {
  //    ok: true | false,
  //    msg: <json board data> | <errormessage>
  //  }
  public static function BoardInfo(): Void {
      var redis: Redis = new Redis();
      if(!redis.connect("localhost")) {
        throw new php.Exception("unable to connect to Redis DB");
      }
      if(TokenValidity()) {
        if(array_key_exists("api-boardinfo-user",getallheaders()) && array_key_exists("api-boardinfo-board",getallheaders())) {
          redis.select(3);
          if(!redis.get(getallheaders()['api-boardinfo-board'])) {
            throw new php.Exception("board '"+getallheaders()['api-boardinfo-board']+"' does not exist");
          }
          redis.select(1);
          if(redis.sIsMember(getallheaders()['api-boardinfo-user']+"_boards",getallheaders()['api-boardinfo-board'])) {
            redis.select(3);
            var resp = {
              ok: true,
              msg: redis.get(getallheaders()['api-boardinfo-board'])
            }
            println(Json.stringify(resp));
          } else {
            throw new php.Exception("you're not a participant of board '"+getallheaders()['api-boardinfo-board']+"'");
          }
        } else {
          throw new php.Exception("missing header fields");
        }
      }
  }
#elseif board_user
  //  /api/user/?method=RegisterUser
  //    api-registration-token: <reg token>
  //    api-registration-username: <username>
  //    api-registration-password: <password>
  //    api-registration-email: <email>
  //  returns: {
  //    ok: true | false,
  //    msg: "null" | <errormessage>
  //  }
  public static function RegisterUser(): Void {
    var redis: Redis = new Redis();
    if(!redis.connect("localhost")) {
      throw new php.Exception("could not connect to Redis DB");
    }
    redis.select(1);
    if(array_key_exists('api-registration-token',getallheaders()) && array_key_exists('api-registration-password',getallheaders()) && array_key_exists('api-registration-email',getallheaders()) && array_key_exists('api-registration-username',getallheaders()) && !redis.get(getallheaders()['api-registration-username'])) {
      if(!redis.get(getallheaders()['api-registration-token'])) {
        throw new php.Exception("unauthorized registration token");
      } else if(Std.parseInt(redis.get(getallheaders()['api-registration-token'])) == 0) { // registration token exhausted
        throw new php.Exception("registration token exhausted");
      } else if(redis.get(getallheaders()['api-registration-username']+"_boards")) {
        throw new php.Exception("DB corruption. contact developer please");
      }
      var lastuserid = redis.get('lastuserid');
      var user = {id: (lastuserid == false) ? "0" : lastuserid , email: getallheaders()['api-registration-email'], password: Sha256.encode(getallheaders()['api-registration-password'])}
      redis.set(getallheaders()['api-registration-username'],Json.stringify(user));
      redis.set(getallheaders()['api-registration-username']+"_boards","");
      redis.incr('lastuserid');
      redis.decr(getallheaders()['api-registration-token']);
      var resp = {
        ok: true,
        msg: "null"
      }
      println(Json.stringify(resp));
    } else {
      throw new php.Exception("an unknown error occurred");
    }
  }

  //  /api/user/?method=LoginUser
  //    api-login-username: <username>
  //    api-login-password: <password>
  //  returns:
  // {
  //    ok: true | false,
  //    msg: "null" | <errormessage>,
  //    user: {
  //      id: <user_id>,
  //      name: <username>,
  //    }
  //  }
  // sets cookie 'board-user-session' to valid session token
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
              var sessiontoken = getallheaders()['api-login-username']+':'+Base64.encode(Bytes.ofString(Sha256.encode(Json.parse(user).id+":"+Json.parse(user).name)+Sha256.encode(DateTools.format(Date.now(),"%Y-%m-%d|%H:%M:%S"))));
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

  // dangerous? might be. hence the token validity check.
  public static function RefreshToken(): Void {
    if(TokenValidity()) {
      // set it to another X amount of hours
    } else {
      throw new php.Exception("unauthorized or token expired");
    }
  }
#end
}
