# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-rc.7] - 2026-04-15

### Added
- **Facade modules** — `ResourceRoles`, `Journal`, `Providers`, `Events`, `Translations` round out the facade layer on top of db_context
- **`Users.add_to_default_groups/3`** wrapper for `auth.assign_user_default_groups` (sibling to `Users.assign_default_groups/3`)
- **Access flag catalog on `ResourceAccess`** — `list_access_flags/2`, `ensure_access_flags/5`, `ensure_resource_type_flags/4`
- Test helper `ensure_entra_provider/0` in `test/support/data_case.ex` for tests that need a group-mapping-capable provider

### Changed
- **db-gen regenerated** — function count grew from 237 to 245 SPs; 238 now have a facade wrapper, 7 intentionally left at raw db_context: `auth_seed_permission_data`, `check_version`, `get_version`, `start_version_update`, `stop_version_update`, `journal_keys` (VARIADIC), `validate_token` (legacy public shadow)
- **SP rename**: `grant_resource_access` → `assign_resource_access` (facade method is still `ResourceAccess.grant/7` for API stability)
- **`language_code` parameter** added to resource types, roles, translations, and permission/perm-set title writes
- **Titles are now translations** — `perm_set.title` / `permission.title` columns removed; titles are stored as translations keyed by `code`. `PermSets.update/5` updates `is_assignable` and writes the title-as-translation, but does **not** mutate `code`
- `SysParams.get/2` now returns `{:error, :not_found}` for all-NULL rows from the SP
- `Permissions.set_assignable/4` returns `{:ok, nil}` on empty SP result (was `{:error, :update_failed}`)
- `unique_string/1` test helper now mixes `System.system_time(:microsecond)` to avoid collisions across separate test-VM runs

### Removed
- **`aad` provider** removed from default seed — library now uses `entra`; tests use the `ensure_entra_provider/0` helper
- Obsolete legacy SPs `add_journal_msg` / `add_journal_msg_jsonb` removed (superseded by `create_journal_message` per ppm source comment)

### Tests
- 229 passing, 0 failures, 1 excluded (`Journal.search/12` test pending an upstream `search_journal` cast fix)

## [1.0.0-rc.6] - 2026-03-17

### Changed
- Regenerated all database modules with db-gen — code formatting now uses multi-line function signatures and parameter lists (237 functions, no functional changes)
- Reformatted all facade modules (`ApiKeys`, `Audit`, `Auth`, `Invitations`, `PermissionsMap`, `Resolver`, `ServiceAccounts`, `SysParams`, `Tenants`, `Users`) with `mix format` line-length compliance
- `internal.throw_no_permission` now accepts `_text[]` (array) instead of `text` for permission codes

## [1.0.0-rc.5] - 2026-03-12

### Added
- **`Invitations.ensure_templates/5`** facade — wraps `auth.ensure_invitation_templates` for idempotent template upsert from a JSONB array of templates with nested actions. Supports `source` and `is_final_state` for cleanup of templates not in the input set.
- New db-gen output: `auth_ensure_invitation_templates/8` function, model, and parser (237 functions total)

### Fixed
- Multi-tenant `CaseClauseError` in `Processor.Email` and `Processor.AzureAD` — `ensure_groups_and_permissions` now returns multiple rows (one per tenant); pattern match updated from `[%{...}]` to `[%{...} | _]` to take the first tenant's groups/permissions

## [1.0.0-rc.4] - 2026-03-10

