# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-rc.2] - 2026-03-01

### Added
- **Provider Capability Flags** — `create_provider` and `update_provider` now accept `allows_group_mapping` and `allows_group_sync` boolean parameters (default `false`, backward compatible)
- **`Auth.list_providers/2`** — new facade function wrapping `auth.get_providers` with keyword opts for filtering (`:is_active`, `:allows_group_mapping`, `:allows_group_sync`, `:search`)
- **`Auth.validate_provider_allows_group_mapping/1`** — validates that a provider supports group mapping
- **`Auth.validate_provider_allows_group_sync/1`** — validates that a provider supports group sync
- **Resource Access (ACL) Facade** (`KeenAuthPermissions.ResourceAccess`)
  - `has_access?/6` — check if user has a flag on a resource
  - `filter_accessible/5` — bulk filter resource IDs to only accessible ones
  - `grant/7` — grant access flags to a user or group
  - `deny/6` — explicit deny on a user (overrides group grants)
  - `revoke/7` — revoke specific flags from a user or group
  - `revoke_all/4` — remove all ACL entries for a resource (cleanup on delete)
  - `get_flags/4` — get effective flags for a user on a resource
  - `get_matrix/4` — get flags across resource hierarchy
  - `get_grants/4` — list all grants/denies on a resource with user/group details
  - `get_user_resources/5` — list resources a user can access
  - `create_resource_type/7` — register a new resource type (auto-creates partition)
- 12 new auto-generated database functions for the resource access system

### Changed
- Regenerated all database modules with db-gen (194 stored procedure wrappers, up from ~170)
- `Auth.create_provider` arity changed from `/4` to `/6` (backward compatible via defaults)
- `Auth.update_provider` arity changed from `/5` to `/7` (backward compatible via defaults)
- `AuthDeleteProviderModel` return type simplified: was `{user_id, username, display_name}`, now `{delete_provider}` (integer provider_id)
- Translation models: `ua_search_data` field renamed to `nrm_search_data`

### Fixed
- Unskipped `delete_provider` test — the DB-side return type mismatch has been fixed in postgresql-permissions-model v2.15.0

### Database Compatibility
- Requires postgresql-permissions-model **v2.14.0+** (resource access ACL system, provider capability flags)

## [1.0.0-rc.1] - 2026-02-26

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
  - Authentication functions pass request context (ip, user_agent, origin) to database via JSONB `request_context` parameter
  - Support for `user_logged_in`, `user_registered`, `user_login_failed` events
- **Short Code Support** for permissions
  - `Permissions.create/5` now accepts optional `short_code` parameter
  - `Permissions.list/2` returns `short_code` field for each permission
  - `Permissions.search/7` returns `short_code` field in results
  - New `Permissions.get_permissions_map/0` function for mapping between `full_code` and `short_code`
  - `Users.ensure_groups_and_permissions/5` now returns `short_code_permissions` list
- **Source Tracking** for permissions and permission sets
  - `Permissions.create/6` now accepts optional `source` parameter (e.g., `"core"`, `"csv_import"`)
  - `Permissions.search/8` now accepts optional `source` filter parameter
  - `Permissions.list/2` returns `source` field for each permission
  - `Permissions.get_permissions_map/0` returns `source` field
  - Permission sets also support `source` in create, search, and list operations
  - Regenerated all affected db-gen models and parsers
- **Service Accounts** (`KeenAuthPermissions.ServiceAccounts`)
  - Purpose-specific accounts for automated operations: `system`, `registrator`, `authenticator`, `token_manager`, `api_gateway`, `group_syncer`, `data_processor`
  - `ServiceAccounts.user/1` returns a `%User{}` struct for any service account
  - Configurable via `config :keen_auth_permissions, :service_accounts`
  - `RequestContext.service_ctx/1` creates a context for a service account
- **Notifier** (`KeenAuthPermissions.Notifier`)
  - Broadcasts SSE events to connected users via PubSub
  - Standardized event routing for permission changes, group membership, user status, provider, and tenant events
- **Permissions Map GenServer** (`KeenAuthPermissions.PermissionsMap`)
  - Caches bidirectional mapping between `full_code` and `short_code` at startup
  - `full_to_short/1`, `short_to_full/1` for code translation
  - `has?/2`, `has_any?/2`, `has_all?/2` for in-memory permission checking on user structs
  - `resolve_permissions/1` for bulk short-to-full translation
  - `reload/0` to refresh from database
- **PostgreSQL NOTIFY Listener** (`KeenAuthPermissions.PgListener`)
  - GenServer that listens to PostgreSQL NOTIFY channels and broadcasts SSE events
  - Debounce logic for rapid-fire notifications
  - User resolution for affected targets via `PgListener.Resolver`
