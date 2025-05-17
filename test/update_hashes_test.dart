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
      });
    });
  });
}
