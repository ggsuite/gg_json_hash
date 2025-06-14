# Changelog

## [3.0.1] - 2025-06-03

### Changed

- Improve handling of separators like .,/,:

## [3.0.0] - 2025-05-28

### Changed

- BREAKING CHANGE: Replace ApplyConfig by named parameters

## [2.0.15] - 2025-05-28

### Added

- Add addMissingHashes

## [2.0.14] - 2025-05-20

### Changed

- Improve updateHint

## [2.0.13] - 2025-05-20

### Added

- Add updateHint

## [2.0.12] - 2025-05-19

### Changed

- Reduce allowed delimiters for hash-pathes to /

## [2.0.11] - 2025-05-17

### Added

- Add uh and updateHashes as shortcuts for UpdateHashes

## [2.0.10] - 2025-05-17

### Added

- Add `JsonInfo` and `UpdateHashes` for retrieving information from hashed Json files and updating hashes after data modification

## [2.0.9] - 2025-05-16

### Added

- Add hip and hsh als shorthands for `JsonHash.defaultInstance.applyInPlace` and `JsonHash.defaultInstance.apply`

## [2.0.8] - 2025-01-27

### Fixed

- Fix: null values in json values lead to errors

## [2.0.7] - 2025-01-24

### Changed

- Empty hashes are treated as no hashes now.

## [2.0.6] - 2025-01-14

### Fixed

- Fixed an issue leading to different hashes compared to the

## [2.0.5] - 2024-11-30

### Changed

- Make JsonHash const

## [2.0.4] - 2024-11-30

### Changed

- Update example

## [2.0.3] - 2024-11-30

### Changed

- Allow to configure number ranges, precision

## [2.0.1] - 2024-11-29

### Fixed

- Fix typo in README

## [2.0.0] - 2024-11-29

### Changed

- BREAKING CHANGE: Fix floating point issues. Improve compatibility with Javascript.

### Fixed

- Fix small issues with floating point precision. Add README.md and example.

## [1.1.4] - 2024-11-28

### Removed

- Remove path dependency

## [1.1.3] - 2024-11-27

### Changed

- Make hash url save

## [1.1.2] - 2024-11-27

### Added

- Add GgJsonHash.validate

## [1.1.1] - 2024-11-27

### Added

- Add recursive flag for adding hashes

## [1.1.0] - 2024-11-23

### Added

- Add inPlace option to write hashes in place.
- Add updateExistingHashes to control if existing hashes are updated.

### Changed

- Update CHANGELOG.md

## [1.0.2] - 2024-11-22

### Added

- Initial boilerplate.
- Add initial implementation
- Add applyToString
- Add example

### Changed

- Increase version

[3.0.1]: https://github.com/inlavigo/gg_json_hash/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/inlavigo/gg_json_hash/compare/2.0.15...3.0.0
[2.0.15]: https://github.com/inlavigo/gg_json_hash/compare/2.0.14...2.0.15
[2.0.14]: https://github.com/inlavigo/gg_json_hash/compare/2.0.13...2.0.14
[2.0.13]: https://github.com/inlavigo/gg_json_hash/compare/2.0.12...2.0.13
[2.0.12]: https://github.com/inlavigo/gg_json_hash/compare/2.0.11...2.0.12
[2.0.11]: https://github.com/inlavigo/gg_json_hash/compare/2.0.10...2.0.11
[2.0.10]: https://github.com/inlavigo/gg_json_hash/compare/2.0.9...2.0.10
[2.0.9]: https://github.com/inlavigo/gg_json_hash/compare/2.0.8...2.0.9
[2.0.8]: https://github.com/inlavigo/gg_json_hash/compare/2.0.7...2.0.8
[2.0.7]: https://github.com/inlavigo/gg_json_hash/compare/2.0.6...2.0.7
[2.0.6]: https://github.com/inlavigo/gg_json_hash/compare/2.0.5...2.0.6
[2.0.5]: https://github.com/inlavigo/gg_json_hash/compare/2.0.4...2.0.5
[2.0.4]: https://github.com/inlavigo/gg_json_hash/compare/2.0.3...2.0.4
[2.0.3]: https://github.com/inlavigo/gg_json_hash/compare/2.0.1...2.0.3
[2.0.1]: https://github.com/inlavigo/gg_json_hash/compare/2.0.0...2.0.1
[2.0.0]: https://github.com/inlavigo/gg_json_hash/compare/1.1.4...2.0.0
[1.1.4]: https://github.com/inlavigo/gg_json_hash/compare/1.1.3...1.1.4
[1.1.3]: https://github.com/inlavigo/gg_json_hash/compare/1.1.2...1.1.3
[1.1.2]: https://github.com/inlavigo/gg_json_hash/compare/1.1.1...1.1.2
[1.1.1]: https://github.com/inlavigo/gg_json_hash/compare/1.1.0...1.1.1
[1.1.0]: https://github.com/inlavigo/gg_json_hash/compare/1.0.2...1.1.0
[1.0.2]: https://github.com/inlavigo/gg_json_hash/tag/%tag
