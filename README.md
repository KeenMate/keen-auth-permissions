# KeenAuthPermissions

A comprehensive Elixir library for authentication and authorization, extending [keen_auth](https://github.com/KeenMate/keen-auth) with PostgreSQL-backed permission management.

## Features

- **Database-First Architecture**: Business logic implemented as PostgreSQL stored procedures with Elixir wrappers
- **Multi-Tenant Support**: Full tenant isolation for permissions, groups, and users
- **User Management**: Registration, authentication, user profiles, and identity management
- **Group Management**: User groups with membership and permission inheritance
- **Permission System**: Hierarchical permissions with short codes and permission sets
- **API Key Management**: Create and manage API keys with granular permissions
- **Token Management**: Secure token creation, validation, and lifecycle management
- **Event Logging**: User events with IP, user agent, and origin tracking
- **Email Authentication**: Built-in support for email/password authentication with Pbkdf2 hashing

## Installation

Add `keen_auth_permissions` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:keen_auth_permissions, git: "https://github.com/KeenMate/keen-auth-permissions.git"}
  ]
end
```

## Configuration

Configure the database context in your application:

```elixir
# config/config.exs
config :keen_auth_permissions,
  db_context: MyApp.Database
```

Create a database module in your application:

```elixir
defmodule MyApp.Database do
  use KeenAuthPermissions.Database, repo: MyApp.Repo
end
```

## Usage

### Authentication

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

### Permission Helpers (In-Memory Checking)

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

### Request Context

Use `RequestContext` to pass user and request metadata through your application:

```elixir
alias KeenAuthPermissions.RequestContext

# Create context from authenticated user
ctx = RequestContext.new(user,
  request_id: "req-123",
  ip: "192.168.1.1",
  user_agent: "Mozilla/5.0...",
  origin: "https://example.com"
)

# System context for background jobs
ctx = RequestContext.system_ctx()
```

### Facade Modules

The library provides high-level facade modules for common operations:

- `KeenAuthPermissions.Auth` - Authentication, registration, tokens
- `KeenAuthPermissions.Users` - User management and search
- `KeenAuthPermissions.UserGroups` - Group management and membership
- `KeenAuthPermissions.Tenants` - Multi-tenant operations
- `KeenAuthPermissions.PermSets` - Permission set management
- `KeenAuthPermissions.ApiKeys` - API key management

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
