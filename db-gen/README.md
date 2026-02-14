# Database Code Generation for KeenAuthPermissions

This directory contains Go templates for generating Elixir code from PostgreSQL stored procedures in the `auth` schema.

## Files

- **`dbcontext.gotmpl`** - Template for the database context module with all stored procedure wrappers
- **`model.gotmpl`** - Template for Elixir struct models representing return types
- **`parser.gotmpl`** - Template for parser modules that convert Postgrex results to structs
- **`routines.json`** - Cached metadata from database introspection

## Usage

### Fetch latest routines from database
```bash
./db-gen-win.exe routines
```

### Generate Elixir code
```bash
./db-gen-win.exe generate
```

## Generated Structure

The generator creates:
- `lib/keen_auth_permissions/database/db_context.ex` - Main database context with ~130+ wrapper functions
- `lib/keen_auth_permissions/database/models/*.ex` - Model structs for each function's return type
- `lib/keen_auth_permissions/database/parsers/*.ex` - Parsers to convert Postgrex results to models

## Integration

Use the generated database context in your application:

```elixir
defmodule MyApp.Database do
  use KeenAuthPermissions.Database, repo: MyApp.Repo
end

# Then call functions
MyApp.Database.auth_get_user_by_id(user_id, tenant_id)
```

## Configuration

The `db-gen.json` in the project root configures:
- Database connection
- Output paths
- Type mappings (PostgreSQL → Elixir)
- Schema to generate from (`auth`)

Functions with special parameter types (like `ensure_groups_and_permissions`) have custom mappings configured in the `Functions` section.
