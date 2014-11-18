part of postgresql;

const int _apos = 39;
const int _return = 13;
const int _newline = 10;
const int _backslash = 92;

//TODO handle int modifiers
dynamic _formatValue(value, String type) {

  err(rt, t) => new Exception('Invalid runtime type and type modifier combination ($rt to $t).');

  if (value == null)
    return 'null';

  if (value is bool)
    return value.toString();

  if (type != null) {
    type = type.toLowerCase();

    if (type == "json") //do it here since value can be anything
      return _formatString(JSON.encode(value));
  }

  if (value is num) {
    if (type == null || type == 'number')
      return value.toString(); //TODO test that corner cases of dart.toString() match postgresql number types.
    else if (type == 'string')
      return "'$value'";
    else
      throw err('num', type);
  }

  if (value is String) {
    if (type == null || type == 'string')
      return _formatString(value);
    else
      throw err('String', type);
  }

  if (value is DateTime) {
    //TODO check types.
    return _formatDateTime(value, type);
  }

  if (value is Map) //List could be a candidate but confused with binary
    return _formatString(JSON.encode(value));

  //if (value is List<int>)
  // return _formatBinary(value, type);

  return extendedFormatValue(value, type, _formatString);
}

typedef _FormatValue(value, String type, formatString(String s));

///The extended value formatter for handling unknown type and value.
_FormatValue extendedFormatValue = (value, String type, formatString(String s)) {
  throw new Exception('Unsupported runtime type as query parameter: $value ($type).');
};
///The default date time type. It is used if the type is unknown and the object
///is `DateTime`.
///You can override it to `timestamptz`.
String defaultDateTimeType = "timestamp";

final _escapeRegExp = new RegExp(r"['\r\n\\]");

//TODO test if this works without escaping unicode characters.
// Uses an string constant E''.
// See http://www.postgresql.org/docs/9.0/static/sql-syntax-lexical.html#SQL-SYNTAX-STRINGS-ESCAPE
_formatString(String s) {
  if (s == null)
    return ' null ';

  var escaped = s.replaceAllMapped(_escapeRegExp, (m) {
    switch (s.codeUnitAt(m.start)) {
      case _apos: return r"\'";
      case _return: return r'\r';
      case _newline: return r'\n';
      case _backslash: return r'\\';
      default: assert(false);
    }
  });

  return " E'$escaped' ";
}

_formatDateTime(DateTime datetime, String type) {

  if (datetime == null)
    return 'null';

  String escaped;
  var t = (type == null) ? defaultDateTimeType : type.toLowerCase();

  if (t != 'date' && t != 'timestamp' && t != 'timestamptz') {
    throw new Exception('Unexpected type: $type.'); //TODO exception type
  }

  if (t == 'timestamptz')
    datetime = datetime.toUtc();

  //2004-10-19 10:23:54.4455+02
  int year = datetime.year;
  final bool bc = year < 0;
  if (bc) year = -year;

  var sb = new StringBuffer()
    ..write(_pad(year, 4))
    ..write('-')
    ..write(_pad(datetime.month))
    ..write('-')
    ..write(_pad(datetime.day));

  if (t == 'timestamp' || t == 'timestamptz') {
    sb..write(' ')
      ..write(_pad(datetime.hour))
      ..write(':')
      ..write(_pad(datetime.minute))
      ..write(':')
      ..write(_pad(datetime.second));

    final int ms = datetime.millisecond;
    if (ms != 0) {
      sb..write('.')..write(_pad(ms, 3));
    }
  }

  if (t == 'timestamptz')
    sb.write("Z");

  if (bc)
    sb.write(" BC");

  return "'${sb.toString()}'";
}

String _pad(int val, [int digits=2]) {
  String str = val.toString();
  for (int i = digits - str.length; --i >= 0;)
    str = '0' + str;
  return str;
}

//TODO
// See http://www.postgresql.org/docs/9.0/static/sql-syntax-lexical.html#SQL-SYNTAX-STRINGS-ESCAPE
_formatBinary(List<int> buffer) {
  //var b64String = ...;
  //return " decode('$b64String', 'base64') ";
}