- **Audit Facade** (`KeenAuthPermissions.Audit`)
  - `get_user_audit_trail/5` - Query unified audit trail for a user
  - `get_security_events/4` - Query security-relevant events
  - `purge_audit_data/2` - Clean up old audit data
- **New Database Functions**
  - `auth.ensure_provider` - Idempotent provider creation (returns `provider_id`, `is_new`)
  - `auth.ensure_user_group_mapping` - Idempotent group mapping creation
  - `auth.get_security_events` - Security event queries
  - `auth.get_user_audit_trail` - Unified audit trail queries
  - `public.purge_audit_data` - Audit data cleanup
- **Token Types Facade** (`KeenAuthPermissions.TokenTypes`)
  - `list/0` - List all token types
  - `create/4`, `update/4`, `delete/3` - Full CRUD for token types
  - `ensure_exists/4` - Idempotent create (checks first, creates if missing)
- **SSE Event Classification** (`KeenAuthPermissions.EventClassification`)
  - Tiered classification of auth events: `:hard`, `:medium`, `:soft`
  - `classify/1` returns the tier for any event name
  - `message/1` returns a human-readable message per event
  - App-level overrides via `config :keen_auth_permissions, :event_classification`
  - See [docs/sse-event-handling.md](docs/sse-event-handling.md) for full documentation
- **Extensible User Struct** (`KeenAuthPermissions.User`)
  - Consuming apps can add custom fields via `config :keen_auth_permissions, user_extra_fields: [...]`
  - Extra fields are optional (default to `nil`), support dot access and pattern matching
  - Compile-time validation — typos in field names cause build errors
- **RevalidateSession Plug** (`KeenAuthPermissions.Plug.RevalidateSession`)
  - TTL-based session revalidation against the database
  - Configurable interval, redirect path, custom `on_invalid` callback, custom `validate_fn`
  - Built-in `clear_user/2` callback for `:maybe_auth` pipelines
- Added CHANGELOG.md to track project changes
- Added comprehensive README.md with usage examples

### Changed
- **Breaking**: `RevalidateSession` now requires `current_user` to be a `%KeenAuthPermissions.User{}` struct. Plain maps are no longer supported — processors must return the proper struct.
- **Breaking**: Updated Elixir requirement from `~> 1.13` to `~> 1.14`
- **Breaking**: RequestContext JSONB rework — stored procedures now accept a single `request_context` JSONB parameter instead of separate `ip`, `user_agent`, `origin` parameters. `correlation_id` remains as a separate parameter on every stored procedure. Affected facade functions: `Auth.register/5`, `Auth.validate_token/6`, `Auth.set_token_as_used/4`, `Auth.set_token_as_failed/4`, `Auth.create_event/4`, `Users.enable/2`, `Users.disable/2`, `Users.lock/2`, `Users.unlock/2`, `Users.register/5`, `Users.ensure_from_provider/8`, `Users.get_by_email_for_auth/2`, `Users.enable_identity/3`, `Users.disable_identity/3`, `Users.update_password/4`, `ApiKeys.validate/4`
- **Breaking**: `Auth.validate_token` arity changed from `/9` to `/6` — individual ip/user_agent/origin params removed, context is now serialized via `RequestContext.to_context_map/1`
- **Breaking**: `Users.update_password` arity changed from `/7` to `/3` or `/4` — individual ip/user_agent/origin/request_id params removed
- **Extensible RequestContext** — `%RequestContext{}` now supports `context_extra_fields` config (same pattern as `user_extra_fields`). Extra fields are included in `to_context_map/1` output for the JSONB parameter
- Added `RequestContext.to_context_map/1` — serializes context metadata (ip, user_agent, origin, request_id, language_code, plus extra fields) into a string-keyed map for the JSONB parameter
- Added `RequestContext.with_field/3` — generic setter for any context field
- Updated `keen_auth` dependency from `~> 0.2` to `~> 1.0`
- Updated `ex_doc` from `~> 0.27` to `~> 0.34`
- Updated `jason` from `~> 1.3` to `~> 1.4`
- Updated `postgrex` from `~> 0.16` to `~> 0.19`
- Regenerated all database models and parsers with db-gen
- `Users.get_by_email_for_auth/2` now requires `RequestContext` instead of raw `user_id`
- `Users.register/5` now extracts context via `RequestContext.to_context_map/1`
- `Users.ensure_from_provider/8` now extracts context via `RequestContext.to_context_map/1`

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
