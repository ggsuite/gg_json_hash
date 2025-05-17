// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';

/// Fixes hashes in a given Json structure
class JsonInfo {
  /// Constructor
  JsonInfo({required Map<String, dynamic> json})
      : json = JsonHash.copyJson(json) {
    _init();
  }

  /// The json to be analyzed
  final Map<String, dynamic> json;

  // ...........................................................................
  /// A list of all objects
  final List<Map<String, dynamic>> allObjects = [];

  /// Assigns each object of the array to its hash
  final Map<String, Map<String, dynamic>> hashToObjects = {};

  /// A set of all hashes that are used in the json
  late final Iterable<String> allHashes;

  /// Assigns to each hash hashes that are referenced by the hash
  final Map<String, List<String>> refDependents = {};

  /// Assigns to each object hash a list of dependencies
  final Map<String, List<String>> refDependencies = {};

  /// Assigns to each hash child hashes the object with hash depends on
  final Map<String, List<String>> childDependencies = {};

  /// Assigns to each hash parent that depend on the child
  final Map<String, List<String>> childDependents = {};

  /// Assigns hashes of objects to hashes of objects that are
  /// referenced by the hash
  final Map<String, List<String>> allDependencies = {};

  /// Assigns hashes of objects to hashes of objects that refer to the object
  final Map<String, List<String>> allDependents = {};

  /// Returns a list of circular dependencies
  final List<List<String>> circularDependencies = [];

  /// Returns a list of hashes in an update order
  final List<String> updateOrder = [];

  // ######################
  // Private
  // ######################

  // ...........................................................................
  void _init() {
    _addMissingHashes(json);
    _initHashToObjects(json);
    _initAllHashes();
    _initRefDependencies();
    _initChildDependencies(json);
    _initAllDependencies();
    _initCircularDependencies();
    _initUpdateOrder();
  }

  // ...........................................................................
  void _addMissingHashes(dynamic json) {
    if (json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        _addMissingHashes(entry.value);
      }

      if (json['_hash'] == null) {
        json = hip(
          json,
          throwIfWrongHashes: false,
          updateExistingHashes: false,
        );
      }
    } else if (json is List) {
      for (final item in json) {
        _addMissingHashes(item);
      }
    }
  }

  // ...........................................................................
  void _initHashToObjects(Map<String, dynamic> json) {
    var hash = json['_hash'] as String;
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

  // ...........................................................................
  void _initAllHashes() {
    allHashes = hashToObjects.keys;
  }

  // ...........................................................................
  void _initRefDependencies() {
    for (final parentObject in allObjects) {
      final parentHash = parentObject['_hash'] as String;

      for (final key in parentObject.keys) {
        final childValue = parentObject[key];
        if (key != '_hash') {
          // Process hashes in keys
          _processStringValue(key, parentHash);

          // Process hashes in values
          if (childValue is String && key != '_hash') {
            _processStringValue(childValue, parentHash);
          } else if (childValue is List) {
            _processList(childValue, parentObject);
          }
        }
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

  final _byDelimiter = RegExp(r'[\.\[\]\\\/\s%\(\)\|]');

  void _processStringValue(String childValue, String parentHash) {
    final parts = childValue.split(_byDelimiter);

    for (final childValuePart in parts) {
      if (hashToObjects.containsKey(childValuePart)) {
        _writeDependency(parentHash, childValuePart);
      }
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

  // ...........................................................................
  void _initChildDependencies(Map<String, dynamic> json) {
    final parentHash = json['_hash'] as String;

    for (final entry in json.entries) {
      _initSubChildDependencies(parentHash, entry.value);
    }
  }

  void _initSubChildDependencies(
    String parentHash,
    dynamic value,
  ) {
    // Process dictionary
    if (value is Map<String, dynamic>) {
      final childHash = value['_hash'] as String;
      _writeChildDependency(parentHash, childHash);
      for (final subVal in value.values) {
        _initSubChildDependencies(childHash, subVal);
      }
    }

    // Process list
    else if (value is List) {
      for (final item in value) {
        if (item is Map<String, dynamic> || item is List) {
          _initSubChildDependencies(
            parentHash,
            item,
          );
        }
      }
    }
  }

  void _writeChildDependency(String parentHash, String childHash) {
    // Update dependents
    var a = childDependents[childHash];
    if (a == null) {
      a = <String>[];
      childDependents[childHash] = a;
    }
    a.add(parentHash);

    // Update dependencies
    var b = childDependencies[parentHash];
    if (b == null) {
      b = <String>[];
      childDependencies[parentHash] = b;
    }
    b.add(childHash);
  }

  // ...........................................................................
  void _initAllDependencies() {
    for (final hash in allHashes) {
      // Init all dependencies
      final refDeps = refDependencies[hash] ?? const [];
      final childDeps = childDependencies[hash] ?? const [];

      if (refDeps.isNotEmpty || childDeps.isNotEmpty) {
        allDependencies[hash] = {...refDeps, ...childDeps}.toList();
      }

      // Init all dependents
      final refDeps2 = refDependents[hash] ?? const [];
      final childDeps2 = childDependents[hash] ?? const [];
      if (refDeps2.isNotEmpty || childDeps2.isNotEmpty) {
        allDependents[hash] = {...refDeps2, ...childDeps2}.toList();
      }
    }
  }

  // ...........................................................................
  void _initCircularDependencies() {
    // Create a copy of the list of all hashes that have dependencies
    final processedHashes = <String>{};
    for (final key in allDependencies.keys) {
      _findCircularReferences(key, [], processedHashes);
    }
  }

  void _findCircularReferences(
    String key,
    List<String> chain,
    Set<String> processedHashes,
  ) {
    // Check if the current key is already in the chain
    // -> circular dependency
    if (chain.contains(key)) {
      final index = chain.indexOf(key);
      chain = [...chain.sublist(index), key];
      circularDependencies.add(chain);
      return;
    }

    // Add the key to the chain
    chain = [...chain, key];

    // If the key has already been processed, stop here
    if (processedHashes.contains(key)) {
      return;
    }
    processedHashes.add(key);

    // Check all dependencies
    final dependencies = allDependencies[key];
    if (dependencies == null) {
      return;
    } else {
      for (final d in dependencies) {
        _findCircularReferences(d, chain, processedHashes);
      }
    }

    return;
  }

  // ...........................................................................
  void _initUpdateOrder() {
    final remainingHashes = allHashes.toList();
  }

  void _initSubUpdateOrder() {}
}
