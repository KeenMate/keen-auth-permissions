# KeenAuthPermissions

A comprehensive Elixir library for authentication and authorization, extending [keen_auth](https://hexdocs.pm/keen_auth/readme.html) with PostgreSQL-backed permission management. Built entirely on top of [postgresql-permissions-model](https://github.com/KeenMate/postgresql-permissions-model), this library serves as an Elixir wrapper around the stored procedures defined in that PostgreSQL module.

## Features

- **Database-First Architecture**: Business logic implemented as PostgreSQL stored procedures with Elixir wrappers
- **Multi-Tenant Support**: Full tenant isolation for permissions, groups, and users
- **User Management**: Registration, authentication, user profiles, and identity management
- **Group Management**: User groups with membership and permission inheritance
- **Permission System**: Hierarchical permissions with short codes, permission sets, and source tracking
- **Permissions Map**: In-memory GenServer cache for fast full_code/short_code translation and permission checks
- **API Key Management**: Create and manage API keys with granular permissions
- **Resource Access (ACL)**: Resource-level authorization layered on top of RBAC — grant/deny/revoke per-resource flags to users or groups
- **Blacklist Management**: Create/delete/search blacklisted users and identities with reason tracking (app-level, not per-tenant)
- **Identifier Resolver**: Translate user-facing UUIDs and codes into internal database IDs without exposing integer keys
- **Multi-Factor Authentication (MFA)**: TOTP enrollment, challenge/verify flow, policy management (tenant/group/user-level), recovery codes, login verification
- **Bulk Ensure Operations**: Idempotent upsert for permissions, permission sets, user groups, group mappings, and resource types from JSON with source tracking and final-state semantics
- **Invitations**: Phase-based invitation system with templates, conditions, and action orchestration — invite users to tenants, groups, permission sets, and resources
- **Audit Trail**: Unified audit trail and security event queries with data purge support
- **Token Management**: Secure token creation, validation, and lifecycle management
- **Event Logging**: User events with IP, user agent, and origin tracking
- **SSE Event Classification**: Tiered real-time event handling (hard/medium/soft) for LiveView apps — see [docs/sse-event-handling.md](docs/sse-event-handling.md)
- **PostgreSQL NOTIFY Listener**: Real-time event broadcasting from database triggers via PgListener
- **Service Accounts**: Purpose-specific accounts (system, registrator, authenticator, etc.) for meaningful audit trails
- **Email Authentication**: Built-in support for email/password authentication with Pbkdf2 hashing
- **Resource Roles**: Named bundles of access flags per resource type; assign/revoke roles to users or groups
- **Journal**: Create and search application-owned audit entries (backend-originated events)
- **Providers**: Declaratively upsert auth providers and external-group → internal-group mappings at startup
- **Events**: Register application-owned event taxonomies (categories, codes, message templates in the 50000+ range)
- **Translations**: Full i18n domain — translations CRUD + language catalog with frontend/backend/communication capability flags

## Installation

Add `keen_auth_permissions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:keen_auth_permissions, "~> 1.0.0-rc.7"}
  ]
end
```

## Configuration

### Database context

Create a database module in your application and point the config to it:

```elixir
defmodule MyApp.Database do
  use KeenAuthPermissions.Database, repo: MyApp.Repo
end
```

```elixir
# config/config.exs
config :keen_auth_permissions,
  db_context: MyApp.Database
```

### Full config reference

```elixir
# config/config.exs
config :keen_auth_permissions,
  db_context: MyApp.Database,
  tenant: 1,                                          # default tenant ID
  password_hasher: Pbkdf2,                             # or Argon2, Bcrypt, etc.
  user_extra_fields: [:employee_number, :department],  # extend the User struct
  context_extra_fields: [:tenant_code, :session_id],   # extend RequestContext
  notifier: [
    enabled: true,
    pubsub: MyApp.PubSub
  ],
  pg_listener: [
    enabled: true,
    repo: MyApp.Repo,
    pubsub: MyApp.PubSub,
    channels: ["auth_events"],
    debounce_interval: 200
  ]
```

### Extending the User Struct

The `%KeenAuthPermissions.User{}` struct ships with standard fields (`user_id`, `code`, `uuid`, `username`, `email`, `display_name`, `groups`, `permissions`). Consuming applications can add custom fields:

```elixir
# config/config.exs
config :keen_auth_permissions,
  user_extra_fields: [:employee_number, :department, :phone]
```

Extra fields default to `nil` and work like any other struct field — dot access, pattern matching, and compile-time validation:

```elixir
# In your processor
user = %KeenAuthPermissions.User{
  user_id: db_user.user_id,
  # ... standard fields ...
  employee_number: "EMP-1234",
  department: "engineering"
}

# In your code
user.employee_number
%User{department: dept} = current_user
```

### Extending the Request Context

The `%KeenAuthPermissions.RequestContext{}` struct ships with standard context fields (`ip`, `user_agent`, `origin`, `language_code`, `request_id`). Consuming applications can add custom context fields that will be included in the JSONB context parameter passed to stored procedures:

```elixir
# config/config.exs
config :keen_auth_permissions,
  context_extra_fields: [:tenant_code, :session_id, :device_id]
```

Extra fields default to `nil`, can be set via `new/2` opts or `with_field/3`, and are automatically included in `to_context_map/1`:

```elixir
alias KeenAuthPermissions.RequestContext

# Pass extra fields when creating context
ctx = RequestContext.new(user,
  ip: "10.0.0.1",
  tenant_code: "acme",
  session_id: "sess-789"
)

# Or set them later
ctx = RequestContext.with_field(ctx, :device_id, "dev-001")

# Serialize for the JSONB parameter (used internally by facade modules)
RequestContext.to_context_map(ctx)
# => %{"ip" => "10.0.0.1", "request_id" => "req-123",
#       "tenant_code" => "acme", "session_id" => "sess-789", "device_id" => "dev-001"}
```

> **Note:** `request_id` is a built-in field (not an extra field). It is passed as the `correlation_id`
> parameter on every stored procedure call, and also included in `to_context_map/1` for the JSONB parameter.

## Application Setup

On application start, ensure required seed data exists. This is idempotent and safe to run on every boot:

```elixir
defmodule MyApp.Application do
  use Application
  require Logger

  def start(_type, _args) do
    children = [
      MyApp.Repo,
      {Phoenix.PubSub, name: MyApp.PubSub},
      # Permissions full_code <-> short_code cache
      KeenAuthPermissions.PermissionsMap,
      # PostgreSQL LISTEN/NOTIFY -> SSE bridge (optional)
      KeenAuthPermissions.PgListener,
      MyAppWeb.Endpoint
    ]

    result = Supervisor.start_link(children, strategy: :one_for_one)

    # Ensure seed data after supervisor starts
    ensure_providers()
    ensure_token_types()
    ensure_group_mappings()

    result
  end

  defp ensure_providers do
    db = KeenAuthPermissions.DbContext.get_global_db_context()

    # {code, name, allows_group_mapping, allows_group_sync}
    providers = [
      {"email", "Email", false, false},
      {"entra", "Microsoft Entra ID", true, true}
    ]

    for {code, name, mapping, sync} <- providers do
      case db.auth_ensure_provider("system", 1, "app-startup", code, name, true, mapping, sync) do
        {:ok, [%{is_new: true}]} -> Logger.info("Created provider: #{code}")
        {:ok, [%{is_new: false}]} -> :ok
        {:error, reason} -> Logger.warning("Failed to ensure provider '#{code}': #{inspect(reason)}")
      end
    end
  end

  defp ensure_token_types do
    alias KeenAuthPermissions.{TokenTypes, RequestContext}
    ctx = RequestContext.system_ctx()

    # 86400 seconds = 24 hours, tenant_id 1
    case TokenTypes.ensure_exists(ctx, "email_confirmation", 86400, 1) do
      {:ok, :exists} -> :ok
      {:ok, _created} -> Logger.info("Created token type: email_confirmation")
      {:error, reason} -> Logger.warning("Failed to ensure token type: #{inspect(reason)}")
    end
  end

  defp ensure_group_mappings do
    db = KeenAuthPermissions.DbContext.get_global_db_context()

    # Map external provider roles to user groups for SSO
    mappings = [
      %{group_code: "full_admins", provider: "entra", role: "Admins.FullAdmin"}
    ]

    for m <- mappings do
      case db.auth_ensure_user_group_mapping("system", 1, "app-startup", m.group_code, m.provider, m.role) do
        {:ok, _} -> :ok
        {:error, reason} -> Logger.warning("Failed to ensure group mapping: #{inspect(reason)}")
      end
    end
  end
end
```

## Router Pipelines

Set up three authentication pipelines in your Phoenix router.

> **Note:** The path prefixes (e.g., `/auth`, `/auth/email`) are just standard Phoenix `scope` blocks — you can change them to any path that fits your application (e.g., `/identity`, `/api/v1/auth`).

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router

  # KeenAuth setup — stores config in conn + auth session cookie
  pipeline :authentication do
    plug KeenAuth.Plug, otp_app: :my_app
    plug KeenAuth.Plug.AuthSession, secure: false, same_site: "Lax"
  end

  # Optional auth — fetch user if logged in, don't require it
  pipeline :maybe_auth do
    plug KeenAuth.Plug.FetchUser
    plug KeenAuthPermissions.Plug.RevalidateSession,
      on_invalid: &KeenAuthPermissions.Plug.RevalidateSession.clear_user/2
  end

  # Required auth — redirect to login if not authenticated
  pipeline :require_auth do
    plug KeenAuth.Plug.FetchUser
    plug KeenAuthPermissions.Plug.RevalidateSession
    plug KeenAuth.Plug.RequireAuthenticated, redirect: "/login"
  end

  # Public pages (show user info if logged in)
  scope "/", MyAppWeb do
    pipe_through [:browser, :authentication, :maybe_auth]
    get "/", PageController, :home
  end

  # Login/registration pages
  scope "/", MyAppWeb do
    pipe_through [:browser, :authentication]
    get "/login", PageController, :login
    post "/register", PageController, :create_registration
  end

  # Email auth routes (with CSRF)
  scope "/auth/email" do
    pipe_through [:browser, :authentication]
    post "/new", KeenAuth.EmailAuthenticationController, :new
  end

  # OAuth routes (no CSRF — callbacks come from external providers)
  scope "/auth" do
    pipe_through [:browser_no_csrf, :authentication]
    get "/:provider/new", KeenAuth.AuthenticationController, :new
    get "/:provider/callback", KeenAuth.AuthenticationController, :callback
    post "/:provider/callback", KeenAuth.AuthenticationController, :callback
  end

  # Protected pages
  scope "/", MyAppWeb do
    pipe_through [:browser, :authentication, :require_auth]
    get "/dashboard", PageController, :dashboard
    live "/users", UsersLive
  end
end
```

## OAuth / External Provider Authentication

This library handles the **database side** of OAuth authentication — registering providers, storing user identities, syncing groups/roles from the provider, and tracking login events. The actual OAuth flow (redirects, token exchange, user info mapping) is handled by [keen_auth](https://hexdocs.pm/keen_auth/readme.html). See the keen_auth documentation for configuring OAuth strategies (Azure AD/Entra, Google, etc.).

### Registering providers

Each OAuth provider must be registered in the database before users can authenticate through it. The recommended approach is to call `auth.ensure_provider` on every application start — it's idempotent (creates the provider if missing, returns the existing one otherwise):

```elixir
# In your Application.start/2 or a startup task
db = KeenAuthPermissions.DbContext.get_global_db_context()

for {code, name} <- [{"email", "Email"}, {"entra", "Microsoft Entra ID"}] do
  case db.auth_ensure_provider("system", 1, "app-startup", code, name, true, false, false) do
    {:ok, [%{is_new: true}]} -> Logger.info("Created provider: #{code}")
    {:ok, [%{is_new: false}]} -> :ok
    {:error, reason} -> Logger.error("Failed to ensure provider #{code}: #{inspect(reason)}")
  end
end
```

For manual provider management, use the facade functions:

```elixir
alias KeenAuthPermissions.Auth

ctx = KeenAuthPermissions.RequestContext.system_ctx()

# Create a provider (fails if already exists)
Auth.create_provider(ctx, "entra", "Microsoft Entra ID", true)

# Create with group mapping/sync support
Auth.create_provider(ctx, "entra", "Microsoft Entra ID", true, true, true)

# List providers with optional filters
Auth.list_providers(ctx)
Auth.list_providers(ctx, is_active: true, allows_group_mapping: true)

# Manage providers
Auth.enable_provider(ctx, "entra")
Auth.disable_provider(ctx, "entra")

# Validate provider capabilities
Auth.validate_provider_allows_group_mapping("entra")
Auth.validate_provider_allows_group_sync("entra")
```

### Processor

When a user authenticates via an OAuth provider, keen_auth calls a **processor** module that bridges the OAuth response to the permissions model. This library ships with a built-in Azure AD/Entra processor (`KeenAuthPermissions.Processor.AzureAD`) that:

1. Calls `auth.ensure_user_from_provider` — creates or updates the user identity linked to the provider
2. Calls `auth.ensure_groups_and_permissions` — syncs the user's provider groups/roles and returns their permissions
3. Returns a `%KeenAuthPermissions.User{}` struct with populated `groups` and `permissions`

```elixir
# config/config.exs — configure keen_auth to use the processor
config :keen_auth, :processors, %{
  entra: KeenAuthPermissions.Processor.AzureAD
}
```

For custom OAuth providers, implement the `KeenAuth.Processor` behaviour and use the same database functions. See the `KeenAuthPermissions.Processor.AzureAD` source for a complete example.

### Provider management functions

- `Auth.create_provider/4..6` — register a new provider (optional `allows_group_mapping`, `allows_group_sync`)
- `Auth.update_provider/5..7` — update provider name/status/capabilities
- `Auth.list_providers/1..2` — list providers with optional filters
- `Auth.enable_provider/2` / `Auth.disable_provider/2` — toggle provider
- `Auth.delete_provider/2` — remove a provider
- `Auth.validate_provider_is_active/1` — check if provider is active
- `Auth.validate_provider_allows_group_mapping/1` — check if provider supports group mapping
- `Auth.validate_provider_allows_group_sync/1` — check if provider supports group sync
- `Auth.list_provider_users/2` — list users from a provider

## Email Authentication

The library includes built-in email/password authentication. By default it uses `Pbkdf2` for password hashing, but you can configure a different algorithm:

```elixir
# config/config.exs
config :keen_auth_permissions,
  password_hasher: Argon2  # any module that implements hash_pwd_salt/1, verify_pass/2, no_user_verify/0
```

If not configured, `Pbkdf2` is used (pure Elixir, no C compiler required).

The convenience functions `Auth.authenticate_by_email/3` and `Auth.register_user/3` use this config internally. If you need full control over hashing, use the lower-level `Auth.register/5` and pass your own pre-hashed password.

```elixir
alias KeenAuthPermissions.Auth

# Email authentication
case Auth.authenticate_by_email("user@example.com", "password") do
  {:ok, user} -> # Authentication successful
  {:error, :invalid_credentials} -> # Invalid email or password
end

# Register a new user
Auth.register_user("user@example.com", "password", "Display Name")
```

To integrate with keen_auth, implement the `KeenAuth.EmailAuthenticationHandler` behaviour and a processor:

```elixir
# Email handler — validates credentials
defmodule MyApp.Auth.EmailHandler do
  @behaviour KeenAuth.EmailAuthenticationHandler

  alias KeenAuthPermissions.Auth

  @impl true
  def authenticate(_conn, %{"email" => email, "password" => password}) do
    case Auth.authenticate_by_email(email, password) do
      {:ok, user} ->
        {:ok, %{"sub" => to_string(user.user_id), "email" => user.email,
                 "name" => user.display_name, "preferred_username" => user.username}}
      {:error, _} ->
        {:error, :invalid_credentials}
    end
  end

  @impl true
  def handle_authenticated(conn, _user), do: conn

  @impl true
  def handle_unauthenticated(conn, params, _error) do
    conn
    |> Phoenix.Controller.put_flash(:error, "Invalid email or password")
    |> Phoenix.Controller.redirect(to: params["redirect_to"] || "/login")
  end
end
```

```elixir
# Email processor — loads user from DB after authentication
defmodule MyApp.Auth.Processor do
  @behaviour KeenAuth.Processor

  alias KeenAuthPermissions.{DbContext, User}

  @impl true
  def process(conn, :email, mapped_user, response) do
    db = DbContext.current_db_context!(conn)
    user_id = mapped_user |> Map.get("sub") |> String.to_integer()

    {:ok, [db_user]} = db.auth_get_user_by_id(user_id, nil)
    {groups, permissions} = load_groups_and_permissions(db, db_user.user_id)

    user = %User{
      user_id: db_user.user_id, code: db_user.code, uuid: db_user.uuid,
      username: db_user.username, email: db_user.email,
      display_name: db_user.display_name,
      groups: groups, permissions: permissions
    }

    {:ok, conn, user, response}
  end

  @impl true
  def sign_out(conn, _provider, params) do
    storage = KeenAuth.Storage.current_storage(conn)
    conn |> storage.delete() |> Phoenix.Controller.redirect(to: params["redirect_to"] || "/")
  end

  defp load_groups_and_permissions(db, user_id) do
    case db.auth_ensure_groups_and_permissions("system", 1, "email-login", user_id, "email", [], []) do
      {:ok, [%{groups: groups, short_code_permissions: perms}]} -> {groups, perms}
      _ -> {[], []}
    end
  end
end
```

```elixir
# config/config.exs — wire it up in keen_auth strategies
config :my_app, :keen_auth,
  strategies: [
    email: [
      label: "Email",
      authentication_handler: MyApp.Auth.EmailHandler,
      mapper: KeenAuth.Mapper.Default,
      processor: MyApp.Auth.Processor
    ]
  ]
```

## Request Context

Use `RequestContext` to pass user and request metadata through your application. All context fields (ip, user_agent, origin, request_id, language_code, plus any configured extra fields) are serialized into a single JSONB map for stored procedures:

```elixir
alias KeenAuthPermissions.RequestContext

# Create context from authenticated user
ctx = RequestContext.new(user,
  request_id: "req-123",
  ip: "192.168.1.1",
  user_agent: "Mozilla/5.0...",
  origin: "https://example.com"
)

# Set fields on an existing context
ctx = RequestContext.with_field(ctx, :language_code, "cs")

# System context for background jobs
ctx = RequestContext.system_ctx()

# Serialize context metadata for JSONB (used internally by facades)
RequestContext.to_context_map(ctx)
# => %{"ip" => "192.168.1.1", "request_id" => "req-123", "user_agent" => "Mozilla/5.0...", ...}
```

## Service Accounts

For automated operations, use purpose-specific service accounts instead of the generic system account:

```elixir
alias KeenAuthPermissions.RequestContext

# Service account for registration operations
ctx = RequestContext.service_ctx(:registrator)

# Service account for authentication operations
ctx = RequestContext.service_ctx(:authenticator)

# Built-in accounts: :system, :registrator, :authenticator,
#   :token_manager, :api_gateway, :group_syncer, :data_processor
```

You can also define custom service accounts via config:

```elixir
# config/config.exs
config :keen_auth_permissions, :service_accounts, %{
  my_importer: %{user_id: 900, username: "svc_importer", display_name: "Importer", email: "svc_importer@localhost"}
}

# then use it like any built-in account
ctx = RequestContext.service_ctx(:my_importer)
```

## Permission Helpers

```elixir
alias KeenAuthPermissions.PermissionHelpers

# Boolean checks
PermissionHelpers.has_any?(user, ["admin.read", "super.admin"])
PermissionHelpers.has_all?(user, ["users.read", "users.write"])
PermissionHelpers.in_any_group?(user, ["admins", "moderators"])

# Result-based checks (for with blocks)
with {:ok, :authorized} <- PermissionHelpers.require_any(ctx, ["admin.read"]),
     {:ok, data} <- fetch_data(ctx) do
  {:ok, data}
end

# Function wrappers
PermissionHelpers.with_permission(ctx, ["admin.delete"], fn ->
  delete_record(id)
end)
```

## Resource Access (ACL)

Resource-level authorization layered on top of RBAC. While permissions control **what actions** a user can perform, resource access controls **which specific resources** they can act on.

### Resource types

Register resource types to define what kinds of resources exist. Types support hierarchy (e.g., `project` -> `project.documents`):

```elixir
alias KeenAuthPermissions.ResourceAccess

ctx = RequestContext.new(user)

# Create a resource type (last arg is language_code for the stored title)
ResourceAccess.create_resource_type(ctx, "project", "Project", nil, nil, nil, "en")
ResourceAccess.create_resource_type(ctx, "project.documents", "Documents", "project", nil, nil, "en")

# List resource types (optionally filter by source, parent_code, active_only)
{:ok, types} = ResourceAccess.list_resource_types()
{:ok, types} = ResourceAccess.list_resource_types("my_app", nil, true)
```

Each resource type has a `full_title` field that is automatically generated from the hierarchy (e.g., "Project > Documents").

### Granting and revoking access

```elixir
# Grant "read" and "write" flags to a user on project 42
ResourceAccess.grant(ctx, "project", 42, user_id, nil, ["read", "write"], tenant_id)
# Underlying SP is now `auth.assign_resource_access` — the facade name is kept for API stability.

# Grant "read" to a group
ResourceAccess.grant(ctx, "project", 42, nil, group_id, ["read"], tenant_id)

# Deny "delete" for a specific user (overrides all group grants)
ResourceAccess.deny(ctx, "project", 42, user_id, ["delete"], tenant_id)

# Revoke specific flags
ResourceAccess.revoke(ctx, "project", 42, user_id, nil, ["write"], tenant_id)

# Revoke all access on a resource (cleanup on resource delete)
ResourceAccess.revoke_all(ctx, "project", 42, tenant_id)
```

### Access flag catalog

Access flags (`read`, `write`, `delete`, ...) are application-defined. Manage the catalog and the per-resource-type attachment set via:

```elixir
# List the global catalog of access-flag definitions (code + title + description)
{:ok, flags} = ResourceAccess.list_access_flags()
{:ok, flags} = ResourceAccess.list_access_flags("my_app", "en")

# Idempotently upsert a batch of access-flag definitions (safe on every bootstrap)
flags = [
  %{"code" => "read",  "title" => "Read",   "description" => "..."},
  %{"code" => "write", "title" => "Write",  "description" => "..."}
]
ResourceAccess.ensure_access_flags(ctx, flags, "my_app", tenant_id, "en")

# Sync the set of access flags attached to a given resource type
# (attaches anything new, detaches anything missing from the list)
ResourceAccess.ensure_resource_type_flags(ctx, "project", ["read", "write", "delete"], tenant_id)
```

### Checking access

```elixir
# Single check
{:ok, true} = ResourceAccess.has_access?(ctx, "project", 42, "read", tenant_id)

# Bulk filter — returns only the IDs the user can access
{:ok, accessible_ids} = ResourceAccess.filter_accessible(ctx, "project", [1, 2, 3, 4, 5], "read", tenant_id)
```

### Querying

```elixir
# Get current user's effective flags on a resource
{:ok, flags} = ResourceAccess.get_flags(ctx, "project", 42, tenant_id)

# Get all grants/denies on a resource (admin view)
{:ok, grants} = ResourceAccess.get_grants(ctx, "project", 42, tenant_id)

# Hierarchical access matrix
{:ok, matrix} = ResourceAccess.get_matrix(ctx, "project", 42, tenant_id)

# List resources a user can access
{:ok, resources} = ResourceAccess.get_user_resources(ctx, target_user_id, "project", "read", tenant_id)
```

### Access check algorithm (priority order)

1. System user (id=1) — always allowed
2. Tenant owner — always allowed
3. User-level deny — blocked, overrides everything
4. User-level grant — allowed
5. Group-level grant (via active group membership) — allowed
6. No matching row — denied

## Blacklist

Manage blacklisted users and identities:

```elixir
alias KeenAuthPermissions.Blacklist

ctx = RequestContext.new(user)

# Create a blacklist entry
Blacklist.create(ctx, "bad_user", "entra", "uid-123", "oid-456", "abuse", "Repeated violations", tenant_id)

# Search blacklist (with pagination)
{:ok, entries} = Blacklist.search(ctx, "bad_user", nil, 1, 20, tenant_id)

# Check if blacklisted (no auth context needed)
{:ok, true} = Blacklist.is_blacklisted?("bad_user", "entra", "uid-123", "oid-456")

# Delete a blacklist entry
Blacklist.delete(ctx, blacklist_id, tenant_id)
```

## Identifier Resolver

When you don't want to expose internal integer IDs (user_id, tenant_id, group_id) to clients, use the resolver to translate UUIDs or codes:

```elixir
alias KeenAuthPermissions.Resolver

# Resolve a user by UUID, code, or even stringified ID
{:ok, user_id} = Resolver.user("a1b2c3d4-e5f6-...")
{:ok, user_id} = Resolver.user("john.doe")
{:ok, user_id} = Resolver.user("42")

# Resolve a tenant
{:ok, tenant_id} = Resolver.tenant("acme")
{:ok, tenant_id} = Resolver.tenant("550e8400-...")

# Resolve a group within a tenant
{:ok, group_id} = Resolver.group("owners", tenant_id)
{:ok, group_id} = Resolver.group("17", tenant_id)
```

All functions return `{:ok, id}` or `{:error, :not_found}` (with specific DB error codes: 33020, 34003, 33021).

## Multi-Factor Authentication (MFA)

Full MFA lifecycle — enrollment, challenge/verify, policy management, and recovery codes:

```elixir
alias KeenAuthPermissions.Mfa

ctx = RequestContext.new(user)

# Enroll a user in TOTP MFA
{:ok, enrollment} = Mfa.enroll(ctx, target_user_id, "totp", tenant_id)
# => %{secret: "...", recovery_codes: ["...", ...]}

# Confirm enrollment after user verifies initial code
Mfa.confirm_enrollment(ctx, target_user_id, "totp", tenant_id)

# Create a challenge for login verification
{:ok, challenge} = Mfa.create_challenge(ctx, target_user_id, tenant_id)

# Verify the challenge
Mfa.verify_challenge(ctx, challenge.token_uid, "123456", false, tenant_id)

# Check MFA status
{:ok, status} = Mfa.get_status(ctx, target_user_id)

# Reset MFA (generates new recovery codes)
{:ok, result} = Mfa.reset(ctx, target_user_id, "totp")
```

### MFA Policies

Policies can be set at tenant, group, or user level:

```elixir
# Require MFA for all users in a tenant
Mfa.create_policy(ctx, tenant_id, nil, nil, true)

# Require MFA for a specific group
Mfa.create_policy(ctx, nil, group_id, nil, true)

# Check if MFA is required for a user
{:ok, true} = Mfa.is_required?(ctx, target_user_id, tenant_id)

# List policies
{:ok, policies} = Mfa.get_policies(ctx, tenant_id, nil, nil)
```

## Bulk Ensure Operations

Idempotent upsert operations for seeding or syncing configuration on app startup. All accept JSON-encoded lists and support source tracking:

```elixir
alias KeenAuthPermissions.{Permissions, PermSets, UserGroups, ResourceAccess}

ctx = RequestContext.system_ctx()

# Ensure permissions exist (creates missing, updates existing)
permissions_json = Jason.encode!([
  %{code: "users.read", title: "Read Users"},
  %{code: "users.write", title: "Write Users"}
])
Permissions.ensure(ctx, permissions_json, true, "my_app")

# Ensure permission sets
perm_sets_json = Jason.encode!([
  %{code: "admin_set", title: "Admin Set", permissions: ["users.read", "users.write"]}
])
PermSets.ensure(ctx, perm_sets_json, true, "my_app", tenant_id)
```

> Titles are stored as translations keyed by the `code` column; `PermSets.update/5` updates `is_assignable` and writes a new title translation but does not mutate `code`.

```elixir

# Ensure user groups
groups_json = Jason.encode!([
  %{code: "admins", title: "Administrators"}
])
UserGroups.ensure(ctx, groups_json, true, "my_app", tenant_id)

# Ensure user group mappings (provider role → internal group)
mappings_json = Jason.encode!([
  %{group_code: "admins", provider_code: "entra", mapped_role: "Admins.FullAdmin"}
])
UserGroups.ensure_mappings(ctx, mappings_json, true, tenant_id)

# Ensure resource types
types_json = Jason.encode!([
  %{code: "project", title: "Project"},
  %{code: "project.docs", title: "Documents", parent_code: "project"}
])
ResourceAccess.ensure_resource_types(ctx, types_json, true, "my_app")
```

The `is_final_state` parameter (second-to-last arg) controls whether items not in the list should be deactivated — useful for keeping the database in sync with a canonical source.

## Invitations

A generic invitation system for onboarding users to tenants, groups, permission sets, and resource-access-controlled entities. Invitations carry ordered, typed actions that execute across lifecycle phases (`on_create`, `on_accept`, `on_reject`, `on_expired`).

### Creating invitations

```elixir
alias KeenAuthPermissions.Invitations

ctx = RequestContext.new(user)

# Create with inline actions
{:ok, invitation} = Invitations.create(ctx, tenant_id, "newuser@example.com", [
  %{action_type_code: "add_tenant_user", phase_code: "on_accept", executor_code: "database",
    sequence: 1, is_required: true, payload: %{tenant_id: tenant_id}},
  %{action_type_code: "send_welcome_email", phase_code: "on_accept", executor_code: "backend",
    sequence: 2, is_required: false, payload: %{template: "welcome"}}
], "Welcome to our platform!", ~U[2026-04-01 00:00:00Z])
# => %{invitation_id: 1, uuid: "...", on_create_actions: [...]}

# Create from a reusable template
{:ok, invitation} = Invitations.create_from_template(ctx, tenant_id, "onboarding",
  "newuser@example.com", "Welcome!", ~U[2026-04-01 00:00:00Z])
```

The `on_create_actions` in the result are backend/external actions your app needs to execute immediately (e.g., sending an email or SMS).

### Accepting and rejecting

```elixir
# Accept — executes DB actions automatically, returns backend actions for your app
{:ok, backend_actions} = Invitations.accept(ctx, invitation_id, target_user_id)

# Reject
{:ok, backend_actions} = Invitations.reject(ctx, invitation_id)

# Revoke (by inviter or admin)
:ok = Invitations.revoke(ctx, invitation_id)
```

### Querying

```elixir
# List invitations (with optional filters)
{:ok, invitations} = Invitations.list(ctx, tenant_id)
{:ok, pending} = Invitations.list(ctx, tenant_id, "pending")
{:ok, for_user} = Invitations.list(ctx, tenant_id, nil, "user@example.com")

# Get actions for an invitation
{:ok, actions} = Invitations.get_actions(ctx, invitation_id)
```

### Templates

Templates define reusable invitation configurations:

```elixir
# Create a template
{:ok, template_id} = Invitations.create_template(ctx, tenant_id, "onboarding", "Onboarding",
  "Standard onboarding invitation", "Welcome to our platform!",
  [%{action_type_code: "add_tenant_user", phase_code: "on_accept", executor_code: "database",
     sequence: 1, is_required: true, payload: %{tenant_id: tenant_id}}])

# Update template
:ok = Invitations.update_template(ctx, template_id, "Updated Title", "New description")

# Delete template
:ok = Invitations.delete_template(ctx, template_id)
```

## Internationalization

The `KeenAuthPermissions.Translations` facade covers the full i18n domain — translations CRUD plus a language catalog with frontend / backend / communication capability flags. Titles for permissions, perm sets, resource types, and roles are stored as translations keyed by `code` and a `language_code`.

Stored procedures that accept a `language_code` parameter honor the `RequestContext.language_code` plumbing, so once you set it on the request context the correct language is picked up automatically:

```elixir
ctx = RequestContext.new(user) |> RequestContext.with_field(:language_code, "cs")
```

## Facade Modules

The library provides high-level facade modules for common operations:

- `KeenAuthPermissions.Auth` - Authentication, registration, tokens
- `KeenAuthPermissions.Users` - User management, search, provider lookup, ensure user info; `Users.assign_default_groups/3` and `Users.add_to_default_groups/3` (sibling wrapper) assign all active default groups to a user
- `KeenAuthPermissions.UserGroups` - Group management, membership, bulk ensure groups & mappings
- `KeenAuthPermissions.Permissions` - Permission CRUD, search, assignment, bulk ensure
- `KeenAuthPermissions.Tenants` - Multi-tenant operations
- `KeenAuthPermissions.PermSets` - Permission set management, bulk ensure
- `KeenAuthPermissions.ApiKeys` - API key management
- `KeenAuthPermissions.ResourceAccess` - Resource-level ACL (grant, deny, revoke, check, resource types, bulk ensure)
- `KeenAuthPermissions.Blacklist` - User/identity blacklist management (create, delete, search, check)
- `KeenAuthPermissions.Resolver` - Translate UUIDs/codes to internal IDs (user, tenant, group)
- `KeenAuthPermissions.Mfa` - Multi-factor authentication (enroll, challenge, verify, policies, recovery codes)
- `KeenAuthPermissions.Invitations` - Phase-based invitations with templates, actions, and lifecycle management
- `KeenAuthPermissions.Audit` - Audit trail + security events
- `KeenAuthPermissions.ResourceRoles` - Resource-role CRUD, assign/revoke roles on resources
- `KeenAuthPermissions.Journal` - Application-created audit journal entries + search + formatted rendering
- `KeenAuthPermissions.Providers` - Provider and group-mapping upsert helpers for bootstrap
- `KeenAuthPermissions.Events` - Application-owned event categories, codes, and message templates
- `KeenAuthPermissions.Translations` - Translations and language-catalog management (i18n)
- `KeenAuthPermissions.SysParams` - Database-level system parameters (setup only)
- `KeenAuthPermissions.PermissionsMap` - In-memory permission code translation (GenServer)

## Session Revalidation

The `RevalidateSession` plug (used in the router pipelines above) periodically checks the database to ensure the session user is still valid (not deleted, disabled, or locked).

Options: `:interval` (seconds, default 300), `:redirect` (default `"/login"`), `:on_invalid` (custom callback), `:validate_fn` (custom validation function).

**Note:** `current_user` must be a `%KeenAuthPermissions.User{}` struct. Processors that return plain maps will cause revalidation to be skipped.

## LiveView Integration

In LiveViews, build a `RequestContext` from the session user and subscribe to SSE events for real-time updates:

```elixir
defmodule MyAppWeb.UsersLive do
  use MyAppWeb, :live_view

  alias KeenAuthPermissions.{Users, RequestContext}
  alias MyAppWeb.AuthEventHandler

  @impl true
  def mount(_params, session, socket) do
    user = session["current_user"]

    if connected?(socket) do
      # Subscribe to auth events for this user
      Phoenix.PubSub.subscribe(MyApp.PubSub, "keen_auth:user:#{user.user_id}")
    end

    ctx = RequestContext.new(user)

    {:ok,
     socket
     |> assign(user: user, ctx: ctx, users: [], loading: true)
     |> load_users()}
  end

  # Handle SSE auth events (permission changes, lockouts, etc.)
  @impl true
  def handle_info({:sse_event, event, payload}, socket) do
    {:noreply, AuthEventHandler.handle_sse_event(socket, event, payload, &load_users/1)}
  end

  defp load_users(socket) do
    case Users.search(socket.assigns.ctx, nil, nil, nil, nil, 1, 50, 1) do
      {:ok, users} -> assign(socket, users: users, loading: false)
      _ -> assign(socket, users: [], loading: false)
    end
  end
end
```

The `AuthEventHandler` classifies SSE events using `KeenAuthPermissions.EventClassification` into tiers:

- **`:hard`** (user disabled/deleted/locked) — block the UI, force session clear
- **`:medium`** (permissions/groups changed) — show a warning banner
- **`:soft`** (data changes) — silently reload data

See [docs/sse-event-handling.md](docs/sse-event-handling.md) for the full event classification documentation.

## System Parameters

The [postgresql-permissions-model](https://github.com/KeenMate/postgresql-permissions-model) uses `auth.sys_param` entries to control database-level behavior. These are set once during deployment and rarely changed. Use `KeenAuthPermissions.SysParams` to read/update them (update requires user_id 1).

### Seeded parameters

| group_code   | code             | default    | type            | description                                                                                              |
|--------------|------------------|------------|-----------------|----------------------------------------------------------------------------------------------------------|
| `journal`    | `level`          | `"update"` | text            | Journal logging verbosity. `"all"` = log everything including reads, `"update"` = state-changing only, `"none"` = disable |
| `journal`    | `retention_days` | `"365"`    | text (cast int) | Days of journal entries to keep. Used by `unsecure.purge_journal()`                                      |
| `journal`    | `storage_mode`   | `"local"`  | text            | Where journal data goes. `"local"` = INSERT only, `"notify"` = pg_notify only, `"both"` = INSERT + pg_notify |
| `user_event` | `retention_days` | `"365"`    | text (cast int) | Days of user events to keep. Used by `unsecure.purge_user_events()`                                      |
| `user_event` | `storage_mode`   | `"local"`  | text            | Where user event data goes. Same modes as journal                                                        |
| `partition`  | `months_ahead`   | `3`        | number          | Future monthly partitions to pre-create for journal and user_event tables. Used by `unsecure.ensure_audit_partitions()` |

### Not seeded but read by code

| group_code | code                      | default                    | type   | description                                                              |
|------------|---------------------------|----------------------------|--------|--------------------------------------------------------------------------|
| `auth`     | `perm_cache_timeout_in_s` | `300` (hardcoded fallback) | number | Permission cache TTL in seconds. Used by `unsecure.recalculate_user_permissions()` |

```elixir
# Read a parameter
{:ok, param} = KeenAuthPermissions.SysParams.get("journal", "level")
param.text_value  # => "update"

# Unknown parameters return {:error, :not_found}
{:error, :not_found} = KeenAuthPermissions.SysParams.get("unknown", "code")

# Update a parameter (only user_id 1 can do this)
KeenAuthPermissions.SysParams.update("journal", "level", "all")
KeenAuthPermissions.SysParams.update("partition", "months_ahead", nil, 6)
```

## Database Requirements

This library requires the [postgresql-permissions-model](https://github.com/KeenMate/postgresql-permissions-model) database schema to be installed.

## Code Generation

The library includes a code generation system (`db-gen`) that automatically creates Elixir modules from PostgreSQL stored procedures. See `db-gen/README.md` for details.

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

```bash
mix docs
```

## License

See LICENSE file for details.
