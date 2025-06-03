// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';
import 'package:test/test.dart';

void main() {
  group('UpdateHashes', () {
    bool isInitialized = false;
    late final JsonInfo ji0;
    late final JsonInfo ji1;
    late final JsonInfo ji2;

    const json0 = <String, dynamic>{};

    const json1 = <String, dynamic>{
      '_hash': 'ROOT',
      'parent0': {
        '_hash': 'PARENT',
        'child0': {'_hash': 'CHILD0'},
      },
      'parent1': {
        '_hash': 'PARENT',
        'child1': {'_hash': 'CHILD1'},
      },
      'list': [
        {
          '_hash': 'LIST0',
          'child0': {'_hash': 'CHILD3'},
        },
        {
          '_hash': 'LIST1',
          'child1': {'_hash': 'CHILD4'},
        },
      ],
    };

    const json2 = <String, dynamic>{
      'key1': 'value1',
      'key2': 'value2',
      '_hash': 'PARENT',
    };

    void init() {
      if (isInitialized) {
        return;
      } else {
        ji0 = JsonInfo(json: json0);
        ji1 = JsonInfo(json: json1);
        ji2 = JsonInfo(json: json2);
        isInitialized = true;
      }
    }

    group('json', () {
      test('returns the original object with added hashes', () {
        const json = {
          'child': {
            'key': 'value',
          },
        };

        final ji = JsonInfo(json: json);

        expect(
          ji.json,
          {
            'child': {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
            '_hash': '3Wizz29YgTIc1LRaN9fNfK',
          },
        );
      });
      test('returns the json to be fixed', () {
        init();
        expect(ji1.json, json1);
        expect(ji2.json, json2);
      });
    });

    group('allObjects, allHashes', () {
      group('returns a list of all objects', () {
        test('for a deeply nested object', () {
          init();
          final oh = ji1.allObjects.map((e) => e['_hash']).toList();
          expect(
            oh,
            [
              'ROOT',
              'PARENT',
              'CHILD0',
              'PARENT',
              'CHILD1',
              'LIST0',
              'CHILD3',
              'LIST1',
              'CHILD4',
            ],
          );

          expect(ji1.allHashes, [
            'ROOT',
            'PARENT',
            'CHILD0',
            'CHILD1',
            'LIST0',
            'CHILD3',
            'LIST1',
            'CHILD4',
          ]);
        });

        test('for object in an array', () {
          const json = {
            '_hash': 'ROOT',
            'list': [
              {
                '_hash': 'CHILD0',
              },
              {
                '_hash': 'CHILD1',
              },
            ],
          };

          final ji = JsonInfo(
            json: json,
          );

          final oh = ji.allObjects.map((e) => e['_hash']).toList();
          expect(
            oh,
            [
              'ROOT',
              'CHILD0',
              'CHILD1',
            ],
          );

          expect(ji.allHashes, [
            'ROOT',
            'CHILD0',
            'CHILD1',
          ]);
        });

        test('for object in an array in an array', () {
          const json = {
            '_hash': 'ROOT',
            'list': [
              [
                {
                  '_hash': 'CHILD0',
                },
                {
                  '_hash': 'CHILD1',
                },
              ],
            ],
          };

          final ji = JsonInfo(
            json: json,
          );

          final oh = ji.allObjects.map((e) => e['_hash']).toList();
          expect(
            oh,
            [
              'ROOT',
              'CHILD0',
              'CHILD1',
            ],
          );

          expect(ji.allHashes, [
            'ROOT',
            'CHILD0',
            'CHILD1',
          ]);
        });

        test('for an object with missing _hashes', () {
          const json = {
            'child0': {
              'grandChild0': {'_hash': 'HASH0'},
              'grandChild1': {'key': 'value'},
            },
            'child1': {
              '_hash': '',
              'grandChild2': {'_hash': 'HASH1'},
              'grandChild3': {'key': 'value'},
            },
          };

          final ji = JsonInfo(
            json: json,
          );
          final oh = ji.allObjects.map((e) => e['_hash']).toList();
          expect(
            oh,
            [
              'iVVKjjwtuhpDxzXGImf_3P',
              'DJsESW_1W2ADX6zDTubL5f',
              'HASH0',
              '5Dq88zdSRIOcAS-WM_lYYt',
              'hu0mbJM_lBdIk6ydaGZPW-',
              'HASH1',
              '5Dq88zdSRIOcAS-WM_lYYt',
            ],
          );

          expect(ji.allHashes, [
            'iVVKjjwtuhpDxzXGImf_3P',
            'DJsESW_1W2ADX6zDTubL5f',
            'HASH0',
            '5Dq88zdSRIOcAS-WM_lYYt',
            'hu0mbJM_lBdIk6ydaGZPW-',
            'HASH1',
          ]);
        });
      });
    });

    group('ambigiousHashes', () {
      group('returns hashes that are used by multiple different objects', () {
        test('for json without ambigious objects', () {
          const json = {
            'a': {'b': 'c'},
          };

          final ji = JsonInfo(json: json);
          expect(ji.ambigiousHashes, isEmpty);
        });

        group('for ambigious objects', () {
          test('on the same level', () {
            const json = {
              'a': {'b': 'c', '_hash': 'HASH'},
              'c': {'b': 'd', '_hash': 'HASH'},
            };

            final ji = JsonInfo(json: json);
            expect(ji.ambigiousHashes, {
              'HASH': [
                {'b': 'c', '_hash': 'HASH'},
                {'b': 'd', '_hash': 'HASH'},
              ],
            });
          });

          test('on different levels', () {
            const json = {
              'a': {
                'b': {
                  'c': {'_hash': 'HASH', 'key': 'a'},
                },
              },
              'd': {
                'e': {'_hash': 'HASH', 'key': 'b'},
              },
            };

            final ji = JsonInfo(json: json);
            expect(ji.ambigiousHashes, {
              'HASH': [
                {'_hash': 'HASH', 'key': 'a'},
                {'_hash': 'HASH', 'key': 'b'},
              ],
            });
          });

          test('in nested lists', () {
            const json = {
              'a': [
                [
                  {'_hash': 'HASH', 'key': 'a'},
                ],
              ],
              'b': [
                [
                  {'_hash': 'HASH', 'key': 'b'},
                ],
              ],
            };

            final ji = JsonInfo(json: json);
            expect(ji.ambigiousHashes, {
              'HASH': [
                {'_hash': 'HASH', 'key': 'a'},
                {'_hash': 'HASH', 'key': 'b'},
              ],
            });
          });
        });
      });
    });

    group(
        'refDependents, refDependencies, '
        'childDependencies, childDependents, '
        'allDependencies, allDependents', () {
      group('returns a list of objects that reference to a given hash', () {
        test('when the json contains no references', () {
          init();
          expect(ji0.refDependents, <String, List<String>>{});
          expect(ji0.refDependencies, <String, List<String>>{});
          expect(ji1.refDependents, <String, dynamic>{});
          expect(ji1.refDependencies, <String, dynamic>{});
        });

        test('when the object references itself', () {
          const json = {
            '_hash': 'ROOT',
            'ref': 'ROOT',
          };

          final fh = JsonInfo(json: json);

          expect(
            fh.refDependents,
            {
              'ROOT': ['ROOT'],
            },
          );

          expect(
            fh.refDependencies,
            {
              'ROOT': ['ROOT'],
            },
          );

          expect(fh.childDependencies, <String, List<String>>{});
          expect(fh.childDependents, <String, List<String>>{});
          expect(
            fh.allDependencies,
            {
              'ROOT': ['ROOT'],
            },
          );
          expect(
            fh.allDependents,
            {
              'ROOT': ['ROOT'],
            },
          );
        });

        test('when the object is references by a child object', () {
          const json = {
            '_hash': 'ROOT',
            'child': {
              '_hash': 'CHILD',
              'ref': 'ROOT',
            },
          };

          final fh = JsonInfo(json: json);

          expect(fh.refDependents, {
            'ROOT': ['CHILD'],
          });

          expect(fh.refDependencies, {
            'CHILD': ['ROOT'],
          });

          expect(fh.childDependencies, {
            'ROOT': ['CHILD'],
          });

          expect(fh.childDependents, {
            'CHILD': ['ROOT'],
          });

          expect(
            fh.allDependencies,
            {
              'ROOT': ['CHILD'],
              'CHILD': ['ROOT'],
            },
          );

          expect(
            fh.allDependents,
            {
              'ROOT': ['CHILD'],
              'CHILD': ['ROOT'],
            },
          );
        });

        test('when the object is references by a sibling object', () {
          const json = {
            '_hash': 'ROOT',
            'child0': {
              '_hash': 'CHILD0',
              'ref': 'CHILD1',
            },
            'child1': {
              '_hash': 'CHILD1',
            },
          };

          final ji = JsonInfo(
            json: json,
          );

          expect(
            ji.refDependents,
            {
              'CHILD1': ['CHILD0'],
            },
          );

          expect(
            ji.refDependencies,
            {
              'CHILD0': ['CHILD1'],
            },
          );

          expect(
            ji.childDependencies,
            {
              'ROOT': ['CHILD0', 'CHILD1'],
            },
          );
          expect(
            ji.childDependents,
            {
              'CHILD0': ['ROOT'],
              'CHILD1': ['ROOT'],
            },
          );

          expect(ji.allDependents, {
            'CHILD0': ['ROOT'],
            'CHILD1': ['CHILD0', 'ROOT'],
          });

          expect(
            ji.allDependencies,
            {
              'ROOT': ['CHILD0', 'CHILD1'],
              'CHILD0': ['CHILD1'],
            },
          );
        });

        group('when the object is referenced within a list', () {
          test('within the object itself', () {
            const json = {
              '_hash': 'ROOT',
              'list': ['ROOT', 'a', 'b'],
            };

            final ji = JsonInfo(
              json: json,
            );

            expect(
              ji.refDependents,
              {
                'ROOT': ['ROOT'],
              },
            );

            expect(
              ji.refDependencies,
              {
                'ROOT': ['ROOT'],
              },
            );

            expect(
              ji.childDependencies,
              <String, dynamic>{},
            );

            expect(
              ji.childDependents,
              <String, dynamic>{},
            );
          });

          test('in a child object', () {
            const json = {
              '_hash': 'ROOT',
              'list': [
                {
                  '_hash': 'CHILD',
                  'ref': 'ROOT',
                },
              ],
            };

            final ji = JsonInfo(
              json: json,
            );

            expect(
              ji.refDependents,
              {
                'ROOT': ['CHILD'],
              },
            );

            expect(
              ji.refDependencies,
              {
                'CHILD': ['ROOT'],
              },
            );

            expect(
              ji.childDependents,
              {
                'CHILD': ['ROOT'],
              },
            );

            expect(
              ji.childDependencies,
              {
                'ROOT': ['CHILD'],
              },
            );

            expect(
              ji.childDependents,
              {
                'CHILD': ['ROOT'],
              },
            );

            expect(
              ji.childDependencies,
              {
                'ROOT': ['CHILD'],
              },
            );
          });

          test('in a list', () {
            const root = {
              '_hash': 'ROOT',
              'list': [
                [
                  {
                    '_hash': 'CHILD1',
                    'ref': 'ROOT',
                  },
                ],
              ],
            };

            final ji = JsonInfo(
              json: root,
            );

            expect(
              ji.refDependents,
              {
                'ROOT': ['CHILD1'],
              },
            );

            expect(
              ji.refDependencies,
              {
                'CHILD1': ['ROOT'],
              },
            );

            expect(
              ji.allDependents,
              {
                'CHILD1': ['ROOT'],
                'ROOT': ['CHILD1'],
              },
            );

            expect(
              ji.allDependencies,
              {
                'ROOT': ['CHILD1'],
                'CHILD1': ['ROOT'],
              },
            );
          });
        });

        group('when the object is referenced as path segment', () {
          for (final delimiter in JsonInfo.hashPathSeparators) {
            test('delimited by $delimiter', () {
              final json = {
                '_hash': 'ROOT',
                'objectA': {
                  '_hash': 'OBJECTA',
                  'objectB': {
                    '_hash': 'OBJECTB',
                    'objectC': {
                      '_hash': 'OBJECTC',
                      'key': 'objectCValue',
                    },
                  },
                },
                'refObject': {
                  'ref': ['OBJECTA', 'OBJECTB', 'OBJECTC'].join(delimiter),
                  '_hash': 'REFOBJECT',
                },
              };

              final ji = JsonInfo(json: json);

              expect(
                ji.refDependents,
                {
                  'OBJECTA': ['REFOBJECT'],
                  'OBJECTB': ['REFOBJECT'],
                  'OBJECTC': ['REFOBJECT'],
                },
              );

              expect(
                ji.refDependencies,
                {
                  'REFOBJECT': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
                },
              );

              expect(
                ji.childDependencies,
                {
                  'ROOT': ['OBJECTA', 'REFOBJECT'],
                  'OBJECTA': ['OBJECTB'],
                  'OBJECTB': ['OBJECTC'],
                },
              );
              expect(
                ji.childDependents,
                {
                  'OBJECTA': ['ROOT'],
                  'OBJECTB': ['OBJECTA'],
                  'OBJECTC': ['OBJECTB'],
                  'REFOBJECT': ['ROOT'],
                },
              );

              expect(
                ji.allDependencies,
                {
                  'ROOT': ['OBJECTA', 'REFOBJECT'],
                  'OBJECTA': ['OBJECTB'],
                  'OBJECTB': ['OBJECTC'],
                  'REFOBJECT': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
                },
              );
              expect(
                ji.allDependents,
                {
                  'OBJECTA': ['REFOBJECT', 'ROOT'],
                  'OBJECTB': ['REFOBJECT', 'OBJECTA'],
                  'OBJECTC': ['REFOBJECT', 'OBJECTB'],
                  'REFOBJECT': ['ROOT'],
                },
              );
            });
          }
        });

        test('when the object is referenced by a key', () {
          final json = {
            '_hash': 'ROOT',
            'objectA': {
              '_hash': 'OBJECTA',
              'objectB': {
                '_hash': 'OBJECTB',
                'objectC': {
                  '_hash': 'OBJECTC',
                  'key': 'objectCValue',
                },
              },
            },
            'refMap': {
              '_hash': 'REFMAP',
              'OBJECTA': 10,
              'OBJECTB': 20,
              'OBJECTC': 30,
            },
          };

          final ji = JsonInfo(json: json);

          expect(
            ji.refDependents,
            {
              'OBJECTA': ['REFMAP'],
              'OBJECTB': ['REFMAP'],
              'OBJECTC': ['REFMAP'],
            },
          );

          expect(
            ji.refDependencies,
            {
              'REFMAP': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
            },
          );

          expect(
            ji.childDependencies,
            {
              'ROOT': ['OBJECTA', 'REFMAP'],
              'OBJECTA': ['OBJECTB'],
              'OBJECTB': ['OBJECTC'],
            },
          );

          expect(
            ji.childDependents,
            {
              'OBJECTA': ['ROOT'],
              'OBJECTB': ['OBJECTA'],
              'OBJECTC': ['OBJECTB'],
              'REFMAP': ['ROOT'],
            },
          );

          expect(
            ji.allDependencies,
            {
              'ROOT': ['OBJECTA', 'REFMAP'],
              'OBJECTA': ['OBJECTB'],
              'OBJECTB': ['OBJECTC'],
              'REFMAP': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
            },
          );

          expect(
            ji.allDependents,
            {
              'OBJECTA': ['REFMAP', 'ROOT'],
              'OBJECTB': ['REFMAP', 'OBJECTA'],
              'OBJECTC': ['REFMAP', 'OBJECTB'],
              'REFMAP': ['ROOT'],
            },
          );
        });

        test('when the same hash occurs multiple times', () {
          const json = {
            '_hash': 'ROOT',
            'child0': {
              '_hash': 'HASH',
              'key': 'a',
            },
            'child1': {
              '_hash': 'HASH',
              'key': 'a',
            },
            'child3': {
              '_hash': 'CHILD3',
              'grandChild': {
                '_hash': 'GRANDCHILD',
                'child3': {
                  '_hash': 'HASH',
                  'key': 'a',
                },
              },
            },
          };

          final ji = JsonInfo(json: json);
          expect(
            ji.childDependents,
            {
              'HASH': ['ROOT', 'GRANDCHILD'],
              'CHILD3': ['ROOT'],
              'GRANDCHILD': ['CHILD3'],
            },
          );

          expect(
            ji.childDependencies,
            {
              'ROOT': ['HASH', 'CHILD3'],
              'CHILD3': ['GRANDCHILD'],
              'GRANDCHILD': ['HASH'],
            },
          );
        });
      });
    });

    group('circularDependencies', () {
      group('returns lists of hashes that form ciruclar dependencies', () {
        group('when a hash of an object', () {
          test('is used by the object itself', () {
            const json = {
              '_hash': 'ROOT',
              'ref': 'ROOT',
            };

            final ji = JsonInfo(json: json);

            expect(ji.circularDependencies, [
              ['ROOT', 'ROOT'],
            ]);
          });

          test('is used by a child object', () {
            const json = {
              '_hash': 'ROOT',
              'child': {
                '_hash': 'CHILD',
                'ref': 'ROOT',
              },
            };

            final ji = JsonInfo(json: json);

            expect(ji.circularDependencies, [
              ['ROOT', 'CHILD', 'ROOT'],
            ]);
          });

          test('is used by a grand child object', () {
            const json = {
              '_hash': 'ROOT',
              'child': {
                '_hash': 'CHILD',
                'grandChild': {
                  '_hash': 'GRANDCHILD',
                  'ref': 'ROOT',
                },
              },
            };

            final ji = JsonInfo(json: json);

            expect(ji.circularDependencies, [
              ['ROOT', 'CHILD', 'GRANDCHILD', 'ROOT'],
            ]);
          });

          test('is used by a sibling object which is used by a sibling etc.',
              () {
            const json = {
              '_hash': 'ROOT',
              'child0': {
                '_hash': 'CHILD0',
                'ref': 'CHILD1',
              },
              'child1': {
                '_hash': 'CHILD1',
                'ref': 'GRANDCHILD',
              },
              'child2': {
                '_hash': 'CHILD2',
                'grandChild': {
                  '_hash': 'GRANDCHILD',
                  'ref': 'CHILD0',
                },
              },
            };

            final ji = JsonInfo(json: json);

            expect(ji.circularDependencies, [
              ['CHILD0', 'CHILD1', 'GRANDCHILD', 'CHILD0'],
            ]);
          });
        });

        group('with multiple circular dependencies', () {
          test('case 0', () {
            const json = {
              '_hash': 'ROOT',
              'chain0': {
                'item0': {
                  '_hash': 'ITEM00',
                  'ref': 'ITEM01',
                },
                'item1': {
                  '_hash': 'ITEM01',
                  'ref': 'ITEM02',
                },
                'item2': {
                  '_hash': 'ITEM02',
                  'ref': 'ITEM00',
                },
              },
              'chain1': {
                'item0': {
                  '_hash': 'ITEM10',
                  'ref': 'ITEM11',
                },
                'item1': {
                  '_hash': 'ITEM11',
                  'ref': 'ITEM12',
                },
                'item2': {
                  '_hash': 'ITEM12',
                  'ref': 'ITEM10',
                },
              },
            };

            final ji = JsonInfo(json: json);

            expect(ji.circularDependencies, [
              ['ITEM00', 'ITEM01', 'ITEM02', 'ITEM00'],
              ['ITEM10', 'ITEM11', 'ITEM12', 'ITEM10'],
            ]);
          });
          test('case 1', () {
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
                'ref': 'CHILD0',
              },
              'child3': {
                '_hash': 'CHILD3',
                'ref': 'ROOT',
              },
            };

            final ji = JsonInfo(json: json);

            expect(ji.circularDependencies, [
              ['CHILD0', 'CHILD1', 'CHILD2', 'CHILD0'],
              ['ROOT', 'CHILD3', 'ROOT'],
            ]);
          });
        });
      });
    });

    group('throwOnAmbigousHashes', () {
      test('throws on circluar dependencies', () {
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
            'ref': 'CHILD0',
          },
          'child3': {
            '_hash': 'CHILD3',
            'ref': 'ROOT',
          },
        };

        final ji = JsonInfo(json: json);
        var message = '';
        try {
          ji.updateOrder;
        } catch (e) {
          message = e.toString();
        }
        expect(
          message,
          [
            'Exception: Cannot update hashes: Circular dependencies detected:',
            '  - CHILD0 -> CHILD1 -> CHILD2 -> CHILD0',
            '  - ROOT -> CHILD3 -> ROOT',
          ].join('\n'),
        );
      });
    });

    group('throwOnUnequalAmbigiousHashes', () {
      test('throws on ambigious hashes that point to different objects', () {
        const json = {
          '_hash': 'ROOT',
          'child0': {
            '_hash': 'HASH0',
            'key': 'a',
          },
          'child1': {
            '_hash': 'HASH0',
            'key': 'b',
          },
          'child2': {
            '_hash': 'HASH1',
            'key': 'x',
          },
          'child3': {
            '_hash': 'HASH1',
            'key': 'x',
          },
        };

        final ji = JsonInfo(json: json);
        var message = '';
        try {
          ji.throwOnUnequalAmbigiousHashes();
        } catch (e) {
          message = e.toString();
        }
        expect(
          message,
          [
            'Exception: Ambigious hashes detected:',
            '  - HASH0',
            '  - HASH1',
          ].join('\n'),
        );
      });

      test('throws not on ambigious hashes that point to equal objects', () {
        const json = {
          '_hash': 'ROOT',
          'child0': {
            '_hash': 'HASH0',
            'key': 'a',
          },
          'child1': {
            '_hash': 'HASH0',
            'key': 'a',
          },
          'child2': {
            '_hash': 'HASH1',
            'key': 'b',
          },
          'child3': {
            '_hash': 'HASH1',
            'key': 'b',
          },
        };

        final ji = JsonInfo(json: json);
        expect(() => ji.throwOnUnequalAmbigiousHashes(), returnsNormally);
      });
    });

    group('updateOrder', () {
      test('of an empty object', () {
        const json = {'_hash': 'ROOT'};
        final ji = JsonInfo(json: json);
        expect(ji.updateOrder, ['ROOT']);
      });

      test('of an object with one child object', () {
        const json = {
          '_hash': 'ROOT',
          'child': {'_hash': 'CHILD'},
        };
        final ji = JsonInfo(json: json);
        expect(ji.updateOrder, ['CHILD', 'ROOT']);
      });

      test('of an object with two children with two grand children', () {
        const json = {
          '_hash': 'ROOT',
          'child0': {
            '_hash': 'CHILD0',
            'grand0': {'_hash': 'GRAND0'},
          },
          'child1': {
            '_hash': 'CHILD1',
            'grand1': {'_hash': 'GRAND1'},
          },
        };
        final ji = JsonInfo(json: json);
        expect(
          ji.updateOrder,
          [
            'GRAND0',
            'CHILD0',
            'GRAND1',
            'CHILD1',
            'ROOT',
          ],
        );
      });

      test('of objects within lists', () {
        const json = {
          '_hash': 'ROOT',
          'list0': [
            {
              '_hash': 'LIST0',
              'child0': {'_hash': 'CHILD0'},
              'list1': [
                {
                  '_hash': 'LIST2',
                  'child2': {'_hash': 'CHILD2'},
                },
              ],
            },
          ],
        };

        final ji = JsonInfo(json: json);
        expect(
          ji.updateOrder,
          ['CHILD0', 'CHILD2', 'LIST2', 'LIST0', 'ROOT'],
        );
      });

      test('of objects with references to others', () {
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
            'key': 'value',
          },
        };

        final ji = JsonInfo(json: json);
        expect(
          ji.updateOrder,
          ['CHILD2', 'CHILD1', 'CHILD0', 'ROOT'],
        );
      });
    });
  });
}
