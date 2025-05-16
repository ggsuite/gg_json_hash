// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';
import 'package:test/test.dart';

void main() {
  group('FixHashes', () {
    bool isInitialized = false;
    late final JsonInfo fixHashes0;
    late final JsonInfo fixHashes1;
    late final JsonInfo fixHashes2;

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
        fixHashes0 = JsonInfo(json: json0);
        fixHashes1 = JsonInfo(json: json1);
        fixHashes2 = JsonInfo(json: json2);
        isInitialized = true;
      }
    }

    group('json', () {
      test('returns the json to be fixed', () {
        init();
        expect(fixHashes1.json, json1);
        expect(fixHashes2.json, json2);
      });
    });

    group('fixedJson', () {
      group('returns the fixed json', () {
        test('when the json is empty', () {
          init();
          final json0 = <String, dynamic>{};
          final emptyFixHashes = JsonInfo(json: json0);
          expect(emptyFixHashes.fixedJson, json0);
        });

        test('when the json is not empty', () {
          init();
          expect(fixHashes1.fixedJson, json1);
        });
      });

      group('hashToObjects', () {
        test('returns the hash to objects', () {
          init();
          final h2o = fixHashes1.hashToObjects;

          expect(
            h2o.keys.toList(),
            [
              'ROOT',
              'PARENT',
              'CHILD0',
              'CHILD1',
              'LIST0',
              'CHILD3',
              'LIST1',
              'CHILD4',
            ],
          );
        });
      });

      group('allObjects', () {
        group('returns a list of all objects', () {
          test('for a deeply nested object', () {
            init();
            final oh = fixHashes1.allObjects.map((e) => e['_hash']).toList();
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

            final fixHashes = JsonInfo(
              json: json,
            );

            final oh = fixHashes.allObjects.map((e) => e['_hash']).toList();
            expect(
              oh,
              [
                'ROOT',
                'CHILD0',
                'CHILD1',
              ],
            );
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

            final fixHashes = JsonInfo(
              json: json,
            );

            final oh = fixHashes.allObjects.map((e) => e['_hash']).toList();
            expect(
              oh,
              [
                'ROOT',
                'CHILD0',
                'CHILD1',
              ],
            );
          });
        });
      });

      group('isReferencedBy', () {
        group('returns a list of objects that reference to a given hash', () {
          test('when the json contains no references', () {
            init();
            expect(fixHashes0.isReferencedBy, <String, List<String>>{});
            expect(fixHashes1.isReferencedBy, <String, List<String>>{});
          });
          test('when the object references itself', () {
            const json = {
              '_hash': 'ROOT',
              'ref': 'ROOT',
            };

            final fixHashes = JsonInfo(
              json: json,
            );

            expect(
              fixHashes.isReferencedBy,
              {
                'ROOT': [json],
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

            final fixHashes = JsonInfo(
              json: json,
            );

            expect(
              fixHashes.isReferencedBy,
              {
                'ROOT': [json['child']],
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

            final fixHashes = JsonInfo(
              json: json,
            );

            expect(
              fixHashes.isReferencedBy,
              {
                'CHILD1': [json['child0']],
              },
            );
          });

          group('when the object is referenced within a list', () {
            test('within the object itself', () {
              const json = {
                '_hash': 'ROOT',
                'list': ['ROOT', 'a', 'b'],
              };

              final fixHashes = JsonInfo(
                json: json,
              );

              expect(
                fixHashes.isReferencedBy,
                {
                  'ROOT': [json],
                },
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

              final fixHashes = JsonInfo(
                json: json,
              );

              expect(
                fixHashes.isReferencedBy,
                {
                  'ROOT': [(json['list']! as List)[0]],
                },
              );
            });

            test('in a list', () {
              const childListItem = {
                '_hash': 'CHILD1',
                'ref': 'ROOT',
              };

              const childList = [
                childListItem,
              ];

              const list = [
                childList,
              ];

              const root = {
                '_hash': 'ROOT',
                'list': list,
              };

              final fixHashes = JsonInfo(
                json: root,
              );

              expect(
                fixHashes.isReferencedBy,
                {
                  'ROOT': [childListItem],
                },
              );
            });
          });
        });
      });
    });
  });
}
