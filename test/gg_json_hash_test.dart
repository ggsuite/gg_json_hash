// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_json_hash/gg_json_hash.dart';
import 'package:test/test.dart';

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

void main() {
  group('JsonHash', () {
    late JsonHash jh;

    setUp(() {
      jh = JsonHash.defaultInstance;
    });

    group('apply(json)', () {
      group('adds correct hashes to', () {
        group('simple json', () {
          group('containing only one key value pair', () {
            test('with a string value', () {
              final json = jh.apply({'key': 'value'});
              expect(json['key'], equals('value'));
              final expectedHash = jh.calcHash('{"key":"value"}');
              expect(json['_hash'], equals(expectedHash));
              expect(json['_hash'], equals('5Dq88zdSRIOcAS-WM_lYYt'));
            });

            test('with an int value', () {
              final json = jh.apply({'key': 1});
              expect(json['key'], equals(1));
              final expectedHash = jh.calcHash('{"key":1}');
              expect(json['_hash'], equals(expectedHash));
              expect(json['_hash'], equals('t4HVsGBJblqznOBwy6IeLt'));
            });

            test('with a double value without commas', () {
              final json = jh.apply({'key': 1.0});
              expect(json['key'], equals(1));
              final expectedHash = jh.calcHash('{"key":1}');
              expect(json['_hash'], equals(expectedHash));
              expect(json['_hash'], equals('t4HVsGBJblqznOBwy6IeLt'));
            });

            test('with a bool value', () {
              final json = jh.apply({'key': true});
              expect(json['key'], equals(true));
              final expectedHash = jh.calcHash('{"key":true}');
              expect(json['_hash'], equals(expectedHash));
              expect(json['_hash'], equals('dNkCrIe79x2dPyf5fywwYO'));
            });

            test(
              'with a null value',
              () {
                final json = jh.apply({'key': null, '_hash': ''});
                expect(json['key'], null);
                final expectedHash = jh.calcHash('{"key":null}');
                expect(json['_hash'], expectedHash);
                expect(json['_hash'], 'BZwS6bAVtKxSW0AW5y8ANk');
              },
            );

            test('with an array with null values', () {
              final json = jh.apply({
                'key': [1, 2, null, 3],
              });
              expect(json['key'], equals([1, 2, null, 3]));
              final expectedHash = jh.calcHash('{"key":[1,2,null,3]}');
              expect(json['_hash'], equals(expectedHash));
              expect(json['_hash'], equals('TJBZ_lVlkDw6WlF8esM0I5'));
            });
          });

          test('existing _hash should be overwritten', () {
            final json = jh.apply(
              {
                'key': 'value',
                '_hash': 'oldHash',
              },
              throwOnWrongHashes: false,
            );
            expect(json['key'], equals('value'));
            final expectedHash = jh.calcHash('{"key":"value"}');
            expect(json['_hash'], equals(expectedHash));
            expect(json['_hash'], equals('5Dq88zdSRIOcAS-WM_lYYt'));
          });

          group('containing three key value pairs', () {
            final json0 = {
              'a': 'value',
              'b': 1.0,
              'c': true,
            };

            final json1 = {
              'b': 1.0,
              'a': 'value',
              'c': true,
            };

            late Map<String, dynamic> j0;
            late Map<String, dynamic> j1;

            setUp(() {
              j0 = jh.apply(json0);
              j1 = jh.apply(json1);
            });

            test('should create a string of key value pairs and hash it', () {
              final expectedHash = jh.calcHash('{"a":"value","b":1,"c":true}');

              expect(j0['_hash'], equals(expectedHash));
              expect(j1['_hash'], equals(expectedHash));
            });

            test('should work independent of key order', () {
              expect(j0, equals(j1));
              expect(j0['_hash'], equals(j1['_hash']));
              expect(true.toString(), equals('true'));
            });
          });
        });

        group('nested json', () {
          test('of level 1', () {
            final parent = jh.apply({
              'key': 'value',
              'child': {
                'key': 'value',
              },
            });

            final child = parent['child'];
            final childHash = jh.calcHash(jsonEncode({'key': 'value'}));
            expect(child['_hash'], equals(childHash));

            final parentHash = jh.calcHash(
              jsonEncode({'child': childHash, 'key': 'value'}),
            );

            expect(parent['_hash'], equals(parentHash));
          });

          test('of level 2', () {
            final parent = jh.apply({
              'key': 'value',
              'child': {
                'key': 'value',
                'grandChild': {
                  'key': 'value',
                },
              },
            });

            final grandChild = parent['child']['grandChild'];
            final grandChildHash = jh.calcHash(jsonEncode({'key': 'value'}));
            expect(grandChild['_hash'], equals(grandChildHash));

            final child = parent['child'];
            final childHash = jh.calcHash(
              jsonEncode({'grandChild': grandChildHash, 'key': 'value'}),
            );
            expect(child['_hash'], equals(childHash));

            final parentHash = jh.calcHash(
              jsonEncode({'child': childHash, 'key': 'value'}),
            );
            expect(parent['_hash'], equals(parentHash));
          });
        });

        test('complete json example', () {
          final json = jsonDecode(exampleJson) as Map<String, dynamic>;
          final hashedJson = jh.apply(json);

          final hashedJsonString =
              const JsonEncoder.withIndent('  ').convert(hashedJson);
          expect(hashedJsonString, equals(exampleJsonWithHashes));
        });

        group('data containing arrays', () {
          group('on top level', () {
            group('containing only simple types', () {
              test('should convert all values to strings and hash it', () {
                final json = jh.apply({
                  'key': ['value', 1.0, true],
                });

                final expectedHash = jh.calcHash(
                  jsonEncode({
                    'key': ['value', 1, true],
                  }),
                );

                expect(json['_hash'], equals(expectedHash));
                expect(json['_hash'], equals('nbNb1YfpgqnPfyFTyCQ5YF'));
              });
            });

            group('containing nested objects', () {
              group('should hash the nested objects', () {
                group('and use the hash instead of the stringified value', () {
                  test('with a complicated array', () {
                    final json = jh.apply({
                      'array': [
                        'key',
                        1.0,
                        true,
                        {'key1': 'value1'},
                        {'key0': 'value0'},
                      ],
                    });

                    final h0 = jh.calcHash(jsonEncode({'key0': 'value0'}));
                    final h1 = jh.calcHash(jsonEncode({'key1': 'value1'}));
                    final expectedHash = jh.calcHash(
                      jsonEncode({
                        'array': ['key', 1, true, h1, h0],
                      }),
                    );

                    expect(json['_hash'], equals(expectedHash));
                    expect(json['_hash'], equals('13h_Z0wZCF4SQsTyMyq5dV'));
                  });

                  test('with a simple array', () {
                    final json = jh.apply({
                      'array': [
                        {'key': 'value'},
                      ],
                    });

                    final itemHash = jh.calcHash(jsonEncode({'key': 'value'}));
                    final array = json['array'];
                    final item0 = array[0];
                    expect(item0['_hash'], equals(itemHash));
                    expect(itemHash, equals('5Dq88zdSRIOcAS-WM_lYYt'));

                    final expectedHash = jh.calcHash(
                      jsonEncode({
                        'array': [itemHash],
                      }),
                    );

                    expect(json['_hash'], equals(expectedHash));
                    expect(json['_hash'], equals('zYcZBAUGLgR0ygMxi0V5ZT'));
                  });
                });
              });
            });

            group('containing nested arrays', () {
              test('should hash the nested arrays', () {
                final json = jh.apply({
                  'array': [
                    ['key', 1.0, true],
                    'hello',
                  ],
                });

                final jsonHash = jh.calcHash(
                  jsonEncode({
                    'array': [
                      ['key', 1, true],
                      'hello',
                    ],
                  }),
                );

                expect(json['_hash'], equals(jsonHash));
                expect(json['_hash'], equals('1X_6COC1sP5ECuHvKtVoDT'));
              });
            });
          });
        });
      });

      group('writes the hashes directly into the given json', () {
        group('when ApplyJsonHashConfig.inPlace is true', () {
          test('writes hashes into original json', () {
            final json = {
              'key': 'value',
            };

            final hashedJson = jh.apply(json, inPlace: true);
            expect(
              hashedJson,
              equals({
                'key': 'value',
                '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
              }),
            );

            expect(json, equals(hashedJson));
          });
        });
      });

      group('writes the hashes into a copy', () {
        group('when ApplyJsonHashConfig.inPlace is false', () {
          test('does not touch the original object', () {
            final json = {
              'key': 'value',
            };

            // The returned copy has the hashes
            final hashedJson = jh.apply(json, inPlace: false);
            expect(
              hashedJson,
              equals({
                'key': 'value',
                '_hash': '5Dq88zdSRIOcAS-WM_lYYt',
              }),
            );

            // The original json is untouched
            expect(
              json,
              equals({
                'key': 'value',
              }),
            );
          });
        });
      });

      group('replaces/updates existing hashes', () {
        group('when ApplyJsonHashConfig.updateExistingHashes is set to true',
            () {
          bool allHashesChanged(Map<String, dynamic> json) {
            return json['a']['_hash'] != 'hash_a' &&
                json['a']['b']['_hash'] != 'hash_b' &&
                json['a']['b']['c']['_hash'] != 'hash_c';
          }

          test('should recalculate existing hashes', () {
            final json = <String, dynamic>{
              'a': {
                '_hash': 'hash_a',
                'b': {
                  '_hash': 'hash_b',
                  'c': {
                    '_hash': 'hash_c',
                    'd': 'value',
                  },
                },
              },
            };

            jh.apply(
              json,
              inPlace: true,
              throwOnWrongHashes: false,
            );
            expect(allHashesChanged(json), isTrue);
          });
        });
      });

      group('does not touch existing hashes', () {
        group('when ApplyJsonHashConfig.updateExistingHashes is set to false',
            () {
          late Map<String, dynamic> json;

          bool noHashesChanged() {
            return json['a']['_hash'] == 'hash_a' &&
                json['a']['b']['_hash'] == 'hash_b' &&
                json['a']['b']['c']['_hash'] == 'hash_c';
          }

          setUp(() {
            json = {
              'a': {
                '_hash': 'hash_a',
                'b': {
                  '_hash': 'hash_b',
                  'c': {
                    '_hash': 'hash_c',
                    'd': 'value',
                  },
                },
              },
            };
          });

          List<String> changedHashes() {
            final result = <String>[];
            if (json['a']['_hash'] != 'hash_a') {
              result.add('a');
            }

            if (json['a']['b']['_hash'] != 'hash_b') {
              result.add('b');
            }

            if (json['a']['b']['c']['_hash'] != 'hash_c') {
              result.add('c');
            }

            return result;
          }

          test('with all objects having hashes', () {
            jh.apply(
              json,
              updateExistingHashes: false,
              throwOnWrongHashes: false,
            );
            expect(noHashesChanged(), isTrue);
          });

          test('with parents have no hashes', () {
            json['a'].remove('_hash');
            jh.apply(
              json,
              updateExistingHashes: false,
              throwOnWrongHashes: false,
            );
            expect(changedHashes(), equals(['a']));

            json['a'].remove('_hash');
            json['a']['b'].remove('_hash');
            jh.apply(
              json,
              updateExistingHashes: true,
              throwOnWrongHashes: false,
            );
            expect(changedHashes(), equals(['a', 'b']));
          });
        });
      });

      group('checks numbers', () {
        test('.e. throws when NaN is given', () {
          String? message;

          try {
            jh.apply({
              'key': double.nan,
            });
          } catch (e) {
            message = e.toString();
          }

          expect(message, equals('Exception: NaN is not supported.'));
        });

        test('i.e. throws when json contains an unsupported type', () {
          String? message;

          try {
            jh.apply({
              'key': Error(),
            });
          } catch (e) {
            message = e.toString();
          }

          expect(message, equals('Exception: Unsupported type: Error'));
        });

        group('i.e. ensures numbers have the right precision', () {
          group(
            'i.e. it does not throw when numbers have right maximum precision',
            () {
              test('e.g. 1.001', () {
                expect(() => jh.apply({'key': 1.001}), returnsNormally);
              });

              test('e.g. 1.123', () {
                expect(() => jh.apply({'key': 1.123}), returnsNormally);
              });

              test('e.g. -1.123', () {
                expect(() => jh.apply({'key': -1.123}), returnsNormally);
              });

              test('e.g. 1e-2', () {
                expect(() => jh.apply({'key': 1e-2}), returnsNormally);
              });
            },
          );

          group(
            'i.e. it does throw when numbers do not match maximum precision',
            () {
              group('e.g. numbers have more commas then precision allows', () {
                test('e.g. 1.0001', () {
                  expect(jh.config.numberConfig.precision, equals(0.001));

                  String message = '';
                  try {
                    jh.apply({
                      'key': 1.0001,
                    });
                  } catch (e) {
                    message = e.toString();
                  }

                  expect(
                    message,
                    equals(
                      'Exception: Number 1.0001 has a higher precision '
                      'than 0.001.',
                    ),
                  );
                });

                test('e.g. 1.1234', () {
                  expect(jh.config.numberConfig.precision, equals(0.001));

                  String message = '';
                  try {
                    jh.apply({
                      'key': 1.1234,
                    });
                  } catch (e) {
                    message = e.toString();
                  }

                  expect(
                    message,
                    equals(
                      'Exception: Number 1.1234 has a higher precision '
                      'than 0.001.',
                    ),
                  );
                });

                test('e.g. -1.0001', () {
                  expect(jh.config.numberConfig.precision, equals(0.001));

                  String message = '';
                  try {
                    jh.apply({
                      'key': -1.0001,
                    });
                  } catch (e) {
                    message = e.toString();
                  }

                  expect(
                    message,
                    equals(
                      'Exception: Number -1.0001 has a higher precision '
                      'than 0.001.',
                    ),
                  );
                });

                test('e.g. -1.1234', () {
                  expect(jh.config.numberConfig.precision, equals(0.001));

                  String message = '';
                  try {
                    jh.apply({
                      'key': -1.1234,
                    });
                  } catch (e) {
                    message = e.toString();
                  }

                  expect(
                    message,
                    equals(
                      'Exception: Number -1.1234 has a higher precision '
                      'than 0.001.',
                    ),
                  );
                });

                test('e.g. 9839089403.1235', () {
                  expect(jh.config.numberConfig.precision, equals(0.001));

                  String message = '';
                  try {
                    jh.apply({
                      'key': 9839089403.1235,
                    });
                  } catch (e) {
                    message = e.toString();
                  }

                  expect(
                    message,
                    equals(
                      'Exception: Number 9839089403.1235 has a higher '
                      'precision than 0.001.',
                    ),
                  );
                });

                test('e.g. 9839089403.1235', () {
                  expect(jh.config.numberConfig.precision, equals(0.001));

                  String message = '';
                  try {
                    jh.apply({
                      'key': 0.1e-4,
                    });
                  } catch (e) {
                    message = e.toString();
                  }

                  expect(
                    message,
                    equals(
                      'Exception: Number 0.00001 has a higher precision '
                      'than 0.001.',
                    ),
                  );
                });
              });
            },
          );
        });

        group('i.e. ensures numbers are in the given range', () {
          group('i.e. values exceed NumbersConfig.maxNum', () {
            late double max;

            setUp(() {
              max = jh.config.numberConfig.maxNum;
            });

            void check(double val) {
              String message = '';
              val = double.parse(val.toStringAsFixed(3));

              try {
                jh.apply({'key': val});
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                equals(
                  'Exception: Number $val exceeds '
                  'NumberHashingConfig.maxNum.',
                ),
              );
            }

            test('.e.g. shortly above the maximum', () {
              check(max + 0.001);
            });
          });

          group('i.e. values exceed NumbersConfig.maxNum', () {
            late double min;

            setUp(() {
              min = jh.config.numberConfig.minNum;
            });

            void check(double val) {
              String message = '';
              val = double.parse(val.toStringAsFixed(3));

              try {
                jh.apply({'key': val});
              } catch (e) {
                message = e.toString();
              }

              expect(
                message,
                equals(
                  'Exception: Number $val is smaller '
                  'NumberHashingConfig.minNum.',
                ),
              );
            }

            test('.e.g. shortly above the maximum', () {
              check(min - 0.001);
            });
          });
        });
      });

      group('throws, when existing hashes do not match newly calculated ones',
          () {
        group('when ApplyJsonHashConfig.throwOnWrongHashes is set to true', () {
          test('with a simple json', () {
            final json = {
              'key': 'value',
              '_hash': 'wrongHash',
            };

            String message = '';
            try {
              jh.apply(json, throwOnWrongHashes: true);
            } catch (e) {
              message = e.toString();
            }

            expect(
              message,
              equals(
                'Exception: Hash "wrongHash" does not match the newly '
                'calculated one "5Dq88zdSRIOcAS-WM_lYYt". '
                'Please make sure that all systems are producing '
                'the same hashes.',
              ),
            );
          });
        });

        group(
            'but not when ApplyJsonHashConfig.throwOnWrongHashes '
            'is set to false', () {
          test('with a simple json', () {
            final json = {
              'key': 'value',
              '_hash': 'wrongHash',
            };

            jh.apply(
              json,
              throwOnWrongHashes: false,
              inPlace: true,
            );
            expect(json['_hash'], equals('5Dq88zdSRIOcAS-WM_lYYt'));
          });
        });
      });
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

    group('applyInPlace(json)', () {
      group('default', () {
        test('replaces empty hashes with the correct ones', () {
          final json = {
            'key': 'value',
            '_hash': '',
          };

          jh.applyInPlace(json);
          expect(json['_hash'], equals('5Dq88zdSRIOcAS-WM_lYYt'));
        });

        test('throws when existing hashes are wrong', () {
          final json = {
            'key': 'value',
            '_hash': 'wrongHash',
          };

          String message = '';
          try {
            jh.applyInPlace(json);
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            equals(
              'Exception: Hash "wrongHash" is wrong. '
              'Should be "5Dq88zdSRIOcAS-WM_lYYt".',
            ),
          );
        });

        group('special cases', () {
          test('with a simple json', () {
            jh.applyInPlace({
              'name': 'Set width of UE to 1111',
              'filter': {
                'columnFilters': [
                  {
                    'type': 'string',
                    'column': 'articleType',
                    'operator': 'startsWith',
                    'search': 'UE',
                    '_hash': '',
                  },
                ],
                'operator': 'and',
                '_hash': '',
              },
              'actions': [
                {
                  'column': 'w',
                  'setValue': 1111,
                  '_hash': '',
                },
              ],
              '_hash': '',
            });
          });
        });
      });
    });

    group('addMissingHashes', () {
      test('does nothing when hash is available', () {
        final json0 = hip({'a': 5});
        final json1 = amh({...json0});
        expect(json0, json1);
      });

      test('does not touch the original object', () {
        final json0 = {'a': 5};
        final json1 = amh(json0);
        expect(json0['_hash'], isNull);
        expect(json1['_hash'], isNotEmpty);
      });

      test('does replace null by the hash', () {
        final json = amh({'a': 5, '_hash': null});
        final hash = hsh(json)['_hash'];
        expect(hash, isNotEmpty);
        expect(json['_hash'], hash);
      });

      test('does replace undefined by the hash', () {
        final json = amh({'a': 5});
        final hash = hsh(json)['_hash'];
        expect(hash, isNotEmpty);
        expect(json['_hash'], hash);
      });
    });

    group('copyJson', () {
      const copyJson = JsonHash.copyJson;

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

    group('private methods', () {
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
              'Exception: Hash "wrongHash" is wrong. '
              'Should be "RBNvo1WzZ4oRRq0W9-hknp".',
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
              'Exception: Hash "wrongHash" is wrong. '
              'Should be "5Dq88zdSRIOcAS-WM_lYYt".',
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
                'Exception: Hash "wrongHash" is wrong. '
                'Should be "oEE88mHZ241BRlAfyG8n9X".',
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

      group('special cases', () {
        test('dictionaries with numbers as key', () async {
          // Load test/broken-hashes-bug.rl.json
          final json = {
            '1270537611': 'mxK7Q1zeVB1httPrYsn0ow',
            '522965': 'PAue6PJ83JBmIqoElcDmot',
          };

          jh.apply(
            json,
            updateExistingHashes: true,
            throwOnWrongHashes: false,
            inPlace: true,
          );

          expect(
            json['_hash'],
            equals(
              'W4CAuZT_tIicr6crbn6LA8',
            ),
          );
        });
      });
    });

    group('NumberHashingConfig', () {
      group('copyWith', () {
        test('no params changed', () {
          const nc = NumberHashingConfig();
          final nc2 = nc.copyWith();
          expect(nc.maxNum, equals(nc2.maxNum));
          expect(nc.minNum, equals(nc2.minNum));
          expect(nc.precision, equals(nc2.precision));
        });

        test('with all parameters changed', () {
          const nc = NumberHashingConfig();
          final nc2 = nc.copyWith(
            maxNum: 100,
            minNum: -100,
            precision: 0.1,
          );
          expect(nc2.maxNum, equals(100));
          expect(nc2.minNum, equals(-100));
          expect(nc2.precision, equals(0.1));
        });
      });
    });
  });

  group('hip', () {
    test('Applies hashes in place', () {
      final json = {
        'key': 'value',
        '_hash': '',
      };

      hip(json);
      expect(json['_hash'], equals('5Dq88zdSRIOcAS-WM_lYYt'));
    });
  });

  group('hsh', () {
    test('Returns an object with hahes', () {
      final json = {
        'key': 'value',
        '_hash': '',
      };

      final result = hsh(json);
      expect(result, isA<Map<String, dynamic>>());
      expect(result['_hash'], equals('5Dq88zdSRIOcAS-WM_lYYt'));
    });
  });

  group('areEqual', () {
    group('with ignoreHashes', () {
      group('== true', () {
        test('returns true for deeply equal objects ignoring hashes', () {
          final a = {'x': 1, 'y': 'test', 'z': true, '_hash': 'A'};
          final b = {'x': 1, 'y': 'test', 'z': true, '_hash': 'B'};
          expect(JsonHash.areEqual(a, b, ignoreHashes: true), isTrue);
        });
      });
      group('== false', () {
        test('returns false for different hashes', () {
          final a = {'x': 1, 'y': 'test', 'z': true, '_hash': 'A'};
          final b = {'x': 1, 'y': 'test', 'z': true, '_hash': 'B'};
          expect(JsonHash.areEqual(a, b, ignoreHashes: false), isFalse);
        });
      });
    });

    test('returns true for deeply equal simple maps', () {
      final a = {'x': 1, 'y': 'test', 'z': true};
      final b = {'x': 1, 'y': 'test', 'z': true};
      expect(JsonHash.areEqual(a, b), isTrue);
    });

    test('returns true for deeply equal nested maps', () {
      final a = {
        'a': 1,
        'b': {
          'c': 2,
          'd': [
            1,
            2,
            3,
            {'x': 4},
            [5, 6, 7],
          ],
        },
      };
      final b = {
        'a': 1,
        'b': {
          'c': 2,
          'd': [
            1,
            2,
            3,
            {'x': 4},
            [5, 6, 7],
          ],
        },
      };
      expect(JsonHash.areEqual(a, b), isTrue);
    });

    test('returns false for maps with different values', () {
      final a = {'x': 1, 'y': 'test'};
      final b = {'x': 2, 'y': 'test'};
      expect(JsonHash.areEqual(a, b), isFalse);
    });

    test('returns false for maps with different keys', () {
      final a = {'x': 1, 'y': 'test'};
      final b = {'x': 1, 'z': 'test'};
      expect(JsonHash.areEqual(a, b), isFalse);
    });

    test('returns false for maps with different nested values', () {
      final a = {
        'a': 1,
        'b': {
          'c': 2,
          'd': [1, 2, 3],
        },
      };
      final b = {
        'a': 1,
        'b': {
          'c': 2,
          'd': [1, 2, 4],
        },
      };
      expect(JsonHash.areEqual(a, b), isFalse);
    });

    test('returns false for maps with different list lengths', () {
      final a = {
        'a': [1, 2, 3],
      };
      final b = {
        'a': [1, 2],
      };
      expect(JsonHash.areEqual(a, b), isFalse);
    });

    test('returns true for empty maps', () {
      expect(JsonHash.areEqual({}, {}), isTrue);
    });

    test('returns false for different types in values', () {
      final a = {'a': 1};
      final b = {'a': '1'};
      expect(JsonHash.areEqual(a, b), isFalse);
    });
  });
}
