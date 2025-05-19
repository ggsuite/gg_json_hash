// @license
// Copyright (c) 2025 Dr. Gabriel Gatzsche
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'package:gg_json_hash/gg_json_hash.dart';

/// Updates the hashes in a given Json structure as well their usages
class UpdateHashes {
  /// Constructor
  UpdateHashes({required Map<String, dynamic> json})
      : jsonInfo = JsonInfo(json: json);

  /// The json info as based for the update
  final JsonInfo jsonInfo;

  /// Applies the updates
  void apply() {
    _init();
  }

  /// The updated objects
  Map<String, dynamic> updatedObjects = {};

  /// Old to new hashes map
  Map<String, String> oldToNewHashes = {};

  /// The update JSON
  late Map<String, dynamic> updatedJson;

  // ######################
  // Private
  // ######################

  void _init() {
    jsonInfo.throwOnUnequalAmbigiousHashes();
    jsonInfo.throwOnCircularDependencies();
    _initUpdatedObjects();
    _initUpdatedJson();
  }

  void _initUpdatedObjects() {
    final updateOrder = jsonInfo.updateOrder;
    for (final hash in updateOrder) {
      // Get the object of the hash
      final objects =
          jsonInfo.ambigiousHashes[hash] ?? [jsonInfo.hashToObjects[hash]!];

      for (final object in objects) {
        // Remember the old hash
        final oldHash = object['_hash'] as String;

        // Reset the hash
        object['_hash'] = '';

        // Replace references to other hashes
        _translateReferences(object);

        // Update the hash
        hip(object, updateExistingHashes: false, throwIfWrongHashes: false);

        // Remember the old to new hash
        final newHash = object['_hash'] as String;

        if (newHash != oldHash) {
          oldToNewHashes[oldHash] = newHash;
        }

        updatedObjects[newHash] = object;
      }
    }
  }

  void _translateReferences(Map<String, dynamic> object) {
    for (final entry in [...object.entries]) {
      final key = entry.key;
      final value = entry.value;

      // Translate the key
      final translatedKey = _translate(key) as String;

      // Translate the value
      final translatedValue = _translate(value);

      // Remove the old key if it is different from the new key
      if (translatedKey != key) {
        object.remove(key);
      }
      object[translatedKey] = translatedValue;
    }
  }

  dynamic _translate(dynamic val) {
    if (val is String) {
      final valSegments = val.split(JsonInfo.hashPathSeparator);
      for (var i = 0; i < valSegments.length; i++) {
        final segment = valSegments[i];
        for (var entry in oldToNewHashes.entries) {
          final oldHash = entry.key;
          final newHash = entry.value;
          if (segment == oldHash) {
            valSegments[i] = newHash;
          }
        }
        val = valSegments.join(JsonInfo.hashPathSeparator);
      }
    } else if (val is List) {
      final copy = [...val];
      for (var i = 0; i < val.length; i++) {
        copy[i] = _translate(val[i]);
      }
      val = copy;
    }

    return val;
  }

  void _initUpdatedJson() {
    final oldRootHash = jsonInfo.updateOrder.last;
    final newRootHash = oldToNewHashes[oldRootHash] ?? oldRootHash;
    final newRoot = updatedObjects[newRootHash] as Map<String, dynamic>;
    const jh = JsonHash.defaultInstance;
    jh.validate(newRoot);
    updatedJson = newRoot;
  }
}

/// Updates the hashes in a given Json structure as well their usages
Map<String, dynamic> updateHashes(Map<String, dynamic> json) {
  final updater = UpdateHashes(json: json);
  updater.apply();
  return updater.updatedJson;
}

/// Shortcut for [updateHashes]
const uh = updateHashes;