### Added
- **Tenant-Scoped Permission Enforcement** — all search/get stored procedures now accept `_tenant_id` (caller's tenant) and optionally `_target_tenant_id` (for cross-tenant admin access). This fixes a security issue where 69 out of 154 `has_permission` calls were defaulting to tenant 1 regardless of context.
- **Resolver Facade** (`KeenAuthPermissions.Resolver`) — translates user-facing identifiers (UUID, code) into internal database IDs, so applications never need to expose integer IDs to clients
  - `Resolver.user/1` — resolve bigint, UUID, or code → `user_id`
  - `Resolver.tenant/1` — resolve integer, UUID, or code → `tenant_id`
  - `Resolver.group/2` — resolve integer or code + tenant → `user_group_id`
- 4 new stored procedures: `auth.ensure_access_flags`, `auth.ensure_resource_type_flags`, `auth.get_access_flags`, `auth.search_user_group_mappings`
- 3 new resolver functions added to db-gen: `internal.resolve_user`, `internal.resolve_tenant`, `internal.resolve_group`
- `access_flags` parameter on `ResourceAccess.create_resource_type` and `ResourceAccess.list_resource_types`

### Changed
- **Unified JSONB search signatures** — all 11 search/audit facade functions now use a consistent signature: `(ctx, search_criteria, page, page_size, tenant_id, target_tenant_id)` where `search_criteria` is a map with domain-specific filter keys instead of individual parameters:
  - `Users.search` — criteria: `search_text`, `user_type_code`, `is_active`, `is_locked`
  - `Blacklist.search` — criteria: `search_text`, `reason` (no `target_tenant_id` — app-level)
  - `UserGroups.search` — criteria: `search_text`, `user_group_type_code`, `is_assignable`, `is_external`
  - `Permissions.search` — criteria: `search_text`, `is_assignable`, `parent_code` (no `target_tenant_id`)
  - `PermSets.search` — criteria: `search_text`, `is_assignable`, `is_system`, `source`
  - `Tenants.search` — criteria: `search_text`
  - `ApiKeys.search` / `ApiKeys.search_outbound` — criteria: `search_text`, `is_active`
  - `Audit.search_user_events` — criteria: `event_type_code`, `target_user_id`, `request_context`, `correlation_id`, `from`, `to`
  - `Audit.get_user_audit_trail` — criteria: `target_user_id`, `from`, `to`
  - `Audit.get_security_events` — criteria: `from`, `to`
- **Renamed facade methods** to match updated stored procedure names:
  - `Blacklist.add/8` → `Blacklist.create/8` (calls `auth.create_blacklist_user`)
  - `Blacklist.remove/3` → `Blacklist.delete/3` (calls `auth.delete_blacklist_user`)
  - `PermSets.add_permissions/4` → `PermSets.create_permissions/4` (calls `auth.create_perm_set_permissions`)
  - `Users.add_to_default_groups/3` → `Users.assign_default_groups/3` (calls `auth.assign_user_default_groups`) (Note: `add_to_default_groups/3` was restored in rc.7 as a sibling wrapper; both names now coexist.)
- Regenerated all database modules with db-gen (~236 stored procedure wrappers, up from ~229)
- Updated all facade files to pass new `_tenant_id` / `_target_tenant_id` parameters

### Database Compatibility
- Requires postgresql-permissions-model **v2.23.0+** (tenant-scoped permissions, resolver functions, renamed procedures, unified JSONB search)

## [1.0.0-rc.3] - 2026-03-08

### Added
- **Invitations Facade** (`KeenAuthPermissions.Invitations`)
  - `create/7` — create invitation with inline actions (returns `on_create` backend actions)
  - `create_from_template/8` — create invitation from a reusable template with payload overrides
  - `list/5` — list invitations with optional status, target email, and inviter filters
  - `get_actions/2` — get ordered action list with status, payload, and results
  - `accept/3` — accept invitation, execute `on_accept` database actions, return backend actions
  - `reject/2` — reject invitation, execute `on_reject` actions
  - `revoke/2` — revoke invitation (by inviter or admin)
  - `create_template/7` — create reusable invitation template with action definitions
  - `update_template/6` — update template title, description, message, active status
  - `delete_template/2` — delete invitation template
- **Identity Verification** — `Users.verify_identity/3` marks a user identity as verified
- `is_verified` field on `AuthGetUserIdentityModel` and `AuthGetUserIdentityByEmailModel`
- ~7 new auto-generated database models and parsers for invitation operations

### Changed
- Regenerated all database modules with db-gen (~229 stored procedure wrappers, up from ~219)
- `auth_search_user_events` now accepts `request_context_criteria` JSONB parameter for filtering events by context fields (ip, user_agent, origin)

### Database Compatibility
- Requires postgresql-permissions-model **v2.16.0+** (invitations, identity verification, event context filtering)

## [1.0.0-rc.2] - 2026-03-06

### Added
- **Blacklist Facade** (`KeenAuthPermissions.Blacklist`)
  - `add/8` — add user/identity to blacklist with reason and notes
  - `remove/3` — remove a blacklist entry
  - `search/6` — search blacklist with text/reason filters and pagination
  - `is_blacklisted?/4` — check if a username/provider combination is blacklisted (no auth context required)
- **MFA Facade** (`KeenAuthPermissions.Mfa`)
  - Enrollment: `enroll/4`, `confirm_enrollment/4`, `disable/3`, `get_status/2`, `reset/3`
  - Challenge/Verify: `create_challenge/3`, `verify_challenge/5`
  - Policies: `create_policy/5`, `delete_policy/2`, `get_policies/4`, `is_required?/3`
  - Login: `verify_user_by_email/3`, `record_login_failure/3`
- **Bulk Ensure Operations** — idempotent upsert from JSON with source tracking and `is_final_state` semantics
  - `Permissions.ensure/4` — bulk ensure permissions
  - `PermSets.ensure/5` — bulk ensure permission sets
  - `UserGroups.ensure/5` — bulk ensure user groups
  - `UserGroups.ensure_mappings/4` — bulk ensure user group mappings
  - `ResourceAccess.ensure_resource_types/4` — bulk ensure resource types
- **`ResourceAccess.update_resource_type/7`** — update existing resource type (code, title, description, is_active, source)
- **`ResourceAccess.list_resource_types/3`** — list resource types with optional `source`, `parent_code`, `active_only` filters
- **`Users.get_by_provider_oid/2`** — get user by provider object ID
- **`Users.ensure_info/6`** — ensure user info exists (upsert from external provider data)
- **`Users.delete_info/4`** — enhanced with optional `blacklist` parameter
- **Provider Capability Flags** — `create_provider` and `update_provider` now accept `allows_group_mapping` and `allows_group_sync` boolean parameters
- **`Auth.list_providers/2`** — list providers with keyword opts for filtering
- **`Auth.validate_provider_allows_group_mapping/1`** and **`Auth.validate_provider_allows_group_sync/1`**
- **Resource Access (ACL) Facade** (`KeenAuthPermissions.ResourceAccess`)
  - `has_access?/6`, `filter_accessible/5` — access checks
  - `grant/7`, `deny/6`, `revoke/7`, `revoke_all/4` — access management
  - `get_flags/4`, `get_matrix/4`, `get_grants/4`, `get_user_resources/5` — querying
  - `create_resource_type/7` — register resource types with hierarchy
- `full_title` field on resource type models — hierarchical display (e.g., "Projects > Documents")
- ~26 new auto-generated database models and parsers for blacklist, MFA, ensure operations, and resource types

### Changed
- Regenerated all database modules with db-gen (~220 stored procedure wrappers, up from ~170)
- `Auth.create_provider` arity changed from `/4` to `/6` (backward compatible via defaults)
- `Auth.update_provider` arity changed from `/5` to `/7` (backward compatible via defaults)
- `AuthDeleteProviderModel` return type simplified: now returns `{delete_provider}` (integer provider_id)
- Translation models: `ua_search_data` field renamed to `nrm_search_data`
- `create_resource_type` model updated: new `full_title` field, parameter reordering

### Fixed
- Unskipped `delete_provider` test — DB-side return type mismatch fixed in postgresql-permissions-model v2.15.0

### Database Compatibility
- Requires postgresql-permissions-model **v2.15.0+** (blacklist, MFA, ensure operations, resource types, provider capability flags)

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
