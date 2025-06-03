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
  /// Separators for hashes
  static const hashPathSeparators = ['/', ':', '.'];

  // ...........................................................................
  /// A list of all objects
  final List<Map<String, dynamic>> allObjects = [];

  /// Assigns each object of the array to its hash
  final Map<String, Map<String, dynamic>> hashToObjects = {};

  /// Offers hashes that are connected to different objects
  final Map<String, Set<Map<String, dynamic>>> ambigiousHashes = {};

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
  List<String> get updateOrder {
    if (_updateOrder == null) {
      throwOnCircularDependencies();
      throwOnUnequalAmbigiousHashes();
      _initUpdateOrder();
    }

    return _updateOrder!;
  }

  // ...........................................................................
  /// Throws an exception if circular dependencies are detected
  void throwOnCircularDependencies() {
    if (circularDependencies.isNotEmpty) {
      final deps = circularDependencies.map((e) => '  - ${e.join(' -> ')}');

      throw Exception(
        [
          'Cannot update hashes: Circular dependencies detected:',
          ...deps,
        ].join('\n'),
      );
    }
  }

  // ...........................................................................
  /// Throws an exception if ambigious hashes are detected
  void throwOnUnequalAmbigiousHashes() {
    final unequalAmbigiousHashes = <String>[];
    for (final entry in ambigiousHashes.entries) {
      final hash = entry.key;
      final objects = entry.value;
      final firstObject = objects.first;
      for (var i = 1; i < objects.length; i++) {
        final object = objects.elementAt(i);
        if (!JsonHash.areEqual(firstObject, object)) {
          unequalAmbigiousHashes.add(hash);
          break;
        }
      }
    }

    if (unequalAmbigiousHashes.isNotEmpty) {
      final hashes = ambigiousHashes.keys.map((e) => '  - $e');
      throw Exception(
        [
          'Ambigious hashes detected:',
          ...hashes,
        ].join('\n'),
      );
    }
  }

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
  }

  // ...........................................................................
  void _addMissingHashes(dynamic json) {
    if (json is Map<String, dynamic>) {
      for (final entry in json.entries) {
        _addMissingHashes(entry.value);
      }

      final hash = json['_hash']?.trim() as String? ?? '';

      if (hash.isEmpty) {
        json = hip(
          json,
          throwOnWrongHashes: false,
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
    _updateAmbigiousObjects(json, hash);
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
  void _updateAmbigiousObjects(
    Map<String, dynamic> newJson,
    String hash,
  ) {
    final existingJson = hashToObjects[hash];

    if (existingJson == null) {
      return;
    }

    final ao = ambigiousHashes[hash] ??= {};
    ao.add(existingJson);
    ao.add(newJson);
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

  void _processStringValue(String childValue, String parentHash) {
    final regExp = RegExp('[${JsonInfo.hashPathSeparators.join('')}]');
    final parts = childValue.split(regExp);

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

    if (!a.contains(parentHash)) {
      a.add(parentHash);
    }

    // Update dependencies
    var b = refDependencies[parentHash];
    if (b == null) {
      b = <String>[];
      refDependencies[parentHash] = b;
    }
    if (!b.contains(childHash)) {
      b.add(childHash);
    }
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
    if (!a.contains(parentHash)) {
      a.add(parentHash);
    }

    // Update dependencies
    var b = childDependencies[parentHash];
    if (b == null) {
      b = <String>[];
      childDependencies[parentHash] = b;
    }
    if (!b.contains(childHash)) {
      b.add(childHash);
    }
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
  List<String>? _updateOrder;

  void _initUpdateOrder() {
    _updateOrder = [];

    final allHashes = this.allHashes.toList();
    final remainingHashes = allHashes.toList();
    for (final hash in allHashes) {
      _initSubUpdateOrder(hash, remainingHashes);
    }
  }

  void _initSubUpdateOrder(String hash, List<String> remainingHashes) {
    if (!remainingHashes.contains(hash)) {
      return;
    }

    final List<String> dependencies = allDependencies[hash] ?? [];

    for (final d in dependencies) {
      _initSubUpdateOrder(d, remainingHashes);
    }
    _updateOrder!.add(hash);
    remainingHashes.remove(hash);
  }
}
