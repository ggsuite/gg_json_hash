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

  // ######################
  // Private
  // ######################

  void _init() {
    final updateOrder = jsonInfo.updateOrder;
  }
}
