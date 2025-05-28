// @license
// Copyright (c) 2019 - 2024 Dr. Gabriel Gatzsche. All Rights Reserved.
//
// Use of this source code is governed by terms that can be
// found in the LICENSE file in the root of this package.

import 'dart:convert';

import 'package:gg_json_hash/gg_json_hash.dart';

void main() {
  var jh = JsonHash.defaultInstance;

  // ...........................................................................
  print('Create a json structure');

  Map<String, dynamic> json = {
    'a': '0',
    'b': '1',
    'child': {
      'd': 3,
      'e': 4,
    },
  };

  // ...........................................................................
  print('Add hashes to the json structure.');
  json = jh.apply(json);
  print(const JsonEncoder.withIndent('  ').convert(json));

  // ...........................................................................
  print('Set a maximum floating point precision.');

  final config = HashConfig(
    numberConfig: NumberHashingConfig.defaultConfig.copyWith(precision: 0.001),
  );

  jh = JsonHash(config: config);

  try {
    jh.apply({
      'a': 1.000001,
    });
  } catch (e) {
    print(e.toString()); // Number 1.000001 has a higher precision than 0.001
  }

  // ...........................................................................
  print('Use the "inPlace" option to modify the input object directly.');

  json = {'a': 1, 'b': 2};

  jh.apply(json, inPlace: true);
  assert(json['_hash'] == 'QyWM_3g_5wNtikMDP4MK38');

  // ...........................................................................
  print(
    'Set "upateExistingHashes: false" to create missing hashes but '
    'without touching existing ones.',
  );

  json = <String, dynamic>{
    'a': 1,
    'b': 2,
    'child': <String, dynamic>{'c': 3},
    'child2': <String, dynamic>{'_hash': 'ABC123', 'd': 4},
  };

  json = jh.apply(json, updateExistingHashes: false);
  assert(json['_hash'] == 'pos6bn6mON0sirhEaXq41-');
  assert(json['child']['_hash'] == 'yrqcsGrHfad4G4u9fgcAxY');
  assert(json['child2']['_hash'] == 'ABC123');

  // ...........................................................................
  print('If existing hashes do not match new ones, an error is thrown.');

  try {
    jh.apply({'a': 1, '_hash': 'invalid'}, throwOnWrongHashes: true);
  } catch (e) {
    print(e.toString());
    // 'Hash "invalid" does not match the newly calculated
    // one "AVq9f1zFei3ZS3WQ8ErYCE". Please make sure that all systems
    // are producing the same hashes.'
  }

  // ...........................................................................
  print('Set "throwOnWrongHashes" to false to replace invalid hashes.');
  json = jh.apply(
    {'a': 1, '_hash': 'invalid'},
    throwOnWrongHashes: false,
    updateExistingHashes: true,
  );
  print(json['_hash']); // AVq9f1zFei3ZS3WQ8ErYCE

  // ...........................................................................
  print('Use validate to check if the hashes are correct');

  json = {'a': 1, 'b': 2};
  json = jh.apply(json);
  jh.validate(json); // true

  try {
    json['a'] = 3;
    jh.validate({'a': 3, '_hash': 'invalid'});
  } catch (e) {
    print(e.toString());
  }
}
