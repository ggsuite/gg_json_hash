// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/src/float_to_string.dart';
import 'package:test/test.dart';

void main() {
  group('floatToString (current behavior with "p<digits>" suffix)', () {
    // ---- Integers: returned as-is (no suffix) ----
    test('returns integers as plain strings', () {
      expect(floatToString(0), '0');
      expect(floatToString(-0), '0'); // (-0).toString() === "0"
      expect(floatToString(7), '7');
      expect(floatToString(-42), '-42');
      expect(floatToString(100000000), '100000000');
    });

    // ---- |x| < 10 -> digits=8, factor=1e8 ----
    test('appends "p8" for non-integers with |x| < 10', () {
      expect(floatToString(0.123456789), '12345679p8');
      expect(floatToString(9.5), '950000000p8');
      expect(floatToString(9.999999995), '1000000000p8');
      expect(floatToString(-0.000000016), '-2p8');
    });

    // ---- 10 ≤ |x| < 100 -> digits=7, factor=1e7 ----
    test('appends "p7" for non-integers with 10 ≤ |x| < 100', () {
      expect(floatToString(12.3456789), '123456789p7');
      expect(floatToString(99.99999995), '1000000000p7');
      expect(floatToString(-12.34), '-123400000p7');
    });

    // ---- 100 ≤ |x| < 1000 -> digits=6, factor=1e6 ----
    test('appends "p6" for non-integers with 100 ≤ |x| < 1000', () {
      expect(floatToString(123.456789), '123456789p6');
      expect(floatToString(-100.000001), '-100000001p6');
    });

    // ---- 1000 ≤ |x| < 10000 -> digits=5, factor=1e5 ----
    test('appends "p5" for non-integers with 1000 ≤ |x| < 10000', () {
      expect(floatToString(1234.56789), '123456789p5');
      expect(floatToString(-9999.1), '-999910000p5');
    });

    // ---- 10000 ≤ |x| < 100000 -> digits=4, factor=1e4 ----
    test('appends "p4" for non-integers with 10000 ≤ |x| < 100000', () {
      expect(floatToString(12345.6789), '123456789p4');
      expect(floatToString(-10000.01), '-100000100p4');
    });

    // ---- 100000 ≤ |x| < 1000000 -> digits=3, factor=1e3 ----
    test('appends "p3" for non-integers with 100000 ≤ |x| < 1000000', () {
      expect(floatToString(123456.789), '123456789p3');
      expect(floatToString(-999999.40001), '-999999400p3');
    });

    // ---- 1e6 ≤ |x| < 1e7 -> digits=2, factor=1e2 ----
    test('appends "p2" for non-integers with 1e6 ≤ |x| < 1e7', () {
      expect(floatToString(1234567.89), '123456789p2');
      expect(floatToString(-1000000.01), '-100000001p2');
    });

    // ---- 1e7 ≤ |x| < 1e8 -> digits=2, factor=1e2 ----
    test('appends "p1" for non-integers with 1e7 ≤ |x| < 1e8', () {
      expect(floatToString(12345678.9), '1234567890p2');
      expect(floatToString(-99999999.4), '-9999999940p2');
    });

    // ---- ≥ 1e8 -> digits=2, factor=2 ----
    test('appends "p0" for non-integers with |x| ≥ 1e8', () {
      expect(floatToString(123456789.44), '12345678944p2');
      expect(floatToString(123456789.65), '12345678965p2');
      expect(floatToString(-100000000.49), '-10000000049p2');
      expect(floatToString(-100000000.5), '-10000000050p2');
    });

    group('throws when json hash', () {
      test('exceeds max value', () {
        var message = <String>[];
        try {
          floatToString(maxFloat + 0.1);
        } catch (e) {
          message = (e as dynamic).message.toString().trim().split('\n');
        }

        expect(message, [
          'Float value 90071992547409.1 must be between '
              '-90071992547409 and 90071992547409.',
        ]);
      });

      test('exceeeds min value', () {
        var message = <String>[];
        try {
          floatToString(minFloat - 0.1);
        } catch (e) {
          message = (e as dynamic).message.toString().trim().split('\n');
        }

        expect(message, [
          'Float value -90071992547409.1 must be between '
              '-90071992547409 and 90071992547409.',
        ]);
      });
    });

    // ---- Boundary checks around thresholds ----
    test('uses the correct bucket right above thresholds (non-integers)', () {
      expect(floatToString(10.00000001), '100000000p7');
      expect(floatToString(100.0000001), '100000000p6');
      expect(floatToString(1000.000001), '100000000p5');
      expect(floatToString(10000.00001), '100000000p4');
      expect(floatToString(100000.0001), '100000000p3');
      expect(floatToString(1000000.001), '100000000p2');
      expect(floatToString(10000000.01), '1000000001p2');
      expect(floatToString(100000000.1), '10000000010p2');
    });

    test('treats exact thresholds that are integers as integers', () {
      expect(floatToString(10), '10');
      expect(floatToString(100), '100');
      expect(floatToString(1000), '1000');
      expect(floatToString(10000), '10000');
      expect(floatToString(100000), '100000');
      expect(floatToString(1000000), '1000000');
      expect(floatToString(10000000), '10000000');
      expect(floatToString(100000000), '100000000');
    });
  });
}
