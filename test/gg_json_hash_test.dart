// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';
import 'package:test/test.dart';

void main() {
  group('JsonHash', () {
    late JsonHash jh;

    setUp(() {
      jh = JsonHash();
    });

    group('applyToJsonString(String)', () {
      test(
          'parses the string, adds the hashes, '
          'and returns the serialized string', () {
        const json = '{"key": "value"}';
        final jsonString = jh.applyToJsonString(json);
        expect(jsonString, '{"key":"value","_hash":"5Dq88zdSRIOcAS-WM_lYYt"}');
      });
    });

    group('private methods', () {
      group('_copyJson', () {
        const copyJson = JsonHash.testCopyJson;

        test('empty json', () {
          expect(copyJson({}), <String, dynamic>{});
        });

        test('simple value', () {
          expect(copyJson({'a': 1}), {'a': 1});
        });

        test('nested value', () {
          expect(
              copyJson({
                'a': {'b': 1},
              }),
              {
                'a': {'b': 1},
              });
        });

        test('list value', () {
          expect(
              copyJson({
                'a': [1, 2],
              }),
              {
                'a': [1, 2],
              });
        });

        test('list with list', () {
          expect(
              copyJson({
                'a': [
                  [1, 2],
                ],
              }),
              {
                'a': [
                  [1, 2],
                ],
              });
        });

        test('list with map', () {
          expect(
              copyJson({
                'a': [
                  {'b': 1},
                ],
              }),
              {
                'a': [
                  {'b': 1},
                ],
              });
        });

        group('throws', () {
          group('on unsupported type', () {
            test('in map', () {
              String? message;
              try {
                copyJson({'a': Error()});
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Unsupported type: Error');
            });

            test('in list', () {
              String? message;
              try {
                copyJson({
                  'a': [Error()],
                });
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Unsupported type: Error');
            });
          });
        });
      });

      group('_isBasicType', () {
        const isBasicType = JsonHash.testIsBasicType;

        test('returns true if type is a basic type', () {
          expect(isBasicType(1), true);
          expect(isBasicType(1.0), true);
          expect(isBasicType('1'), true);
          expect(isBasicType(true), true);
          expect(isBasicType(false), true);
          expect(isBasicType(<dynamic>{}), false);
        });
      });

      group('_jsonString(Map)', () {
        test('converts a map into a json string', () {
          final jsonString = jh.testJsonString;
          expect(jsonString({'a': 1}), '{"a":1}');
          expect(jsonString({'a': 'b'}), '{"a":"b"}');
          expect(jsonString({'a': true}), '{"a":true}');
          expect(jsonString({'a': false}), '{"a":false}');
          expect(jsonString({'a': 1.0}), '{"a":1}');
          expect(
            jsonString({
              'a': [1, 2],
            }),
            '{"a":[1,2]}',
          );
          expect(
            jsonString({
              'a': {'b': 1},
            }),
            '{"a":{"b":1}}',
          );
        });

        test('throws when unsupported type', () {
          final jsonString = jh.testJsonString;
          String? message;
          try {
            jsonString({'a': Error()});
          } catch (e) {
            message = e.toString();
          }

          expect(message, 'Exception: Unsupported type: Error');
        });
      });

      group('_convertBasicType(String)', () {
        test('with a string', () {
          expect(jh.testConvertBasicType('hello'), 'hello');
        });

        test('with an int', () {
          expect(jh.testConvertBasicType(10), 10);
        });

        test('with a double', () {
          expect(jh.testConvertBasicType(true), true);
        });

        test('with a non-basic type', () {
          String message = '';
          try {
            jh.testConvertBasicType(<dynamic>{});
          } catch (e) {
            message = e.toString();
          }

          expect(message, 'Exception: Unsupported type: _Set<dynamic>');
        });
      });
    });

    group('validate', () {
      group('with an empty json', () {
        group('throws', () {
          test('when no hash is given', () {
            String? message;

            try {
              jh.validate({});
            } catch (e) {
              message = e.toString();
            }

            expect(message, 'Exception: Hash is missing.');
          });

          test('when hash is wrong', () {
            String? message;

            try {
              jh.validate({'_hash': 'wrongHash'});
            } catch (e) {
              message = e.toString();
            }

            expect(
              message,
              'Exception: Hash "wrongHash" is wrong. Should be "RBNvo1WzZ4oRRq0W9-hknp".',
            );
          });
        });

        group('does not throw', () {
          test('when hash is correct', () {
            expect(
              () => jh.validate({'_hash': 'RBNvo1WzZ4oRRq0W9-hknp'}),
              isNot(throwsA(anything)),
            );
          });
        });
      });

      group('with a single level json', () {
        group('throws', () {
          test('when no hash is given', () {
            String? message;

            try {
              jh.validate({'key': 'value'});
            } catch (e) {
              message = e.toString();
            }

            expect(message, 'Exception: Hash is missing.');
          });

          test('when hash is wrong', () {
            String? message;

            try {
              jh.validate({'key': 'value', '_hash': 'wrongHash'});
            } catch (e) {
              message = e.toString();
            }

            expect(
              message,
              'Exception: Hash "wrongHash" is wrong. Should be "5Dq88zdSRIOcAS-WM_lYYt".',
            );
          });
        });

        group('does not throw', () {
          test('when hash is correct', () {
            expect(
              () => jh.validate(
                {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
              ),
              isNot(throwsA(anything)),
            );
          });
        });
      });

      group('with a deeply nested json', () {
        late Map<String, dynamic> json2;

        setUp(() {
          json2 = {
            '_hash': 'oEE88mHZ241BRlAfyG8n9X',
            'parent': {
              '_hash': '3Wizz29YgTIc1LRaN9fNfK',
              'child': {
                'key': 'value',
                '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
              },
            },
          };
        });

        group('throws', () {
          group('when no hash is given', () {
            test('at the root', () {
              String? message;
              json2.remove('_hash');

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Hash is missing.');
            });

            test('at the parent', () {
              String? message;
              json2['parent'].remove('_hash');

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Hash at /parent is missing.');
            });

            test('at the child', () {
              String? message;
              json2['parent']['child'].remove('_hash');

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Hash at /parent/child is missing.');
            });
          });

          group('when hash is wrong', () {
            test('at the root', () {
              String? message;
              json2['_hash'] = 'wrongHash';

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash "wrongHash" is wrong. Should be "oEE88mHZ241BRlAfyG8n9X".',
              );
            });

            test('at the parent', () {
              String? message;
              json2['parent']['_hash'] = 'wrongHash';

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash at /parent "wrongHash" is wrong. Should be "3Wizz29YgTIc1LRaN9fNfK".',
              );
            });

            test('at the child', () {
              String? message;
              json2['parent']['child']['_hash'] = 'wrongHash';

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash at /parent/child "wrongHash" is wrong. Should be "5Dq88zdSRIOcAS-WM_lYYt".',
              );
            });
          });

          group('not', () {
            test('when hash is correct', () {
              expect(() => jh.validate(json2), isNot(throwsA(anything)));
            });
          });
        });
      });

      group('with a deeply nested json with child array', () {
        late Map<String, dynamic> json2;

        setUp(() {
          json2 = {
            '_hash': 'IoJ_C8gm8uVu8ExpS7ZNPY',
            'parent': [
              {
                '_hash': 'kDsVfUjnkXU7_KXqp-PuyA',
                'child': [
                  {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
                ],
              },
            ],
          };
        });

        group('throws', () {
          group('when no hash is given', () {
            test('at the parent', () {
              String? message;
              json2['parent'][0].remove('_hash');

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(message, 'Exception: Hash at /parent/0 is missing.');
            });

            test('at the child', () {
              String? message;
              json2['parent'][0]['child'][0].remove('_hash');

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash at /parent/0/child/0 is missing.',
              );
            });
          });

          group('when hash is wrong', () {
            test('at the parent', () {
              String? message;
              json2['parent'][0]['_hash'] = 'wrongHash';

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash at /parent/0 "wrongHash" is wrong. Should be "kDsVfUjnkXU7_KXqp-PuyA".',
              );
            });

            test('at the child', () {
              String? message;
              json2['parent'][0]['child'][0]['_hash'] = 'wrongHash';

              try {
                jh.validate(json2);
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                'Exception: Hash at /parent/0/child/0 "wrongHash" is wrong. Should be "5Dq88zdSRIOcAS-WM_lYYt".',
              );
            });
          });

          group('not', () {
            test('when hash is correct', () {
              expect(() => jh.validate(json2), isNot(throwsA(anything)));
            });
          });
        });
      });
    });
  });

  const exampleJson = '''{
    "layerA": {
      "data": [
        {
          "w": 600,
          "w1": 100
        },
        {
          "w": 700,
          "w1": 100
        }
      ]
    },
    "layerB": {
      "data": [
        {
          "d": 268,
          "d1": 100
        }
      ]
    },
    "layerC": {
      "data": [
        {
          "h": 800
        }
      ]
    },
    "layerD": {
      "data": [
        {
          "wMin": 0,
          "wMax": 900,
          "w1Min": 0,
          "w1Max": 900
        }
      ]
    },
    "layerE": {
      "data": [
        {
          "type": "XYZABC",
          "widths": "sLZpHAffgchgJnA++HqKtO",
          "depths": "k1IL2ctZHw4NpaA34w0d0I",
          "heights": "GBLHz0ayRkVUlms1wHDaJq",
          "ranges": "9rohAG49drWZs9tew4rDef"
        }
      ]
    },
    "layerF": {
      "data": [
        {
          "type": "XYZABC",
          "name": "Unterschrank 60cm"
        }
      ]
    },
    "layerG": {
      "data": [
        {
          "type": "XYZABC",
          "name": "Base Cabinet 23.5"
        }
      ]
    }
  }''';

  const exampleJsonWithHashes = '''{
    "layerA": {
      "data": [
        {
          "w": 600,
          "w1": 100,
          "_hash": "ajRQhCx6QLPI8227B72r8I"
        },
        {
          "w": 700,
          "w1": 100,
          "_hash": "Jf177UAntzI4rIjKiU_MVt"
        }
      ],
      "_hash": "qCgcNNF3wJPfx0rkRDfoSY"
    },
    "layerB": {
      "data": [
        {
          "d": 268,
          "d1": 100,
          "_hash": "9mJ7aZJexhfz8IfwF6bsuW"
        }
      ],
      "_hash": "tb0ffNF2ePpqsRxmvMDRrt"
    },
    "layerC": {
      "data": [
        {
          "h": 800,
          "_hash": "KvMHhk1dYYQ2o5Srt6pTUN"
        }
      ],
      "_hash": "Z4km_FzQoxyck-YHQDZMtV"
    },
    "layerD": {
      "data": [
        {
          "wMin": 0,
          "wMax": 900,
          "w1Min": 0,
          "w1Max": 900,
          "_hash": "6uw0BSIllrk6DuKyvQh-Rg"
        }
      ],
      "_hash": "qFDAzWUsTnqICnpc_rJtax"
    },
    "layerE": {
      "data": [
        {
          "type": "XYZABC",
          "widths": "sLZpHAffgchgJnA++HqKtO",
          "depths": "k1IL2ctZHw4NpaA34w0d0I",
          "heights": "GBLHz0ayRkVUlms1wHDaJq",
          "ranges": "9rohAG49drWZs9tew4rDef",
          "_hash": "65LigWuYVGgifKnEZaOJET"
        }
      ],
      "_hash": "pDRglh2oWJcghTzzrzTLw6"
    },
    "layerF": {
      "data": [
        {
          "type": "XYZABC",
          "name": "Unterschrank 60cm",
          "_hash": "gjzETUIUf563ZJNHVEY9Wt"
        }
      ],
      "_hash": "r1u6gR8WLzPAZ3lEsAqREP"
    },
    "layerG": {
      "data": [
        {
          "type": "XYZABC",
          "name": "Base Cabinet 23.5",
          "_hash": "DEyuShUHDpWSJ7Rq_a3uz6"
        }
      ],
      "_hash": "3meyGs7XhOh8gWFNQFYZDI"
    },
    "_hash": "OmmdaqCAhcIKnDm7lT-_gI"
  }''';
}
