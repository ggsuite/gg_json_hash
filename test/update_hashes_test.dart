// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateHashes', () {
    group('apply()', () {
      group('throws', () {
        test('when json data contains circular dependencies', () {
          final json = {
            '_hash': 'root',
            'child0': {
              '_hash': 'CHILD0',
              'ref': 'CHILD1',
            },
            'child1': {
              '_hash': 'CHILD1',
              'ref': 'CHILD2',
            },
            'child2': {
              '_hash': 'CHILD2',
              'ref': 'CHILD0',
            },
          };

          var message = '';
          try {
            uh(json);
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            [
              'Exception: Cannot update hashes: '
                  'Circular dependencies detected:',
              '  - CHILD0 -> CHILD1 -> CHILD2 -> CHILD0',
            ].join('\n'),
          );
        });

        test('when json data contains ambiguous hashes', () {
          final json = {
            '_hash': 'root',
            'child0': {
              '_hash': 'CHILD',
              'key': 'a',
            },
            'child1': {
              '_hash': 'CHILD',
              'key': 'b',
            },
          };

          final updateHashes = UpdateHashes(json: json);
          var message = '';
          try {
            updateHashes.apply();
          } catch (e) {
            message = e.toString();
          }

          expect(
            message,
            [
              'Exception: Ambigious hashes detected:',
              '  - CHILD',
            ].join('\n'),
          );
        });
      });

      test('does nothing when hashes are already perfect', () {
        final json = hip({
          'a': '5',
          'b': {
            'c': '6',
          },
        });

        final jsonUpdated = uh(json);
        expect(jsonUpdated, json);
      });

      group('updates hashes and references in an object', () {
        test('that is empty', () {
          const json = {
            '_hash': 'ROOT',
          };

          final uj = uh(json);

          expect(uj, {'_hash': 'RBNvo1WzZ4oRRq0W9-hknp'});
        });

        test('with one child', () {
          const json = {
            '_hash': 'ROOT',
            'child0': {
              '_hash': 'CHILD0',
            },
          };

          final updateHashes = UpdateHashes(json: json);
          updateHashes.apply();

          final uj = updateHashes.updatedJson;

          expect(uj, {
            '_hash': 'StnzK_1GZNY07Y0Ucuv3Sm',
            'child0': {'_hash': 'RBNvo1WzZ4oRRq0W9-hknp'},
          });
        });

        test('with a references to other objects', () {
          const json = {
            '_hash': 'ROOT',
            'child0': {
              '_hash': 'CHILD0',
              'ref': 'CHILD1',
            },
            'child1': {
              '_hash': 'CHILD1',
              'ref': 'CHILD2',
            },
            'child2': {
              '_hash': 'CHILD2',
            },
          };

          final updateHashes = UpdateHashes(json: json);
          updateHashes.apply();

          final uj = updateHashes.updatedJson;

          expect(uj, {
            '_hash': 'oGPF9fMYO89rh97-Y5eVTI',
            'child0': {
              '_hash': '_ByJerk4dXxFMBxPZAapfW',
              'ref': '3PY_gxJ7g-ZyVcwt1JiGLa',
            },
            'child1': {
              '_hash': '3PY_gxJ7g-ZyVcwt1JiGLa',
              'ref': 'RBNvo1WzZ4oRRq0W9-hknp',
            },
            'child2': {'_hash': 'RBNvo1WzZ4oRRq0W9-hknp'},
          });
        });

        test('with nested arrays', () {
          const json = {
            '_hash': 'ROOT',
            'child0': {
              '_hash': 'CHILD0',
              'ref': [
                [
                  {
                    '_hash': 'CHILD1',
                    'ref': [
                      {
                        '_hash': 'CHILD2',
                      },
                      'CHILD3',
                    ],
                  },
                ],
              ],
            },
            'child3': {
              '_hash': 'CHILD3',
              'key': 'VALUE',
            },
          };

          final updateHashes = UpdateHashes(json: json);
          updateHashes.apply();

          final uj = updateHashes.updatedJson;

          expect(uj, {
            '_hash': 'JemEH8yDi5s4UkazrZhpwt',
            'child0': {
              '_hash': 'HG90sRuwNhlwRo8bqty8BF',
              'ref': [
                [
                  {
                    '_hash': 'G1fQls2aKWdRBynY-l069A',
                    'ref': [
                      {'_hash': 'RBNvo1WzZ4oRRq0W9-hknp'},
                      'JczQWaAeuCdYpXBHjbUNr_',
                    ],
                  }
                ]
              ],
            },
            'child3': {'_hash': 'JczQWaAeuCdYpXBHjbUNr_', 'key': 'VALUE'},
          });
        });

        group('with multiple identical child objects', () {
          test('with same hashes', () {
            const json = {
              '_hash': 'ROOT',
              'array': [
                {
                  'key': 'value',
                  '_hash': 'HASH',
                },
                {
                  'key': 'value',
                  '_hash': 'HASH',
                },
              ],
            };

            final updateHashes = UpdateHashes(json: json);
            updateHashes.apply();

            expect(updateHashes.updatedJson, {
              '_hash': 'dBrRvbCChojFe3hqOrpydA',
              'array': [
                {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
                {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
              ],
            });
          });

          test('with different hashes', () {
            const json = {
              '_hash': 'ROOT',
              'array': [
                {
                  'key': 'value',
                  '_hash': 'HASH0',
                },
                {
                  'key': 'value',
                  '_hash': 'HASH1',
                },
              ],
              'ref0': 'HASH0',
              'ref1': 'HASH1',
            };

            final updateHashes = UpdateHashes(json: json);
            updateHashes.apply();

            expect(updateHashes.updatedJson, {
              '_hash': 'Mz_OFBqW1yngka9qbGJ1Yn',
              'array': [
                {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
                {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
              ],
              'ref0': '5Dq88zdSRIOcAS-WM_lYYt',
              'ref1': '5Dq88zdSRIOcAS-WM_lYYt',
            });
          });
        });

        test('with keys that are hashes', () {
          const json = {
            '_hash': 'ROOT',
            'child0': {
              '_hash': 'CHILD0',
              'ref': {
                '_hash': 'CHILD1',
                'key': 'value',
              },
            },
            'CHILD0': {
              'a': 5,
            },
            'CHILD1': {
              'b': 6,
            },
          };

          final updateHashes = UpdateHashes(json: json);
          updateHashes.apply();
          final uj = updateHashes.updatedJson;
          expect(uj, {
            '_hash': 'Xti9lpVaLOoytoiqRagT_V',
            'child0': {
              '_hash': 'J9DWPP6vhXvqJ1txvk1F1n',
              'ref': {'_hash': '5Dq88zdSRIOcAS-WM_lYYt', 'key': 'value'},
            },
            'J9DWPP6vhXvqJ1txvk1F1n': {
              'a': 5,
              '_hash': 'sugxnSwo3OC4Png24DZ1Dw',
            },
            '5Dq88zdSRIOcAS-WM_lYYt': {
              'b': 6,
              '_hash': 'yrjcDewZICiUowpefTcsGb',
            },
          });
        });

        group('with hashes as pathes', () {
          test('delimited by /', () {
            const json = {
              '_hash': 'ROOT',
              'child0': {
                '_hash': 'CHILD0',
                'ref': {
                  '_hash': 'CHILD1',
                  'key': 'value',
                },
              },
              '/CHILD0/CHILD1': {
                'a': 5,
              },
              'child2': {
                'b': '/CHILD1/CHILD0',
              },
            };

            final updateHashes = UpdateHashes(json: json);
            updateHashes.apply();
            final uj = updateHashes.updatedJson;
            expect(uj, {
              '_hash': 'mRHgTEhgWEy0g27nquOzxq',
              'child0': {
                '_hash': 'J9DWPP6vhXvqJ1txvk1F1n',
                'ref': {'_hash': '5Dq88zdSRIOcAS-WM_lYYt', 'key': 'value'},
              },
              'child2': {
                'b': '/5Dq88zdSRIOcAS-WM_lYYt/J9DWPP6vhXvqJ1txvk1F1n',
                '_hash': 'LoOEAbAbJkq2HR0zn2fayc',
              },
              '/J9DWPP6vhXvqJ1txvk1F1n/5Dq88zdSRIOcAS-WM_lYYt': {
                'a': 5,
                '_hash': 'sugxnSwo3OC4Png24DZ1Dw',
              },
            });
          });

          test('delimited by :', () {
            const json = {
              '_hash': 'ROOT',
              'child0': {
                '_hash': 'CHILD0',
                'ref': {
                  '_hash': 'CHILD1',
                  'key': 'value',
                },
              },
              ':CHILD0:CHILD1': {
                'a': 5,
              },
              'child2': {
                'b': ':CHILD1:CHILD0',
              },
            };

            final updateHashes = UpdateHashes(json: json);
            updateHashes.apply();
            final uj = updateHashes.updatedJson;
            expect(uj, {
              '_hash': '-eI585GkWNj79UAnrKkQfI',
              'child0': {
                '_hash': 'J9DWPP6vhXvqJ1txvk1F1n',
                'ref': {'_hash': '5Dq88zdSRIOcAS-WM_lYYt', 'key': 'value'},
              },
              'child2': {
                'b': ':5Dq88zdSRIOcAS-WM_lYYt:J9DWPP6vhXvqJ1txvk1F1n',
                '_hash': 'GSbLchOIE7Kaac2WAmUxqu',
              },
              ':J9DWPP6vhXvqJ1txvk1F1n:5Dq88zdSRIOcAS-WM_lYYt': {
                'a': 5,
                '_hash': 'sugxnSwo3OC4Png24DZ1Dw',
              },
            });
          });

          test('delimited by : and /', () {
            const json = {
              '_hash': 'ROOT',
              'child0': {
                '_hash': 'CHILD0',
                'ref': {
                  '_hash': 'CHILD1',
                  'key': 'value',
                },
              },
              '/CHILD0:CHILD1': {
                'a': 5,
              },
              'child2': {
                'b': ':CHILD1/CHILD0',
              },
            };

            final updateHashes = UpdateHashes(json: json);
            updateHashes.apply();
            final uj = updateHashes.updatedJson;
            expect(uj, {
              '_hash': '_snIhEY3on5kr0oHJ1m94s',
              'child0': {
                '_hash': 'J9DWPP6vhXvqJ1txvk1F1n',
                'ref': {'_hash': '5Dq88zdSRIOcAS-WM_lYYt', 'key': 'value'},
              },
              'child2': {
                'b': ':5Dq88zdSRIOcAS-WM_lYYt/J9DWPP6vhXvqJ1txvk1F1n',
                '_hash': 'asj8b1uU1Se-d8txkshOFA',
              },
              '/J9DWPP6vhXvqJ1txvk1F1n:5Dq88zdSRIOcAS-WM_lYYt': {
                'a': 5,
                '_hash': 'sugxnSwo3OC4Png24DZ1Dw',
              },
            });
          });
        });
      });

      group('special cases', () {
        group('one hash containing another hash', () {
          test('should be handled correctly', () {
            const json = {
              '_hash': 'ROOT',
              'child0': {
                '_hash': 'A_B',
                'key': '0',
              },
              'child1': {
                '_hash': 'C_D',
                'key': '1',
              },
              'child3': {
                '_hash': 'A_B_C_D',
                'key': '3',
              },
              'child4': {
                'ref': 'A_B_C_D',
                'key': '4',
              },
            };

            final uh = UpdateHashes(json: json);
            uh.apply();

            expect(uh.updatedJson, {
              '_hash': 'gtrP8T-j8dPmyLK3dVtGuK',
              'child0': {'_hash': 'OOMROmpHVL_tNlj89AeGWM', 'key': '0'},
              'child1': {'_hash': 'FcuGj40TVvIS7aVXvQCc2l', 'key': '1'},
              'child3': {'_hash': 'ZOgYhRKyox862udZ3kaYvL', 'key': '3'},
              'child4': {
                'ref': 'ZOgYhRKyox862udZ3kaYvL',
                'key': '4',
                '_hash': 'm8a0Pq2xVAS1AeCekSqCCu',
              },
            });
          });
        });
      });
    });
  });

  group('updateHint', () {
    test('shows which hashes need to be updated', () {
      const json = {
        '_hash': 'WRONG0',
        'key': {
          '_hash': 'WRONG1',
          'key': {
            '_hash': 'WRONG2',
            'key': '1',
          },
        },
      };

      expect(updateHint(json).split('\n'), [
        'The following hashes need to be replaced:',
        '  - WRONG2 -> FcuGj40TVvIS7aVXvQCc2l',
        '  - WRONG1 -> PlM9222uvfw_rhet-GZZgz',
        '  - WRONG0 -> McfplpnHJ5e18OxKk4rwh5',
      ]);
    });

    test('shows a message, when all hashes are uptodate', () {
      final json = hip({'key': 1});
      expect(updateHint(json), 'All hashes are up to date.');
    });
  });
}
