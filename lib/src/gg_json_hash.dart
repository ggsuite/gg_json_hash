// @license
// Copyright (c) ggsuite
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:gg_json_hash/src/float_to_string.dart';

// .............................................................................
/// Options for the JSON hash.
class HashConfig {
  /// Constructor
  const HashConfig({
    this.hashLength = 22,
    this.hashAlgorithm = 'SHA-256',
    this.floatToStr = floatToString,
  });

  /// Length of the hash.
  final int hashLength;

  /// Algorithm for hashing.
  final String hashAlgorithm;

  /// This method is used to convert a float to a string for hash calculation
  final String Function(num float) floatToStr;

  /// Default configuration.
  static const HashConfig defaultConfig = HashConfig();

  /// Returns a copy of this config with the given fields replaced.
  HashConfig copyWith({
    int? hashLength,
    String? hashAlgorithm,
    String Function(num float)? floatToStr,
  }) {
    return HashConfig(
      hashLength: hashLength ?? this.hashLength,
      hashAlgorithm: hashAlgorithm ?? this.hashAlgorithm,
      floatToStr: floatToStr ?? this.floatToStr,
    );
  }
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
    bool inPlace = false,
    bool updateExistingHashes = true,
    bool throwOnWrongHashes = true,
  }) {
    final copy = inPlace ? json : _copyJson(json, false);
    _addHashesToObject(
      copy,
      updateExistingHashes: updateExistingHashes,
      throwOnWrongHashes: throwOnWrongHashes,
    );

    // When updateExistingHashes is true, _addHashesToObject has just
    // recalculated the hash of every object in the tree and compared it
    // against any pre-existing hash (throwing on mismatch). Running
    // validate() again would recompute the identical hashes a second time
    // and can never fail. It is only needed when existing hashes were
    // skipped, i.e. updateExistingHashes is false.
    if (throwOnWrongHashes && !updateExistingHashes) {
      validate(copy);
    }
    return copy;
  }

  // ...........................................................................
  /// Returns a copy of this instance with the given fields replaced.
  JsonHash copyWith({HashConfig? config}) {
    return JsonHash(config: config ?? this.config);
  }

  // ...........................................................................
  /// Deeply copies the JSON object.
  static Map<String, dynamic> copyJson(
    Map<String, dynamic> json, {
    bool ignoreHashes = false,
  }) {
    return _copyJson(json, ignoreHashes);
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
    bool throwOnWrongHashes = true,
  }) {
    return apply(
      json,
      updateExistingHashes: updateExistingHashes,
      throwOnWrongHashes: throwOnWrongHashes,
      inPlace: true,
    );
  }

  // ...........................................................................
  /// Writes hashes into a JSON string.
  String applyToJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final hashedJson = apply(json, inPlace: true);
    return jsonEncode(hashedJson);
  }

  // ...........................................................................
  /// Inserts hashes, when _hash is null, empty or placeholder
  Map<String, dynamic> addMissingHashes(
    Map<String, dynamic> json, {
    bool throwOnWrongHashes = false,
    bool updateExistingHashes = false,
  }) {
    var hash = json['_hash'] as String?;
    if (hash?.isNotEmpty != true) {
      return hsh(
        json,
        throwOnWrongHashes: throwOnWrongHashes,
        updateExistingHashes: updateExistingHashes,
      );
    }

    return json;
  }

  // ...........................................................................
  /// Returns a copy without hashes
  Map<String, dynamic> removeHashes(Map<String, dynamic> json) {
    final result = copyJson(json, ignoreHashes: true);

    return result;
  }

  // ...........................................................................
  /// Single-pass fast path for update operations:
  ///
  /// Deep-copies [json], fills in missing or empty `_hash` attributes
  /// bottom up and verifies existing ones against the hash calculated from
  /// the content. Returns `null` when an existing `_hash` does not match
  /// the calculated one, i.e. the json needs a real hash update.
  ///
  /// When a non-null result is returned it is identical to the result of
  /// running the full `updateHashes` machinery on [json].
  Map<String, dynamic>? copyWithVerifiedHashes(Map<String, dynamic> json) {
    try {
      return _copyFillVerify(json);
    } on _StaleHashException {
      return null;
    }
  }

  // ...........................................................................
  /// Calculates a SHA-256 hash of a string with base64 url.
  String calcHash(String input) {
    final bytes = sha256.convert(utf8.encode(input)).bytes;

    // base64Url replaces '+' by '-' and '/' by '_' at encoding time, which
    // yields exactly the same string as encoding with base64 and replacing
    // the characters afterwards. Only padding '=' needs to be stripped.
    final base64 = base64UrlEncode(bytes).substring(0, config.hashLength);
    return base64.replaceAll('=', '');
  }

  // ...........................................................................
  /// Throws if hashes are not correct.
  void validate(Map<String, dynamic> json) {
    // Check the hash of the high level element
    final jsonWithCorrectHashes = apply(json, throwOnWrongHashes: false);
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
    Map<String, dynamic> obj, {
    bool updateExistingHashes = true,
    bool throwOnWrongHashes = true,
  }) {
    final updateExisting = updateExistingHashes;
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

        _addHashesToObject(
          value,
          updateExistingHashes: updateExistingHashes,
          throwOnWrongHashes: throwOnWrongHashes,
        );
      } else if (value is List) {
        _processList(
          value,
          updateExistingHashes: updateExistingHashes,
          throwOnWrongHashes: throwOnWrongHashes,
        );
      }
    }

    // Build the canonical string representing the current object.
    // This produces exactly the same string as building an intermediate
    // "objToHash" map (child objects replaced by their hash, lists
    // flattened) and serializing it with _jsonString, but in a single pass
    // without intermediate allocations.
    final sortedMapJson = _hashPayload(obj);

    // Compute the SHA-256 hash of the JSON string
    final hash = calcHash(sortedMapJson);

    // Throw if old and new hash do not match
    if (throwOnWrongHashes) {
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

    if (value is double) {
      if (value.isNaN) {
        throw Exception('NaN is not supported.');
      }
      return value;
    }
    // Handle int values
    else if (value is int) {
      return value;
    }
    // Handle non double and non int numbers
    else if (value is num) {
      // coverage:ignore-start
      throw UnimplementedError(
        'Number is not double and not int. Please implement this case.',
      );
      // coverage:ignore-end
    } else if (value is bool) {
      return value;
    } else {
      throw Exception('Unsupported type: ${value.runtimeType}');
    }
  }

  // ...........................................................................
  /// Builds the canonical string that is hashed for [obj].
  ///
  /// The `_hash` key is skipped, keys are sorted, child objects are
  /// represented by their `_hash` value and floats are converted using
  /// [HashConfig.floatToStr]. The result is identical to serializing the
  /// flattened "objToHash" representation with [_jsonString].
  String _hashPayload(Map<String, dynamic> obj) {
    final keys = <String>[];
    for (final key in obj.keys) {
      if (key != '_hash') {
        keys.add(key);
      }
    }
    keys.sort();

    final sb = StringBuffer('{');
    for (var i = 0; i < keys.length; i++) {
      if (i > 0) {
        sb.write(',');
      }
      final key = keys[i];
      sb.write('"');
      sb.write(key);
      sb.write('":');
      _writePayloadValue(obj[key], sb);
    }
    sb.write('}');
    return sb.toString();
  }

  // ...........................................................................
  /// Writes the canonical hash representation of [value] into [sb].
  void _writePayloadValue(dynamic value, StringBuffer sb) {
    if (value is String) {
      sb.write('"');
      sb.write(value.replaceAll('"', '\\"'));
      sb.write('"');
    } else if (value is Map<String, dynamic>) {
      // Child objects are represented by their hash
      _writePayloadValue(value['_hash'], sb);
    } else if (value is List) {
      sb.write('[');
      for (var i = 0; i < value.length; i++) {
        if (i > 0) {
          sb.write(',');
        }
        _writePayloadValue(value[i], sb);
      }
      sb.write(']');
    } else if (value is bool) {
      sb.write(value ? 'true' : 'false');
    } else if (value is num) {
      if (value is double && value.isNaN) {
        throw Exception('NaN is not supported.');
      }
      sb.write(config.floatToStr(value));
    } else if (value == null) {
      sb.write('null');
    } else {
      throw Exception('Unsupported type: ${value.runtimeType}');
    }
  }

  // ...........................................................................
  /// Recursively processes a list, adding hashes to nested objects and lists.
  void _processList(
    List<dynamic> list, {
    required bool updateExistingHashes,
    required bool throwOnWrongHashes,
  }) {
    for (final element in list) {
      if (element is Map<String, dynamic>) {
        _addHashesToObject(
          element,
          updateExistingHashes: updateExistingHashes,
          throwOnWrongHashes: throwOnWrongHashes,
        );
      } else if (element is List) {
        _processList(
          element,
          updateExistingHashes: updateExistingHashes,
          throwOnWrongHashes: throwOnWrongHashes,
        );
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

  static bool _areEqualList(List<dynamic> a, List<dynamic> b) {
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
  static Map<String, dynamic> _copyJson(
    Map<String, dynamic> json,
    bool ignoreHashes,
  ) {
    final copy = <String, dynamic>{};
    for (final key in json.keys) {
      if (ignoreHashes && key == '_hash') {
        continue;
      }
      final value = json[key];
      if (value is List) {
        copy[key] = _copyList(value, ignoreHashes);
      } else if (_isBasicType(value)) {
        copy[key] = value;
      } else if (value is Map<String, dynamic>) {
        copy[key] = _copyJson(value, ignoreHashes);
      } else if (value == null) {
        copy[key] = null;
      } else {
        print(key);
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
    }
    return copy;
  }

  // ...........................................................................
  /// Copies the list.
  static List<dynamic> _copyList(List<dynamic> list, bool ignoreHashes) {
    final copy = <dynamic>[];
    for (final element in list) {
      if (element is List) {
        copy.add(_copyList(element, ignoreHashes));
      } else if (_isBasicType(element)) {
        copy.add(element);
      } else if (element is Map<String, dynamic>) {
        copy.add(_copyJson(element, ignoreHashes));
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
  /// Copies [obj], fills missing hashes and verifies existing ones.
  /// Throws [_StaleHashException] when an existing hash does not match.
  Map<String, dynamic> _copyFillVerify(Map<String, dynamic> obj) {
    final copy = <String, dynamic>{};
    var hadHashKey = false;

    for (final key in obj.keys) {
      final value = obj[key];

      if (key == '_hash') {
        hadHashKey = true;
        // Keep the key at its original position.
        // The value is updated below.
        copy['_hash'] = value;
        continue;
      }

      if (value is Map<String, dynamic>) {
        copy[key] = _copyFillVerify(value);
      } else if (value is List) {
        copy[key] = _copyFillVerifyList(value);
      } else if (_isBasicType(value)) {
        copy[key] = value;
      } else if (value == null) {
        copy[key] = null;
      } else {
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
    }

    final calculatedHash = calcHash(_hashPayload(copy));
    final storedHash = hadHashKey ? obj['_hash'] : null;

    if (storedHash == null || (storedHash is String && storedHash.isEmpty)) {
      // Missing or empty hash -> fill it.
      copy['_hash'] = calculatedHash;
    } else if (storedHash is! String || storedHash != calculatedHash) {
      // Existing hash is stale (or has an unexpected type):
      // the caller has to run the full update machinery.
      throw const _StaleHashException();
    }

    return copy;
  }

  // ...........................................................................
  /// List part of [_copyFillVerify].
  List<dynamic> _copyFillVerifyList(List<dynamic> list) {
    final copy = <dynamic>[];
    for (final element in list) {
      if (element is Map<String, dynamic>) {
        copy.add(_copyFillVerify(element));
      } else if (element is List) {
        copy.add(_copyFillVerifyList(element));
      } else if (_isBasicType(element)) {
        copy.add(element);
      } else if (element == null) {
        copy.add(null);
      } else {
        throw Exception('Unsupported type: ${element.runtimeType}');
      }
    }
    return copy;
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
        return config.floatToStr(value);
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
      result.add(
        '"$key":'
        '${encodeValue(map[key])}',
      );
      if (!isLast) result.add(',');
    }
    result.add('}');

    return result.join('');
  }
}

// ...........................................................................
/// Internal signal used by [JsonHash.copyWithVerifiedHashes] to abort the
/// fast path when an existing hash does not match the calculated one.
class _StaleHashException implements Exception {
  const _StaleHashException();
}

// ...........................................................................

/// Shorthand for applying hashes in place
final hip = JsonHash.defaultInstance.applyInPlace;

/// Shorthand for applying hashes
final hsh = JsonHash.defaultInstance.apply;

/// Fills empty hashes into
final amh = JsonHash.defaultInstance.addMissingHashes;

/// Removes hashes from a given JSON structure
final rmhsh = JsonHash.defaultInstance.removeHashes;
