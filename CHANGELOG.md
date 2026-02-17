# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - Unreleased

### Added
- **Email Authentication Support**
  - New `Auth.authenticate_by_email/3` for email/password login
  - New `Auth.register_user/4` convenience function for user registration
  - Password hashing using Pbkdf2 (pure Elixir, no C compiler required)
  - Added `pbkdf2_elixir` dependency for secure password hashing
- **Permission Helpers Module** (`KeenAuthPermissions.PermissionHelpers`)
  - In-memory permission checking without database calls
  - Boolean checks: `has_any?/2`, `has_all?/2`, `in_any_group?/2`, `in_all_groups?/2`
  - Result-based checks for `with` blocks: `require_any/2`, `require_all/2`, `require_any_group/2`
  - Function wrappers: `with_permission/3`, `with_all_permissions/3`
  - Works with both `User` struct and `RequestContext`
- **Request Context** (`KeenAuthPermissions.RequestContext`)
  - Structured context for passing user and request metadata
  - Includes `ip`, `user_agent`, `origin` fields for event logging
  - `system_ctx/0` for background jobs and system operations
- **Facade Modules** for high-level operations
  - `KeenAuthPermissions.Auth` - Authentication, registration, tokens, user events
  - `KeenAuthPermissions.Users` - User management, search, preferences
  - `KeenAuthPermissions.UserGroups` - Group management and membership
  - `KeenAuthPermissions.Tenants` - Tenant CRUD, search, members, and user-tenant operations
  - `KeenAuthPermissions.PermSets` - Permission set management
  - `KeenAuthPermissions.ApiKeys` - API key management
- **User-Tenant Operations** in `KeenAuthPermissions.Tenants`
  - `get_user_available_tenants/2` - List tenants available to a specific user
  - `get_user_last_selected_tenant/2` - Get a user's last selected tenant
  - `update_user_last_selected_tenant/3` - Update a user's last selected tenant
  - `create_user_tenant_preferences/4` - Create user tenant preferences
  - `update_user_tenant_preferences/5` - Update user tenant preferences
- **User Event Support**
  - All authentication functions now pass `ip_address`, `user_agent`, `origin` to database
  - Support for `user_logged_in`, `user_registered`, `user_login_failed` events
- **Short Code Support** for permissions
  - `Permissions.create/5` now accepts optional `short_code` parameter
  - `Permissions.list/2` returns `short_code` field for each permission
  - `Permissions.search/7` returns `short_code` field in results
  - New `Permissions.get_permissions_map/0` function for mapping between `full_code` and `short_code`
  - `Users.ensure_groups_and_permissions/5` now returns `short_code_permissions` list
- **Token Types Facade** (`KeenAuthPermissions.TokenTypes`)
  - `list/0` - List all token types
  - `create/4`, `update/4`, `delete/3` - Full CRUD for token types
  - `ensure_exists/4` - Idempotent create (checks first, creates if missing)
- Added CHANGELOG.md to track project changes
- Added comprehensive README.md with usage examples

### Changed
- **Breaking**: Updated Elixir requirement from `~> 1.13` to `~> 1.14`
- Updated `keen_auth` dependency from `~> 0.2` to `~> 1.0`
- Updated `ex_doc` from `~> 0.27` to `~> 0.34`
- Updated `jason` from `~> 1.3` to `~> 1.4`
- Updated `postgrex` from `~> 0.16` to `~> 0.19`
- Regenerated all database models and parsers with db-gen
- `Users.get_by_email_for_auth/2` now requires `RequestContext` instead of raw `user_id`
- `Users.register/5` now extracts `ip`, `user_agent`, `origin` from `RequestContext`
- `Users.ensure_from_provider/8` now extracts `ip`, `user_agent`, `origin` from `RequestContext`

### Fixed
- Cleaned up duplicate auto-generated database files that were causing compilation errors
- Fixed `Logger.warn/1` deprecation warnings (now uses `Logger.warning/2`)
  - Updated `db-gen/parser.gotmpl` template for future regenerations
  - Updated all existing generated parser files
- Fixed test factory `unique_id/0` to use timestamp-based IDs preventing duplicate key violations across test runs
- Added nil guards in `verify_password/2` to prevent crashes when `password_hash` is nil
- Fixed Azure AD processor to extract client IP, user agent, and origin from conn

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
