// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';

/// Fixes hashes in a given Json structure
class JsonInfo {
  /// Constructor
  JsonInfo({required this.json}) {
    _init();
  }

  /// The json to be fixed
  final Map<String, dynamic> json;

  /// The fixed json
  Map<String, dynamic> get fixedJson {
    return json;
  }

  // ...........................................................................
  /// A list of all objects
  final List<Map<String, dynamic>> allObjects = [];

  /// Assigns each object of the array to its hash
  final Map<String, Map<String, dynamic>> hashToObjects = {};

  /// Assigns to each hash hashes that are referenced by the hash
  final Map<String, List<Map<String, dynamic>>> isReferencedBy = {};

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init() {
    _initHashToObjects(json);
    _initIsReferencedBy(json);
  }

  // ...........................................................................
  void _initHashToObjects(Map<String, dynamic> json) {
    var hash = json['_hash'] as String?;
    allObjects.add(json);

    // Make sure every object has an hash
    if (hash == null) {
      json = hsh(
        json,
        applyConfig: const ApplyJsonHashConfig(
          throwIfOnWrongHashes: false,
          updateExistingHashes: false,
        ),
      );
      hash = json['_hash'] as String;
    }

    hashToObjects[hash] = json;

    for (final entry in json.entries) {
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        _initHashToObjects(value);
      } else if (value is List) {
        _initHashToObjectsForList(value);
      }
    }
  }

  void _initHashToObjectsForList(List<dynamic> value) {
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        _initHashToObjects(item);
      } else if (item is List) {
        _initHashToObjectsForList(item);
      }
    }
  }

  void _initIsReferencedBy(Map<String, dynamic> json) {
    for (final object in allObjects) {
      for (final key in object.keys) {
        final value = object[key];

        if (value is String && key != '_hash') {
          _processString(value, object);
        } else if (value is List) {
          _processList(value, object);
        }
      }
    }
  }

  void _processList(List<dynamic> value, Map<String, dynamic> object) {
    for (final item in value) {
      if (item is String) {
        _processString(item, object);
      } else if (item is List) {
        _processList(item, object);
      }
    }
  }

  void _processString(String value, Map<String, dynamic> object) {
    if (hashToObjects.containsKey(value)) {
      var array = isReferencedBy[value];
      if (array == null) {
        array = <Map<String, dynamic>>[];
        isReferencedBy[value] = array;
      }

      array.add(object);
    }
  }
}
