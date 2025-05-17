// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:crypto/crypto.dart';

// .............................................................................
/// Number config for hashing.
///
/// We need to make sure that the hashing of numbers is consistent
/// across different platforms. Especially rounding errors can lead to
/// different hashes although the numbers are considered equal. This
/// class provides a configuration for hashing numbers.
class NumberHashingConfig {
  /// Constructor
  const NumberHashingConfig({
    this.precision = 0.001,
    this.maxNum = 1000 * 1000 * 1000,
    this.minNum = -1000 * 1000 * 1000,
    this.throwOnRangeError = true,
  });

  /// Precision for hashing numbers.
  final double precision;

  /// Maximum number for hashing.
  final double maxNum;

  /// Minimum number for hashing.
  final double minNum;

  /// Throw an error if a number is out of range.
  final bool throwOnRangeError;

  /// Default configuration.
  static const NumberHashingConfig defaultConfig = NumberHashingConfig();

  /// Creates a copy of the current NumberHashingConfig
  /// with optional new values.
  NumberHashingConfig copyWith({
    double? precision,
    double? maxNum,
    double? minNum,
    bool? throwOnRangeError,
  }) {
    return NumberHashingConfig(
      precision: precision ?? this.precision,
      maxNum: maxNum ?? this.maxNum,
      minNum: minNum ?? this.minNum,
      throwOnRangeError: throwOnRangeError ?? this.throwOnRangeError,
    );
  }
}

// .............................................................................
/// When writing hashes into a given JSON object, we have various options.
class ApplyJsonHashConfig {
  /// Constructor
  const ApplyJsonHashConfig({
    this.inPlace = false,
    this.updateExistingHashes = true,
    this.throwIfOnWrongHashes = true,
  });

  /// Write the hashes in place.
  final bool inPlace;

  /// Update existing hashes.
  final bool updateExistingHashes;

  /// Throw an error if the hash is wrong.
  final bool throwIfOnWrongHashes;

  /// Default configuration.
  static const ApplyJsonHashConfig defaultConfig = ApplyJsonHashConfig();

  /// Creates a copy of the current ApplyJsonHashConfig
  /// with optional new values.
  ApplyJsonHashConfig copyWith({
    bool? inPlace,
    bool? updateExistingHashes,
    bool? throwIfOnWrongHashes,
  }) {
    return ApplyJsonHashConfig(
      inPlace: inPlace ?? this.inPlace,
      updateExistingHashes: updateExistingHashes ?? this.updateExistingHashes,
      throwIfOnWrongHashes: throwIfOnWrongHashes ?? this.throwIfOnWrongHashes,
    );
  }
}

// .............................................................................
/// Options for the JSON hash.
class HashConfig {
  /// Constructor
  const HashConfig({
    this.hashLength = 22,
    this.hashAlgorithm = 'SHA-256',
    this.numberConfig = NumberHashingConfig.defaultConfig,
  });

  /// Length of the hash.
  final int hashLength;

  /// Algorithm for hashing.
  final String hashAlgorithm;

  /// Configuration for hashing numbers.
  final NumberHashingConfig numberConfig;

  /// Default configuration.
  static const HashConfig defaultConfig = HashConfig();
}

// .............................................................................
/// Adds hashes to JSON object.
class JsonHash {
  /// Constructor
  const JsonHash({this.config = HashConfig.defaultConfig});

  /// Configuration for hashing.
  final HashConfig config;

  /// Default instance.
  static const JsonHash defaultInstance = JsonHash();

  // ...........................................................................
  /// Writes hashes into the JSON object.
  Map<String, dynamic> apply(
    Map<String, dynamic> json, {
    ApplyJsonHashConfig applyConfig = ApplyJsonHashConfig.defaultConfig,
  }) {
    final copy = applyConfig.inPlace ? json : _copyJson(json);
    _addHashesToObject(copy, applyConfig);

    if (applyConfig.throwIfOnWrongHashes) {
      validate(copy);
    }
    return copy;
  }

  // ...........................................................................
  /// Deeply copies the JSON object.
  static Map<String, dynamic> copyJson(Map<String, dynamic> json) {
    return _copyJson(json);
  }

