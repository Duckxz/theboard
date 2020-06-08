package xz.du.board;
import haxe.extern.EitherType;
import haxe.extern.Rest;
import php.*;

@:native("Redis")
@:nativeChildren extern enum RedisEnums {
  BEFORE;
  AFTER;
  OPT_SCAN;
  SCAN_RETRY;
  SCAN_NORETERY;
  MULTI;
  PIPELINE;
  OPT_PREFIX;
  OPT_SERIALIZER;
  SERIALIZER_NONE;
  SERIALIZER_PHP;
  SERIALIZER_IGBINARY;
  SERIALIZER_MSGPACK;
  OPT_READ_TIMEOUT;
}

@:native("Redis")
extern class Redis {
  function new():Void;
  function connect(?host: String, ?port: Int, ?timeout: Float, ?reserved: Any, ?retry_Interval: Int, ?read_timeout: Float):Bool;
  function auth(password: String):Bool;
  function select(dbindex: Int):Bool;
  function swapdb(db1: Int, db2: Int):Bool;
  function close():Bool;
  function ping(?message: String):Bool;
  function echo(message: String):String;
  function get(key: String):EitherType<String,Bool>; // either string or bool
  function set(key: String, value: String, ?opts: NativeArray):Bool;
  function setEx(key: String, lifetime: Int, value: String):Bool;
  function del(keys: Rest<String>):Int;
  function pSetEx(key: String, lifetime: Int, value: String):Bool;
  function setNx(key: String, value: String):Bool;
  function exists(key: Any): Int;
  function incr(key: String):Int;
  function incrBy(key: String, amount: Int):Int;
  function incrByFloat(key: String, amount: Float):Float;
  function decr(key: String):Int;
  function decrBy(key: String, amount: Int):Int;
  function mGet(keys: NativeArray): NativeArray;
  function bgSave():Void;
  function config(operation: String, key: String, ?value: String):EitherType<NativeAssocArray<Any>,Bool>;
  function dbSize():Int;
  function flushAll(?async: Bool):Bool; // always true, removes ALL
  function flushDb(?async: Bool):Bool; // always true, removes all keys in CURRENT db
  function info():NativeAssocArray<String>; // returns an AA
  function lastSave():Int;
  function save():Bool;
  function scan(?ref: Ref<Any>, ?pat: Int, ?count: Int):EitherType<NativeArray,Bool>;
  function keys(?pat: String):NativeArray;
  function expireAt(key: String, stamp: Int):Bool;
  function rename(key: String, key2: String):Bool;
  function move(key: String, db: Int): Bool;
  function randomKey(): String;
  function getSet(key: String, newValue: String):String;
  function persist(key: String):Bool;
  function hSet(hash: String, key: String, value: String): Int;
  function hSetNx(hash: String, key: String, value: String): Bool;
  function hGet(hash: String, key: String):EitherType<String,Bool>; // String or Bool(false)
  function hLen(hash: String): Any; // Int or Bool(false)
  function hDel(hash: String, key: String, key1: String, key2: String, key3: String, key4: String, key5: String):EitherType<Int,Bool>; // Int or Bool(false)
  function hKeys(hash: String):NativeArray;
  function hVals(hash: String):NativeArray;
  function hGetAll(hash: String):NativeArray;
  function hExists(hash: String, key: String):Bool;
  function hIncrBy(hash: String, key: String, value: Int):Int;
  function hIncrByFloat(hash: String, key: String, value: Float):Float;
  function hMSet(hash: String, values: Map<String,Any>):Bool;
  function hMGet(hash: String, fields: NativeArray):Map<String,Any>;
  function hScan(hash: String, ref: Ref<Any>, pat: String, count: Int):NativeArray;
  function hStrLen(hash: String, field: String):Int;
  function blPop(key_NativeArray: NativeArray, timeout: Int ):NativeArray; // it's best to pass an NativeArray of keys
  function brPop(key_NativeArray: NativeArray, timeout: Int ):NativeArray; // it's best to pass an NativeArray of keys
  function bRPopLPush(srckey: String, dstkey: String, timeout: Int):EitherType<String,Bool>; // String or Bool(false)
  function lIndex(list: String, index: Int): Any; // String or Bool(false)
  function lInsert(list: String, position: RedisEnums, pivot: Int, index: Int):Int;
  function lPop(list: String):EitherType<String,Bool>; // String or Bool(false)
  function lPush(list: String, value: Any):EitherType<Int,Bool>;
  function lPushx(list: String, value: String):EitherType<Int,Bool>;
  function lRange(list: String, start: Int, end: Int):NativeArray;
  function lRem(list: String, value: String, count: Int):EitherType<Int,Bool>;
  function lSet(list: String, index: Int, value: Any): Bool;
  function lTrim(list: String, start: Int, stop: Int):EitherType<NativeArray,Bool>; // either NativeArray<Any> or Bool
  function rPop(list: String):EitherType<String,Bool>;
  function rPopLPush(srckey: String, dstkey: String):EitherType<String,Bool>;
  function rPush(list: String, value: Any):EitherType<Int,Bool>;
  function rPushX(list: String, value: Any):EitherType<Int,Bool>;
  function lLen(list: String):EitherType<Int,Bool>;
  function sAdd(set: String, value: Any):Int;
  function sCard(set: String):Int;
  function sDiff(set: String, restsets: Rest<String>): NativeArray;
  function sDiffStore(dstset: String, restsets: Rest<String>):EitherType<Int,Bool>;
  function sInter(set: String, restsets: Rest<String>):NativeArray;
  function sInterStore(dstset: String, set: String, restsets: Rest<String>): Any;
  function sIsMember(set: String, member: String):Bool;
  function sMembers(set: String):NativeArray;
  function sMove(srcset: String, dstset: String, member: String):Bool;
  function sPop(set: String, ?count: Int):EitherType<NativeArray,Bool>;
  function sRandMember(set: String, ?count: Int):EitherType<String,Bool>;
  function sRem(set: String, member: String):Int;
  function sUnion(set: String, restsets: Rest<String>):NativeArray;
  function sUnionStore(dstset: String, restsets: Rest<String>):EitherType<Int,Bool>;
  function sScan(set: String, iterator: Ref<Any>):EitherType<NativeArray,Bool>;
}
