library quiver.json;

import "dart:json";

void main() {
  var parser = new PullParser('{"a": true, "b": "hello"}'.runes.iterator);
  while (parser.moveNext()) {
    print(parser.current);
  }
}

int _codeUnitOf(String char) => char.codeUnits[0];

class PullParser implements Iterator<ParseEvent> {
  static final _OPEN_CURLY = _codeUnitOf('{');
  static final _CLOSE_CURLY = _codeUnitOf('}');
  static final _OPEN_SQUARE = _codeUnitOf('[');
  static final _CLOSE_SQUARE = _codeUnitOf(']');
  static final _DBL_QUOTE = _codeUnitOf('"');
  static final _BACK_SLASH = _codeUnitOf('\\');
  static final _COLON = _codeUnitOf(':');
  static final _COMMA = _codeUnitOf(',');
  static final _SPACE = _codeUnitOf(' ');
  static final _T = _codeUnitOf('t');
  static final _F = _codeUnitOf('f');
  static final _TRUE = 'true'.codeUnits;
  static final _FALSE = 'false'.codeUnits;

  static const _OBJECT = true;
  static const _LIST = false;

  final Iterator<int> _src;
  final _contextStack = new List<bool>();
  ParseEventType _previousParseEventType;

  PullParser(this._src);

  static bool _isWhiteSpace(int codeUnit) {
    return codeUnit == _SPACE; // TODO: add other white space chars
  }

  void _pushContext(bool isObject) {
    _contextStack.add(isObject);
  }

  void _popContext() {
    _contextStack.removeLast();
  }

  bool get _inList => _contextStack.length > 0 && !_contextStack.last;

  bool moveNext() {
    // Skip whitespace
    while(_src.moveNext()) {
      if (!_isWhiteSpace(_src.current)) {
        return true;
      }
    }
    return false;
  }

  ParseEvent get current {
    int ch = _src.current;
    ParseEvent result;
    if (ch == _OPEN_CURLY) {
      _pushContext(_OBJECT);
      result = ParseEvent.OBJECT_START;
    } else if (ch == _CLOSE_CURLY) {
      _popContext();
      result = ParseEvent.OBJECT_END;
    } else if (ch == _OPEN_SQUARE) {
      _pushContext(_LIST);
      result = ParseEvent.LIST_START;
    } else if (ch == _CLOSE_SQUARE) {
      _popContext();
      result = ParseEvent.LIST_START;
    } else if (ch == _T) {
      _consume(_TRUE);
      result = ParseEvent.TRUE;
    } else if (ch == _F) {
      _consume(_FALSE);
      result = ParseEvent.FALSE;
    } else if (ch == _DBL_QUOTE) {
      String str = _consumeString();
      if (_inList) {
        result = new ParseEvent._private(ParseEventType.LIST_ITEM, str);
      } else {
        result = new ParseEvent._private(ParseEventType.PROPERTY_NAME, str);
      }
    } else if (ch == _COLON) {
      result = new ParseEvent._private(
          ParseEventType.STRING_VALUE, _consumeString());
    } else {
      throw _unexpectedCodePoint(_src.current);
    }
    _previousParseEventType = result.type;
    return result;
  }

  String _consumeString() {
    var sb = new StringBuffer();
    while(_src.moveNext() && _src.current != _DBL_QUOTE) {
      sb.writeCharCode(_src.current);
    }
    _src.moveNext();  // Move past closing double-quote
    return sb.toString();
  }

  void _consume(List<int> codePoints) {
    for (int i = 0; i < codePoints.length; i++) {
      if (_src.current != codePoints[i]) {
        throw _unexpectedCodePoint(_src.current);
      }
      if (!_src.moveNext() && i < codePoints.length - 1) {
        throw new StateError('Unexpected EOF');
      }
    }
  }

  StateError _unexpectedCodePoint(int cp) =>
      new StateError('Unexpected code point ${new String.fromCharCode(cp)}');  // TODO: need sth more user-friendly
}

class ParseEvent {
  static const OBJECT_START = const ParseEvent._private(ParseEventType.OBJECT_START, null);
  static const OBJECT_END = const ParseEvent._private(ParseEventType.OBJECT_END, null);
  static const NULL = const ParseEvent._private(ParseEventType.NULL_VALUE, null);
  static const TRUE = const ParseEvent._private(ParseEventType.BOOLEAN_VALUE, true);
  static const FALSE = const ParseEvent._private(ParseEventType.BOOLEAN_VALUE, false);
  static const LIST_START = const ParseEvent._private(ParseEventType.LIST_START, null);
  static const LIST_END = const ParseEvent._private(ParseEventType.LIST_END, null);

  final ParseEventType type;
  final value;
  const ParseEvent._private(this.type, this.value);
  String toString() => 'ParseEvent($type, $value)';
}

class ParseEventType {
  static const OBJECT_START = const ParseEventType._private('OBJECT_START');
  static const OBJECT_END = const ParseEventType._private('OBJECT_END');
  static const PROPERTY_NAME = const ParseEventType._private('PROPERTY_NAME');
  static const STRING_VALUE = const ParseEventType._private('STRING_VALUE');
  static const NUMBER_VALUE = const ParseEventType._private('NUMBER_VALUE');
  static const BOOLEAN_VALUE = const ParseEventType._private('BOOLEAN_VALUE');
  static const NULL_VALUE = const ParseEventType._private('NULL_VALUE');
  static const LIST_START = const ParseEventType._private('LIST_START');
  static const LIST_END = const ParseEventType._private('LIST_END');
  static const LIST_ITEM = const ParseEventType._private('LIST_ITEM');

  final String name;
  const ParseEventType._private(String n) : this.name = n;

  String toString() => name;
}
