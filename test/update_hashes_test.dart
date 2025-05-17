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

      group('updates hashes and references in an object', () {
        test('that is empty', () {
          const json = {
            '_hash': 'ROOT',
          };

          final updateHashes = UpdateHashes(json: json);
          updateHashes.apply();

          final uj = updateHashes.updatedJson;

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

        test('with multiple identical child objects', () {
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
            '_hash': '_28DJCUI3zppsTIy8QjLUS',
            'array': [
              {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
              {'key': 'value', '_hash': '5Dq88zdSRIOcAS-WM_lYYt'},
            ],
          });
        });
      });
    });
  });
}
