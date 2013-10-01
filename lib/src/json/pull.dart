part of quiver.json;

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
  static final _N = _codeUnitOf('n');
  static final _E = _codeUnitOf('e');
  static final _E_CAP = _codeUnitOf('E');
  static final _MINUS = _codeUnitOf('-');
  static final _PLUS = _codeUnitOf('+');
  static final _DOT = _codeUnitOf('.');
  static final _ZERO = _codeUnitOf('0');
  static final _NINE = _codeUnitOf('9');
  static final _TRUE = 'true'.codeUnits;
  static final _FALSE = 'false'.codeUnits;
  static final _NULL = 'null'.codeUnits;

  static const _OBJECT = true;
  static const _LIST = false;

  final Iterator<int> _src;
  final _contextStack = <_NodeType>[_NodeType.ROOT];

  bool _eof = false;
  int _position = -1;
  ParseEvent _current;
  ParseEventType _previousParseEventType;

  PullParser(this._src) {
    // Move onto the first character
    _srcMoveNext();
  }

  _NodeType get _context => _contextStack.last;

  void _pushContext() {
    // Detect what context are we entering
    _NodeType ctx;
    int lookingAt = _src.current;
    if (lookingAt == _OPEN_CURLY || lookingAt == _CLOSE_CURLY) {
      ctx = _NodeType.OBJECT;
    } else if (lookingAt == _OPEN_SQUARE || lookingAt == _CLOSE_SQUARE) {
      ctx = _NodeType.LIST;
    } else if (_isValidStartOfValue(lookingAt)) {
      if (_context == _NodeType.ROOT || _context == _NodeType.OBJECT ||
          _context == _NodeType.LIST) {
        ctx = _NodeType.VALUE;
      } else {
        throw _unexpectedCodePoint();
      }
    } else {
      throw _unexpectedCodePoint();
    }
    assert(ctx != null);
    _contextStack.add(ctx);
  }

  bool _isValidStartOfValue(int ch) =>
      ch == _T || ch == _F ||  // bool
      ch == _DBL_QUOTE ||  // string
      ch == _N ||  // null
      _isNumeric(ch);  // number

  bool _isNumeric(int ch) =>
      ch == _MINUS || ch == _PLUS || ch == _DOT || ch == _E || ch == _E_CAP ||
      (_ZERO <= ch && ch <= _NINE);

  void _popContext() {
    _contextStack.removeLast();
  }

  bool moveNext() => _skipWhiteSpace(() {
    if (_eof) {
      return false;
    }

    _pushContext();
    int ch = _src.current;
    ParseEvent result;
    if (ch == _OPEN_CURLY) {
      result = ParseEvent.OBJECT_START;
      _srcMoveNext();
    } else if (ch == _CLOSE_CURLY) {
      _popContext();
      result = ParseEvent.OBJECT_END;
      _srcMoveNext();
    } else if (ch == _OPEN_SQUARE) {
      result = ParseEvent.LIST_START;
      _srcMoveNext();
    } else if (ch == _CLOSE_SQUARE) {
      _popContext();
      result = ParseEvent.LIST_START;
      _srcMoveNext();
    } else if (_context == _NodeType.VALUE) {
      if (_previousParseEventType == ParseEventType.PROPERTY_NAME) {
        // Property value
        result = _consumeValue();
        _skipWhiteSpace(() {
          // Comma before next property. Skip it.
          if (_src.current == _COMMA) {
            _srcMoveNext();
          }
        });
      } else if (ch == _DBL_QUOTE) {
        // Property name
        result = _consumeString(ParseEventType.PROPERTY_NAME);
        _skipWhiteSpace(() {
          if (_src.current == _COLON) {
            _srcMoveNext();
          } else {
            throw _unexpectedCodePoint();
          }
        });
        if (_eof) {
          throw new ParseError('Unexpected EOF');
        }
      } else {
        throw _unexpectedCodePoint();
      }
      _popContext();
    } else {
      throw _unexpectedCodePoint();
    }
    assert(result != null);
    _previousParseEventType = result.type;
    _current = result;
    return true;
  });

  // Moves forward by one code point, then skips whitespace.
  bool _skipWhiteSpace(bool then()) {
    do {
      if (!_isWhiteSpace(_src.current)) {
        return then();
      }
    } while(_srcMoveNext());
    return false;
  }

  bool _srcMoveNext() {
    if (!_src.moveNext()) {
      _eof = true;
      return false;
    }
    _position++;
    return true;
  }

  ParseEvent get current => _current;

  ParseEvent _consumeValue() {
    var value;
    int ch = _src.current;
    if (ch == _T) {
      _consume(_TRUE);
      return ParseEvent.TRUE;
    } else if (ch == _F) {
      _consume(_FALSE);
      return ParseEvent.FALSE;
    } else if (ch == _DBL_QUOTE) {
      return _consumeString(ParseEventType.STRING_VALUE);
    } else if (ch == _N) {
      _consume(_NULL);
      return ParseEvent.NULL;
    } else if (_isNumeric(ch)) {
      return _consumeNumber();
    } else {
      throw _unexpectedCodePoint();
    }
  }

  ParseEvent _consumeString(ParseEventType type) {
    var sb = new StringBuffer();
    sb.writeCharCode(_DBL_QUOTE);
    int previous = null;
    while(_srcMoveNext() &&
          (_src.current != _DBL_QUOTE || previous == _BACK_SLASH)) {
      sb.writeCharCode(_src.current);
      previous = _src.current;
    }
    sb.writeCharCode(_DBL_QUOTE);
    _srcMoveNext(); // consume closing double quote
    return new ParseEvent(type, parse(sb.toString()));
  }

  ParseEvent _consumeNumber() {
    var sb = new StringBuffer();
    sb.writeCharCode(_src.current);
    while(_srcMoveNext() && _isNumeric(_src.current)) {
      sb.writeCharCode(_src.current);
    }
    return new ParseEvent(ParseEventType.NUMBER_VALUE, parse(sb.toString()));
  }

  void _consume(List<int> codePoints) {
    for (int i = 0; i < codePoints.length; i++) {
      if (_src.current != codePoints[i]) {
        throw _unexpectedCodePoint();
      }
      if (!_srcMoveNext() && i < codePoints.length - 1) {
        throw new StateError('Unexpected EOF');
      }
    }
  }

  StateError _unexpectedCodePoint() {
    var char = new String.fromCharCode(_src.current);
    return new StateError('Unexpected code point at ${_position} [${char}]');
  }
}
