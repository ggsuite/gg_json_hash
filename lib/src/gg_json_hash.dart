// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

// ...........................................................................
import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';

// #############################################################################
/// Deeply hashes a JSON object.
Map<String, dynamic> addHashes(
  Map<String, dynamic> json, {
  bool updateExistingHashes = true,
  int floatingPointPrecision = 10,
  int hashLength = 22,
  bool inPlace = false,
  bool recursive = true,
}) {
  return JsonHash(
    hashLength: hashLength,
    floatingPointPrecision: floatingPointPrecision,
    updateExistingHashes: updateExistingHashes,
    recursive: recursive,
  ).applyTo(json, inPlace: inPlace);
}

// #############################################################################
/// Adds hashes to JSON object
class JsonHash {
  /// Constructor
  const JsonHash({
    this.hashLength = 22,
    this.floatingPointPrecision = 10,
    this.updateExistingHashes = true,
    this.recursive = true,
  });

  /// Replace existing hashes
  final bool updateExistingHashes;

  /// The hash length in bytes
  final int hashLength;

  /// Round floating point numbers to this precision before hashing
  final int floatingPointPrecision;

  /// Recursively iterates into child objects
  final bool recursive;

  /// Writes hashes into the JSON object
  Map<String, dynamic> applyTo(
    Map<String, dynamic> json, {
    bool inPlace = false,
  }) {
    final copy = inPlace ? json : _copyJson(json);
    _addHashesToObject(copy, recursive);
    return copy;
  }

