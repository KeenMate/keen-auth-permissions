# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - Unreleased

### Changed
- **Breaking**: Updated Elixir requirement from `~> 1.13` to `~> 1.14`
- Updated `keen_auth` dependency from `~> 0.2` to `~> 1.0`
- Updated `ex_doc` from `~> 0.27` to `~> 0.34`
- Updated `jason` from `~> 1.3` to `~> 1.4`
- Updated `postgrex` from `~> 0.16` to `~> 0.19`

### Added
- Added `short_code` support for permissions - allows using shorter codes instead of full hierarchical codes
  - `Permissions.create/5` now accepts optional `short_code` parameter
  - `Permissions.list/2` returns `short_code` field for each permission
  - `Permissions.search/7` returns `short_code` field in results
  - New `Permissions.get_permissions_map/0` function for mapping between `full_code` and `short_code`
  - `Users.ensure_groups_and_permissions/5` now returns `short_code_permissions` list
- Added CHANGELOG.md to track project changes
- Added CHANGELOG.md to hex package files

### Fixed
- Cleaned up duplicate auto-generated database files that were causing compilation errors
- Fixed `Logger.warn/1` deprecation warnings (now uses `Logger.warning/2`)
  - Updated `db-gen/parser.gotmpl` template for future regenerations
  - Updated all existing generated parser files
- Fixed test factory `unique_id/0` to use timestamp-based IDs preventing duplicate key violations across test runs

## [0.1.1] - Previous

Initial release extending `keen_auth` with permissions handling capabilities.

### Features
- PostgreSQL stored procedure wrappers for permissions management
- Multi-tenant permission system
- User groups and group membership management
- Permission sets (perm_sets) for grouping permissions
- API key management with permission assignments
- User identity management across providers
- Token validation and management
- db-gen integration for auto-generating Elixir code from PostgreSQL functions
