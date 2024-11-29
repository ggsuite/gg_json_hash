# gg_json_hash

`gg_json_hash` is a lightweight npm package designed to traverse JSON data
structures and add unique hash identifiers to all objects within them.

![teaser.webp](https://github.com/inlavigo/gg_json_hash/raw/main/teaser.webp)

## Motivation

Hashing nested JSON objects makes sense for several key reasons:

- **Change Detection**: By generating a unique hash for each object, you can easily
  detect changes in complex data structures without manually comparing all
  fields.
- **Efficient Synchronization**: Hashes allow systems to sync only modified or new
  data, reducing bandwidth and improving performance.
- **Cache Management**: Hashes act as unique keys for caching, enabling quick
  retrieval and ensuring data consistency.
- **Data Integrity**: Hashes verify that nested objects remain unaltered, adding an
  extra layer of security and reliability.
- **Simplified Tracking**: In complex systems, hashes provide a consistent way to
  identify and track objects, even across distributed environments.

## Features

- **Recursive Processing**: Add hashes to nested JSON objects.
- **SHA256** Uses SHA256 algorithm for hashing.
- **Hash truncation** Specify the length of the added hashes.
- **Non-Intrusive**: If desired, add hashes without altering existing data.
- **Floating points**: Assign same hashes to similiar floating point numbers

## Example

```js
import 'dart:convert';
import 'package:gg_json_hash/gg_json_hash.dart';

void main() {
  var jh = const JsonHash(floatingPointPrecision: 5);

  // ...........................................................................
  print('Create a json structure');

  var json = <String, dynamic>{
    'a': '0',
    'b': '1',
    'child': {
      'd': 3,
      'e': 4,
    },
  };

  // ...........................................................................
  print('Add hashes to the json structure');
  json = jh.applyTo(json);
  print(const JsonEncoder.withIndent('  ').convert(json));

  // ...........................................................................
  print('set a floating point precision to handle rounding differences');

  final json0 = {
    'a': 1.000001,
  };

  final json1 = {
    'a': 1.000002,
  };

  jh.applyTo(json0);
  jh.applyTo(json1);

  print(
    'Both objects have the same hash because difference is below the precision',
  );
  assert(json0['_hash'] == json1['_hash']); // true

  // ...........................................................................
  print('Use the "inPlace" option to modify the input object');

  json = {'a': 1, 'b': 2};
  jh.applyTo(json, inPlace: true);
  assert(json['_hash'] == 'QyWM_3g_5wNtikMDP4MK38');

  // ...........................................................................
  print('Set "recursive: false" to let child hashes untouched.');

  json = {
    'a': 1,
    'b': 2,
    'child': {'_hash': 'ABC123'},
  };
  addHashes(json, recursive: false);
  assert(json['child']['_hash'] == 'ABC123');

  // ...........................................................................
  print('Set "recursive: true" (default) to recalc child hashes.');

  json = {
    'a': 1,
    'b': 2,
    'child': {'_hash': 'ABC123'},
  };
  json = addHashes(json, recursive: true);
  assert(json['child']['_hash'] == 'RBNvo1WzZ4oRRq0W9-hknp');

  // ...........................................................................
  print(
    'Set "upateExistingHashes: false" to create missing hashes but '
    'not touch existing ones.',
  );

  json = {
    'a': 1,
    'b': 2,
    'child': {'c': 3},
    'child2': {'_hash': 'ABC123', 'd': 4},
  };
  jh = const JsonHash(updateExistingHashes: false);
  json = jh.applyTo(json);
  assert(json['_hash'] == 'pos6bn6mON0sirhEaXq41-');
  assert(json['child']['_hash'] == 'yrqcsGrHfad4G4u9fgcAxY');
  assert(json['child2']['_hash'] == 'ABC123');

  // ...........................................................................
  print('Use JsonHash class to create a pre configured setup');

  const jsonHash = JsonHash(
    floatingPointPrecision: 5,
    recursive: true,
    updateExistingHashes: false,
  );

  // ...........................................................................
  print('Use apply to add hashes to a json object');
  jsonHash.applyTo(json);

  // ...........................................................................
  print('Use validate to check if the hashes are correct');

  json = {'a': 1, 'b': 2};
  json = jh.applyTo(json);
  jh.validate(json); // true

  try {
    json['a'] = 3;
    jh.validate({'a': 3, '_hash': 'invalid'});
  } catch (e) {
    print(e.toString());
  }
}
```
