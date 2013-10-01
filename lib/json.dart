library quiver.json;

import "dart:json";

part "src/json/pull.dart";

int _codeUnitOf(String char) => char.codeUnits[0];
String _strCodeUnit(int cu) => new String.fromCharCode(cu);

// TODO: should this be an event to allow best-effort parsing?
class ParseError implements Exception {
  final message;

  ParseError([this.message]);

  String toString() {
    if (message == null) return "ParseError";
    return "ParseError: $message";
  }
}

class InternalParseError implements Exception {
  final message;

  InternalParseError._private([this.message]);

  String toString() {
    if (message == null) return "InternalParseError";
    return "InternalParseError: $message";
  }
}

class _NodeType {
  static const ROOT = const _NodeType('ROOT');
  static const OBJECT = const _NodeType('OBJECT');
  static const LIST = const _NodeType('LIST');
  static const PROPERTY_NAME = const _NodeType('PROPERTY_NAME');
  static const VALUE = const _NodeType('VALUE');

  final String name;
  const _NodeType(this.name);

  String toString() => name;
}

class ParseEvent {
  static const OBJECT_START = const ParseEvent(ParseEventType.OBJECT_START);
  static const OBJECT_END = const ParseEvent(ParseEventType.OBJECT_END);
  static const NULL = const ParseEvent(ParseEventType.NULL_VALUE);
  static const TRUE = const ParseEvent(ParseEventType.BOOLEAN_VALUE, true);
  static const FALSE = const ParseEvent(ParseEventType.BOOLEAN_VALUE, false);
  static const LIST_START = const ParseEvent(ParseEventType.LIST_START);
  static const LIST_END = const ParseEvent(ParseEventType.LIST_END);

  final ParseEventType type;
  final value;
  const ParseEvent(this.type, [value = null]) : this.value = value;

  String toString() => 'ParseEvent($type, $value)';
  operator==(other) =>
      other is ParseEvent && type == other.type && value == other.value;
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

  final String name;
  const ParseEventType._private(String n) : this.name = n;

  String toString() => name;
}

bool _isWhiteSpace(int codeUnit) =>
    (0x0009 <= codeUnit && codeUnit <= 0x000D) ||
    codeUnit == 0x0020 ||
    codeUnit == 0x0085 ||
    codeUnit == 0x00A0 ||
    codeUnit == 0x1680 ||
    codeUnit == 0x180E ||
    (0x2000 <= codeUnit && codeUnit <= 0x200A) ||
    codeUnit == 0x2028 ||
    codeUnit == 0x2029 ||
    codeUnit == 0x202F ||
    codeUnit == 0x205F ||
    codeUnit == 0x3000 ||
    codeUnit == 0xFEFF;