  /// Returns true if two JSON objects are deeply equal.
  static bool areEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b, {
    bool ignoreHashes = false,
  }) {
    return _areEqual(a, b, ignoreHashes: ignoreHashes);
  }

  // ...........................................................................
  /// Writes hashes into the JSON object in place.
  Map<String, dynamic> applyInPlace(
    Map<String, dynamic> json, {
    bool updateExistingHashes = false,
    bool throwIfWrongHashes = true,
  }) {
    final applyConfig = ApplyJsonHashConfig(
      inPlace: true,
      updateExistingHashes: updateExistingHashes,
      throwIfOnWrongHashes: throwIfWrongHashes,
    );

    return apply(json, applyConfig: applyConfig);
  }

  // ...........................................................................
  /// Writes hashes into a JSON string.
  String applyToJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final applyConfig =
        ApplyJsonHashConfig.defaultConfig.copyWith(inPlace: true);
    final hashedJson = apply(json, applyConfig: applyConfig);
    return jsonEncode(hashedJson);
  }

  // ...........................................................................
  /// Calculates a SHA-256 hash of a string with base64 url.
  String calcHash(String input) {
    final bytes = sha256.convert(utf8.encode(input)).bytes;
    final base64 = base64Encode(bytes).substring(0, config.hashLength);

    // convert to url safe base64
    return base64.replaceAll('+', '-').replaceAll('/', '_').replaceAll('=', '');
  }

  // ...........................................................................
  /// Throws if hashes are not correct.
  void validate(Map<String, dynamic> json) {
    // Check the hash of the high level element
    final ac =
        ApplyJsonHashConfig.defaultConfig.copyWith(throwIfOnWrongHashes: false);
    final jsonWithCorrectHashes = apply(json, applyConfig: ac);
    _validate(json, jsonWithCorrectHashes, '');
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  /// For testing purposes only.
  static const testCopyJson = _copyJson;

  /// For testing purposes only.
  static const testIsBasicType = _isBasicType;

  /// For testing purposes only.
  String testJsonString(Map<String, dynamic> value) => _jsonString(value);

  /// For testing purposes only.
  dynamic testConvertBasicType(dynamic value) => _convertBasicType(value);

  // ...........................................................................
  /// Validates the hashes of the JSON object.
  void _validate(
    Map<String, dynamic> jsonIs,
    Map<String, dynamic> jsonShould,
    String path,
  ) {
    // Check the hashes of the parent element
    final expectedHash = jsonShould['_hash'];
    final actualHash = jsonIs['_hash'];

    if (actualHash == null) {
      final pathHint = path.isNotEmpty ? ' at $path' : '';
      throw Exception('Hash$pathHint is missing.');
    }

    if (expectedHash != actualHash) {
      final pathHint = path.isNotEmpty ? ' at $path' : '';
      throw Exception(
        'Hash$pathHint "$actualHash" is wrong. Should be "$expectedHash".',
      );
    }

    // Check the hashes of the child elements
    for (final key in jsonIs.keys) {
      if (key == '_hash') continue;
      final value = jsonIs[key];
      if (value is Map<String, dynamic>) {
        final childIs = value;
        final childShould = jsonShould[key] as Map<String, dynamic>;
        _validate(childIs, childShould, '$path/$key');
      } else if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] is Map<String, dynamic>) {
            final itemIs = value[i] as Map<String, dynamic>;
            final itemShould = jsonShould[key][i] as Map<String, dynamic>;
            _validate(itemIs, itemShould, '$path/$key/$i');
          }
        }
      }
    }
  }

  // ...........................................................................
  /// Recursively adds hashes to a nested object.
  void _addHashesToObject(
    Map<String, dynamic> obj,
    ApplyJsonHashConfig applyConfig,
  ) {
    final updateExisting = applyConfig.updateExistingHashes;
    final throwIfOnWrongHashes = applyConfig.throwIfOnWrongHashes;
    final existingHash = obj['_hash'] as String? ?? '';

    if (!updateExisting && existingHash.isNotEmpty == true) {
      return;
    }

    // Recursively process child elements
    for (final value in obj.values) {
      if (value is Map<String, dynamic>) {
        final existingHash = value['_hash'] as String?;
        if (existingHash?.isNotEmpty == true && !updateExisting) {
          continue;
        }

        _addHashesToObject(value, applyConfig);
      } else if (value is List) {
        _processList(value, applyConfig);
      }
    }

    // Build a new object to represent the current object for hashing
    final objToHash = <String, dynamic>{};

    for (final key in obj.keys) {
      if (key == '_hash') continue;

      final value = obj[key];
      if (value is Map<String, dynamic>) {
        objToHash[key] = value['_hash'];
      } else if (value is List) {
        objToHash[key] = _flattenList(value);
      } else if (_isBasicType(value)) {
        objToHash[key] = _convertBasicType(value);
      } else if (value == null) {
        objToHash[key] = null;
      }
      // coverage:ignore-start
      else {
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
      // coverage:ignore-end
    }

    final sortedMapJson = _jsonString(objToHash);

    // Compute the SHA-256 hash of the JSON string
    final hash = calcHash(sortedMapJson);

    // Throw if old and new hash do not match
    if (throwIfOnWrongHashes) {
      final oldHash = obj['_hash'] as String? ?? '';
      if (oldHash.isNotEmpty && oldHash != hash) {
        throw Exception(
          'Hash "$oldHash" does not match the newly calculated one "$hash". '
          'Please make sure that all systems are producing the same hashes.',
        );
      }
    }

    // Add the hash to the original object
    obj['_hash'] = hash;
  }

  // ...........................................................................
  /// Converts a basic type to a suitable representation.
  dynamic _convertBasicType(dynamic value) {
    if (value is String) {
      return value;
    }
    if (value is num) {
      _checkNumber(value);

      if (value.toInt() == value) {
        return value.toInt();
      }

      return value;
    } else if (value is bool) {
      return value;
    } else {
      throw Exception('Unsupported type: ${value.runtimeType}');
    }
  }

  // ...........................................................................
  /// Builds a representation of a list for hashing.
  List<dynamic> _flattenList(List<dynamic> list) {
    final flattenedList = <dynamic>[];

    for (final element in list) {
      if (element is Map<String, dynamic>) {
        flattenedList.add(element['_hash']);
      } else if (element is List) {
        flattenedList.add(_flattenList(element));
      } else if (_isBasicType(element)) {
        flattenedList.add(_convertBasicType(element));
      } else if (element == null) {
        flattenedList.add(null);
      }
      // coverage:ignore-start
      else {
        throw Exception('Unsupported type: ${element.runtimeType}');
      }
      // coverage:ignore-end
    }

    return flattenedList;
  }

  // ...........................................................................
  /// Recursively processes a list, adding hashes to nested objects and lists.
  void _processList(List<dynamic> list, ApplyJsonHashConfig applyConfig) {
    for (final element in list) {
      if (element is Map<String, dynamic>) {
        _addHashesToObject(element, applyConfig);
      } else if (element is List) {
        _processList(element, applyConfig);
      }
    }
  }

  // ...........................................................................
  /// Returns true if two JSON objects are deeply equal
  static bool _areEqual(
    Map<String, dynamic> a,
    Map<String, dynamic> b, {
    bool ignoreHashes = false,
  }) {
    if (a.length != b.length) {
      return false;
    }

    for (final key in a.keys) {
      if (ignoreHashes && key == '_hash') {
        continue;
      }

      final valueA = a[key];
      final valueB = b[key];

      if (valueA is Map<String, dynamic> && valueB is Map<String, dynamic>) {
        if (!_areEqual(valueA, valueB)) {
          return false;
        }
      } else if (valueA is List && valueB is List) {
        if (!_areEqualList(valueA, valueB)) {
          return false;
        }
      } else if (valueA != valueB) {
        return false;
      }
    }

    return true;
  }

  static bool _areEqualList(
    List<dynamic> a,
    List<dynamic> b,
  ) {
    if (a.length != b.length) {
      return false;
    }

    for (int i = 0; i < a.length; i++) {
      final valueA = a[i];
      final valueB = b[i];

      if (valueA is Map<String, dynamic> && valueB is Map<String, dynamic>) {
        if (!_areEqual(valueA, valueB)) {
          return false;
        }
      } else if (valueA is List && valueB is List) {
        if (!_areEqualList(valueA, valueB)) {
          return false;
        }
      } else if (valueA != valueB) {
        return false;
      }
    }

    return true;
  }

  // ...........................................................................
  /// Copies the JSON object.
  static Map<String, dynamic> _copyJson(Map<String, dynamic> json) {
    final copy = <String, dynamic>{};
    for (final key in json.keys) {
      final value = json[key];
      if (value is List) {
        copy[key] = _copyList(value);
      } else if (_isBasicType(value)) {
        copy[key] = value;
      } else if (value is Map<String, dynamic>) {
        copy[key] = _copyJson(value);
      } else if (value == null) {
        copy[key] = null;
      } else {
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
    }
    return copy;
  }

  // ...........................................................................
  /// Copies the list.
  static List<dynamic> _copyList(List<dynamic> list) {
    final copy = <dynamic>[];
    for (final element in list) {
      if (element is List) {
        copy.add(_copyList(element));
      } else if (_isBasicType(element)) {
        copy.add(element);
      } else if (element is Map<String, dynamic>) {
        copy.add(_copyJson(element));
      } else if (element == null) {
        copy.add(null);
      } else {
        throw Exception('Unsupported type: ${element.runtimeType}');
      }
    }
    return copy;
  }

  // ...........................................................................
  /// Checks if a value is a basic type.
  static bool _isBasicType(dynamic value) {
    return value is String || value is num || value is bool;
  }

  // ...........................................................................
  /// Turns a number into a string with a given precision.
  void _checkNumber(num value) {
    if (value.isNaN) {
      throw Exception('NaN is not supported.');
    }

    if (value is int) {
      return;
    }

    if (_exceedsPrecision(value)) {
      throw Exception('Number $value has a higher precision than 0.001.');
    }

    if (_exceedsUpperRange(value)) {
      throw Exception('Number $value exceeds NumberHashingConfig.maxNum.');
    }

    if (_exceedsLowerRange(value)) {
      throw Exception('Number $value is smaller NumberHashingConfig.minNum.');
    }
  }

  // ...........................................................................
  /// Checks if a number exceeds the defined range.
  bool _exceedsUpperRange(num value) {
    return value > config.numberConfig.maxNum;
  }

  // ...........................................................................
  /// Checks if a number exceeds the defined range.
  bool _exceedsLowerRange(num value) {
    return value < config.numberConfig.minNum;
  }

  // ...........................................................................
  /// Checks if a number exceeds the precision.
  bool _exceedsPrecision(num value) {
    final precision = config.numberConfig.precision;
    final roundedValue = (value / precision).round() * precision;
    const epsilon = 2.220446049250313e-16;
    return (value - roundedValue).abs() > epsilon;
  }

  // ...........................................................................
  /// Converts a map to a JSON string.
  String _jsonString(Map<String, dynamic> map) {
    // Sort the object keys to ensure consistent key order
    final sortedKeys = map.keys.toList()..sort();

    String encodeValue(dynamic value) {
      if (value is String) {
        return '"${value.replaceAll('"', '\\"')}"'; // Escape quotes
      } else if (value is bool) {
        return value.toString();
      } else if (value is num) {
        return _convertBasicType(value).toString();
      } else if (value is List) {
        return '[${value.map(encodeValue).join(',')}]';
      } else if (value is Map<String, dynamic>) {
        return _jsonString(value);
      } else if (value == null) {
        return 'null';
      } else {
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
    }

    var result = <String>[];
    result.add('{');
    for (var i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      bool isLast = i == sortedKeys.length - 1;
      result.add('"$key":'
          '${encodeValue(map[key])}');
      if (!isLast) result.add(',');
    }
    result.add('}');

    return result.join('');
  }
}

/// Shorthand for applying hashes in place
final hip = JsonHash.defaultInstance.applyInPlace;

/// Shorthand for applying hashes
final hsh = JsonHash.defaultInstance.apply;
