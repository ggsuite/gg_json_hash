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
  final Map<String, List<String>> refDependents = {};

  /// Assigns to each object hash a list of dependencies
  final Map<String, List<String>> refDependencies = {};

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init() {
    _initHashToObjects(json);
    _initDependencies();
  }

  // ...........................................................................
  void _initHashToObjects(Map<String, dynamic> json) {
    var hash = json['_hash'] as String?;

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

    allObjects.add(json);

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

  void _initDependencies() {
    for (final parentObject in allObjects) {
      final parentHash = parentObject['_hash'] as String;

      for (final key in parentObject.keys) {
        final childValue = parentObject[key];

        if (childValue is String && key != '_hash') {
          _processStringValue(childValue, parentHash);
        } else if (childValue is List) {
          _processList(childValue, parentObject);
        } /*else if (childValue is Map<String, dynamic>) {
          final childHash = childValue['_hash'] as String;
          _writeDependency(parentHash, childHash);
        }*/
      }
    }
  }

  void _processList(List<dynamic> value, Map<String, dynamic> object) {
    final parentHash = object['_hash'] as String;

    for (final item in value) {
      if (item is String) {
        _processStringValue(item, parentHash);
      } else if (item is List) {
        _processList(item, object);
      }
    }
  }

  void _processStringValue(String childValue, String parentHash) {
    if (hashToObjects.containsKey(childValue)) {
      _writeDependency(parentHash, childValue);
    }
  }

  void _writeDependency(String parentHash, String childHash) {
    // Update dependents
    var a = refDependents[childHash];
    if (a == null) {
      a = <String>[];
      refDependents[childHash] = a;
    }

    a.add(parentHash);

    // Update dependencies
    var b = refDependencies[parentHash];
    if (b == null) {
      b = <String>[];
      refDependencies[parentHash] = b;
    }
    b.add(childHash);
  }
}