  /// Writes hashes into a JSON string
  String applyToString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    final hashedJson = applyTo(json, inPlace: true);
    return jsonEncode(hashedJson);
  }

  /// Calculates a SHA-256 hash of a string with base64 url
  String calcHash(String string) {
    final digest = sha256.convert(utf8.encode(string));
    return base64UrlEncode(digest.bytes).substring(0, hashLength);
  }

  // ...........................................................................
  /// Throws if hashes are not correct
  void validate(Map<String, dynamic> json) {
    // Check the hash of the high level element
    final jsonWithCorrectHashes = applyTo(json);
    _validate(json, jsonWithCorrectHashes, '');
  }

  // ######################
  // Private
  // ######################

  // ...........................................................................
  static void _validate(
    Map<String, dynamic> jsonIs,
    Map<String, dynamic> jsonShould,
    String path,
  ) {
    // Check the hashes of the parent element
    final expectedHash = jsonShould['_hash'] as String;
    final actualHash = jsonIs['_hash'] as String?;

    if (actualHash == null) {
      final pathHint = path.isEmpty ? '' : ' at $path';
      throw Exception('Hash$pathHint is missing.');
    }

    if (expectedHash != actualHash) {
      final pathHint = path.isEmpty ? '' : ' at $path';
      throw Exception(
        'Hash$pathHint "$actualHash" is wrong. Should be "$expectedHash".',
      );
    }

    // Check the hashes of the child element
    // Check the hashes of the child elements
    for (final item in jsonIs.entries) {
      if (item.key == '_hash') continue;
      if (item.value is Map<String, dynamic>) {
        final childIs = item.value as Map<String, dynamic>;
        final childShould = jsonShould[item.key] as Map<String, dynamic>;
        _validate(childIs, childShould, '$path/${item.key}');
      } else if (item.value is List<dynamic>) {
        for (var i = 0; i < (item.value as List<dynamic>).length; i++) {
          if (item.value[i] is Map<String, dynamic>) {
            final itemIs = item.value[i] as Map<String, dynamic>;
            final itemShould = (jsonShould[item.key] as List<dynamic>)[i]
                as Map<String, dynamic>;

            _validate(
              itemIs,
              itemShould,
              '$path/${item.key}/$i',
            );
          }
        }
      }
    }
  }

  // ...........................................................................
  /// Recursively adds hashes to a nested object.
  void _addHashesToObject(
    Map<String, dynamic> obj,
    bool recursive,
  ) {
    if (!updateExistingHashes && obj.containsKey('_hash')) {
      return;
    }

    // Recursively process child elements
    obj.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final existingHash = value['_hash'];
        if (existingHash != null && !recursive) {
          return;
        }
        _addHashesToObject(value, recursive);
      } else if (value is List<dynamic>) {
        _processList(value);
      }
    });

    // Build a new object to represent the current object for hashing
    final objToHash = <String, dynamic>{};

    for (final entry in obj.entries) {
      final key = entry.key;
      if (key == '_hash') continue;
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        objToHash[key] = value['_hash'] as String;
      } else if (value is List<dynamic>) {
        objToHash[key] = _flattenList(value);
      } else if (_isBasicType(value)) {
        objToHash[key] = _convertBasicType(value, floatingPointPrecision);
      } else {
        // coverage:ignore-start
        throw Exception('Unsupported type: ${value.runtimeType}');
        // coverage:ignore-end
      }
    }

    // Sort the object keys to ensure consistent key order
    final sortedMap = SplayTreeMap<String, dynamic>.from(objToHash);
    final sortedMapJson = _jsonString(sortedMap);

    // Compute the SHA-256 hash of the JSON string
    var hash = calcHash(sortedMapJson);

    // Add the hash to the original object
    obj['_hash'] = hash;
  }

  // ...........................................................................
  static dynamic _convertBasicType(
    dynamic value,
    int floatingPointPrecision,
  ) {
    if (value is String) {
      return value;
    }
    if (value is num) {
      return _truncate(value, floatingPointPrecision);
    } else if (value is bool) {
      return value;
    } else {
      throw Exception('Unsupported type: ${value.runtimeType}');
    }
  }

  // ...........................................................................
  /// Builds a representation of a list for hashing.
  List<dynamic> _flattenList(List<dynamic> list) {
    var flattenedList = <dynamic>[];

    for (final element in list) {
      if (element is Map<String, dynamic>) {
        flattenedList.add(element['_hash'] as String);
      } else if (element is List<dynamic>) {
        flattenedList.add(_flattenList(element));
      } else if (_isBasicType(element)) {
        flattenedList.add(_convertBasicType(element, floatingPointPrecision));
      }
    }

    return flattenedList;
  }

  // ...........................................................................
  /// Recursively processes a list, adding hashes to nested objects and lists.
  void _processList(List<dynamic> list) {
    for (final element in list) {
      if (element is Map<String, dynamic>) {
        _addHashesToObject(element, recursive);
      } else if (element is List<dynamic>) {
        _processList(element);
      }
    }
  }

  // ...........................................................................
  /// Copies the JSON object
  static Map<String, dynamic> _copyJson(Map<String, dynamic> json) {
    final copy = <String, dynamic>{};
    for (final entry in json.entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        copy[key] = _copyJson(value);
      } else if (value is List<dynamic>) {
        copy[key] = _copyList(value);
      } else if (_isBasicType(value)) {
        copy[key] = value;
      } else {
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
    }
    return copy;
  }

  // ...........................................................................
  /// Copies the list
  static List<dynamic> _copyList(List<dynamic> list) {
    final copy = <dynamic>[];
    for (final element in list) {
      if (element is Map<String, dynamic>) {
        copy.add(_copyJson(element));
      } else if (element is List<dynamic>) {
        copy.add(_copyList(element));
      } else if (_isBasicType(element)) {
        copy.add(element);
      } else {
        throw Exception('Unsupported type: ${element.runtimeType}');
      }
    }
    return copy;
  }

  // ...........................................................................
  static bool _isBasicType(dynamic value) {
    return value is String || value is int || value is double || value is bool;
  }

  // ...........................................................................
  /// Turns a double into a string with a given precision.
  static num _truncate(
    num value,
    int precision,
  ) {
    if (value is int) {
      return value;
    }

    String result = value.toString();
    final parts = result.split('.');
    final integerPart = parts[0];
    final commaParts = parts[1];

    var truncatedCommaParts = commaParts.length > precision
        ? commaParts.substring(0, precision)
        : commaParts;

    // Remove trailing zeros
    if (truncatedCommaParts.endsWith('0')) {
      truncatedCommaParts = truncatedCommaParts.replaceAll(RegExp(r'0+$'), '');
    }

    if (truncatedCommaParts.isEmpty) {
      return double.parse(integerPart).toInt();
    }

    result = '$integerPart.$truncatedCommaParts';
    return double.parse(result);
  }

  // ...........................................................................
  static String _jsonString(Map<String, dynamic> map) {
    String encodeValue(dynamic value) {
      if (value is String) {
        return '"${value.replaceAll('"', '\\"')}"'; // Escape Anführungszeichen
      } else if (value is num || value is bool) {
        return value.toString();
      } else if (value == null) {
        return 'null';
      } else if (value is List) {
        return '[${value.map((e) => encodeValue(e)).join(",")}]';
      } else if (value is Map<String, dynamic>) {
        return _jsonString(value);
      } else {
        throw Exception('Unsupported type: ${value.runtimeType}');
      }
    }

    return '{${map.entries.map(
          (e) => '"${e.key}"'
              ':${encodeValue(e.value)}',
        ).join(',')}}';
  }

  // ...........................................................................
  /// For test purposes we are exposing these private methods
  static Map<String, dynamic> get privateMethods => {
        '_copyJson': _copyJson,
        '_copyList': _copyList,
        '_isBasicType': _isBasicType,
        '_truncate': _truncate,
        '_jsonString': _jsonString,
        '_convertBasicType': _convertBasicType,
      };
}
