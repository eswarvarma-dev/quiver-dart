// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the 'License');
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an 'AS IS' BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library quiver.json.pull_test;

import 'package:unittest/unittest.dart';
import 'package:quiver/json.dart';

main() {
  group('PullParser', () {
    test('should parse empty object', () {
      expectJson('{}', [
        objectStart,
        objectEnd,
      ]);
    });
    test('should parse string property', () {
      expectJson('{"hello": "world"}', [
        objectStart,
        propertyName("hello"),
        stringValue("world"),
        objectEnd,
      ]);
    });
    test('should parse boolean properties', () {
      expectJson('''
{
  "a": true,
  "b": false
}
''', [
        objectStart,
        propertyName("a"),
        ParseEvent.TRUE,
        propertyName("b"),
        ParseEvent.FALSE,
        objectEnd,
      ]);
    });
    test('should parse escaped string property', () {
      expectJson('''{"hello": "wo\\"rld"}''', [
        objectStart,
        propertyName("hello"),
        stringValue('wo"rld'),
        objectEnd,
      ]);
    });
    test('should parse null property value', () {
      expectJson('''{"hello": null}''', [
        objectStart,
        propertyName("hello"),
        ParseEvent.NULL,
        objectEnd,
      ]);
    });

    var nums = <String, num>{
      '1' : 1,
      '-12.3456' : -12.3456,
      '0.123' : 0.123,
      '1.42e+5' : 1.42e+5,
      '1.42E+5' : 1.42E+5,
      '1.42E-5' : 1.42E-5,
      '-1234567890e+1' : -12345678900.toDouble(),
    };
    nums.forEach((String n, num v) {
      test('should parse number ${n}', () {
        expectJson('''{"number": ${n}}''', [
          objectStart,
          propertyName("number"),
          new ParseEvent(ParseEventType.NUMBER_VALUE, v),
          objectEnd,
        ]);
      });
    });
  });
}

// Utilities

void expectJson(String jsonStr, List<ParseEvent> expected) {
  var actual = new PullParser(jsonStr.runes.iterator);
  for (int i = 0; i < expected.length; i++) {
    expect(actual.moveNext(), isTrue);
    if (actual.current.value != null && expected[i].value != null) {
      expect(actual.current.value.runtimeType, expected[i].value.runtimeType);
    }
    expect(actual.current, equals(expected[i]));
  }
}

ParseEvent propertyName(String name) =>
    new ParseEvent(ParseEventType.PROPERTY_NAME, name);
ParseEvent stringValue(String value) =>
    new ParseEvent(ParseEventType.STRING_VALUE, value);

const objectStart = ParseEvent.OBJECT_START;
const objectEnd = ParseEvent.OBJECT_END;
const listStart = ParseEvent.LIST_START;
const listEnd = ParseEvent.LIST_END;
