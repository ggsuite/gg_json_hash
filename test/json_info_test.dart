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
      test('returns the original object with added hashes', () {
        const json = {
          'child': {
            'key': 'value',
          },
        };

        final fixHashes = JsonInfo(json: json);

        expect(
          fixHashes.json,
          {
            'child': {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
            '_hash': '3Wizz29YgTIc1LRaN9fNfK',
          },
        );
      });
      test('returns the json to be fixed', () {
        init();
        expect(fixHashes1.json, json1);
        expect(fixHashes2.json, json2);
      });
    });

    group('allObjects, allHashes', () {
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

          expect(fixHashes1.allHashes, [
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

          expect(fixHashes.allHashes, [
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

          expect(fixHashes.allHashes, [
            'ROOT',
            'CHILD0',
            'CHILD1',
          ]);
        });

        test('for an object with missing _hashes', () {
          const json = {
            'child': {
              'grandChild0': {'_hash': 'HASH0'},
              'grandChild2': {'key': 'value'},
            },
          };

          final fixHashes = JsonInfo(
            json: json,
          );
          final oh = fixHashes.allObjects.map((e) => e['_hash']).toList();
          expect(
            oh,
            [
              'UWPFyflDOcMsNU9Bn4f1LG',
              'Gd576RRXUydlpqqaOWJ2HS',
              'HASH0',
              '5Dq88zdSRIOcAS-WM_lYYt',
            ],
          );

          expect(fixHashes.allHashes, [
            'UWPFyflDOcMsNU9Bn4f1LG',
            'Gd576RRXUydlpqqaOWJ2HS',
            'HASH0',
            '5Dq88zdSRIOcAS-WM_lYYt',
          ]);
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
          expect(fixHashes0.refDependents, <String, List<String>>{});
          expect(fixHashes0.refDependencies, <String, List<String>>{});
          expect(fixHashes1.refDependents, <String, dynamic>{});
          expect(fixHashes1.refDependencies, <String, dynamic>{});
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

          final fixHashes = JsonInfo(
            json: json,
          );

          expect(
            fixHashes.refDependents,
            {
              'CHILD1': ['CHILD0'],
            },
          );

          expect(
            fixHashes.refDependencies,
            {
              'CHILD0': ['CHILD1'],
            },
          );

          expect(
            fixHashes.childDependencies,
            {
              'ROOT': ['CHILD0', 'CHILD1'],
            },
          );
          expect(
            fixHashes.childDependents,
            {
              'CHILD0': ['ROOT'],
              'CHILD1': ['ROOT'],
            },
          );

          expect(fixHashes.allDependents, {
            'CHILD0': ['ROOT'],
            'CHILD1': ['CHILD0', 'ROOT'],
          });

          expect(
            fixHashes.allDependencies,
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

            final fixHashes = JsonInfo(
              json: json,
            );

            expect(
              fixHashes.refDependents,
              {
                'ROOT': ['ROOT'],
              },
            );

            expect(
              fixHashes.refDependencies,
              {
                'ROOT': ['ROOT'],
              },
            );

            expect(
              fixHashes.childDependencies,
              <String, dynamic>{},
            );

            expect(
              fixHashes.childDependents,
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

            final fixHashes = JsonInfo(
              json: json,
            );

            expect(
              fixHashes.refDependents,
              {
                'ROOT': ['CHILD'],
              },
            );

            expect(
              fixHashes.refDependencies,
              {
                'CHILD': ['ROOT'],
              },
            );

            expect(
              fixHashes.childDependents,
              {
                'CHILD': ['ROOT'],
              },
            );

            expect(
              fixHashes.childDependencies,
              {
                'ROOT': ['CHILD'],
              },
            );

            expect(
              fixHashes.childDependents,
              {
                'CHILD': ['ROOT'],
              },
            );

            expect(
              fixHashes.childDependencies,
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

            final fixHashes = JsonInfo(
              json: root,
            );

            expect(
              fixHashes.refDependents,
              {
                'ROOT': ['CHILD1'],
              },
            );

            expect(
              fixHashes.refDependencies,
              {
                'CHILD1': ['ROOT'],
              },
            );

            expect(
              fixHashes.allDependents,
              {
                'CHILD1': ['ROOT'],
                'ROOT': ['CHILD1'],
              },
            );

            expect(
              fixHashes.allDependencies,
              {
                'ROOT': ['CHILD1'],
                'CHILD1': ['ROOT'],
              },
            );
          });
        });

        group('when the object is referenced as path segment', () {
          for (final delimiter in [
            '/',
            '.',
            '|',
            '[',
            ']',
            '\\',
            '%',
            '(',
            ')',
            '.',
            ' ',
          ]) {
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

              final fixHashes = JsonInfo(json: json);

              expect(
                fixHashes.refDependents,
                {
                  'OBJECTA': ['REFOBJECT'],
                  'OBJECTB': ['REFOBJECT'],
                  'OBJECTC': ['REFOBJECT'],
                },
              );

              expect(
                fixHashes.refDependencies,
                {
                  'REFOBJECT': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
                },
              );

              expect(
                fixHashes.childDependencies,
                {
                  'ROOT': ['OBJECTA', 'REFOBJECT'],
                  'OBJECTA': ['OBJECTB'],
                  'OBJECTB': ['OBJECTC'],
                },
              );
              expect(
                fixHashes.childDependents,
                {
                  'OBJECTA': ['ROOT'],
                  'OBJECTB': ['OBJECTA'],
                  'OBJECTC': ['OBJECTB'],
                  'REFOBJECT': ['ROOT'],
                },
              );

              expect(
                fixHashes.allDependencies,
                {
                  'ROOT': ['OBJECTA', 'REFOBJECT'],
                  'OBJECTA': ['OBJECTB'],
                  'OBJECTB': ['OBJECTC'],
                  'REFOBJECT': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
                },
              );
              expect(
                fixHashes.allDependents,
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

          final fixHashes = JsonInfo(json: json);

          expect(
            fixHashes.refDependents,
            {
              'OBJECTA': ['REFMAP'],
              'OBJECTB': ['REFMAP'],
              'OBJECTC': ['REFMAP'],
            },
          );

          expect(
            fixHashes.refDependencies,
            {
              'REFMAP': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
            },
          );

          expect(
            fixHashes.childDependencies,
            {
              'ROOT': ['OBJECTA', 'REFMAP'],
              'OBJECTA': ['OBJECTB'],
              'OBJECTB': ['OBJECTC'],
            },
          );

          expect(
            fixHashes.childDependents,
            {
              'OBJECTA': ['ROOT'],
              'OBJECTB': ['OBJECTA'],
              'OBJECTC': ['OBJECTB'],
              'REFMAP': ['ROOT'],
            },
          );

          expect(
            fixHashes.allDependencies,
            {
              'ROOT': ['OBJECTA', 'REFMAP'],
              'OBJECTA': ['OBJECTB'],
              'OBJECTB': ['OBJECTC'],
              'REFMAP': ['OBJECTA', 'OBJECTB', 'OBJECTC'],
            },
          );

          expect(
            fixHashes.allDependents,
            {
              'OBJECTA': ['REFMAP', 'ROOT'],
              'OBJECTB': ['REFMAP', 'OBJECTA'],
              'OBJECTC': ['REFMAP', 'OBJECTB'],
              'REFMAP': ['ROOT'],
            },
          );
        });
      });
    });
  });
}
