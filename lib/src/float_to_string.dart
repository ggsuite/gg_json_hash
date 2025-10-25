// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// @license
// Copyright (c) 2025 Rljson
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

/// The minimum precision for very large numbers
const precision = 100;

/// The maximum supported floating value
const maxFloat =
    (9007199254740991 ~/ precision); // Number.MAX_SAFE_INTEGER in JS

/// The minimum supported floating value
const minFloat =
    (-9007199254740991 ~/ precision); // Number.MIN_SAFE_INTEGER in JS

/// Converts a floating-point number to a string representation,
/// depending on the magnitude of the input value. The function rounds
/// the value to a precision that decreases as the absolute value increases,
/// ensuring a compact and robust string output.
///
/// Returns the string representation of the number.
String floatToString(num value) {
  if (value is int || value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  int digits = 2;
  num factor = precision;

  if (value > maxFloat || value < minFloat) {
    throw Exception(
      'Float value $value must be between $minFloat and $maxFloat.',
    );
  }

  final absVal = value.abs();

  // Define thresholds and corresponding digits/factors
  final thresholds = [
    {'limit': 10, 'digits': 8, 'factor': 1e8},
    {'limit': 100, 'digits': 7, 'factor': 1e7},
    {'limit': 1000, 'digits': 6, 'factor': 1e6},
    {'limit': 10000, 'digits': 5, 'factor': 1e5},
    {'limit': 100000, 'digits': 4, 'factor': 1e4},
    {'limit': 1000000, 'digits': 3, 'factor': 1e3},
    {'limit': 10000000, 'digits': 2, 'factor': 1e2},
  ];

  for (final t in thresholds) {
    if (absVal < (t['limit'] as num)) {
      digits = t['digits'] as int;
      factor = t['factor'] as num;
      break;
    }
  }

  final rounded = (absVal * factor).round();
  final sign = value < 0 ? '-' : '';
  final result =
      '$sign$rounded'
      'p$digits';

  return result;
}
