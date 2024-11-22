#!/usr/bin/env dart
// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_json_hash/src/gg_json_hash.dart';

Future<void> main() async {
  // Write hashes into a JSON string
  const json = '{"key": "value"}';
  final jsonString = const JsonHash().applyToString(json);
  print(jsonString); // '{"key":"value","_hash":"5Dq88zdSRIOcAS+WM/lYYt"}');

  // Write hashes into a JSON object
  final jsonMap = {'hellod': 'world'};
  final hashedJson = const JsonHash().applyTo(jsonMap);
  final hashedJsonString = jsonEncode(hashedJson);
  print(
    hashedJsonString,
  ); // {"hellod":"world","_hash":"i811N7aI03kp1AIL6j/Bmo"}
}
