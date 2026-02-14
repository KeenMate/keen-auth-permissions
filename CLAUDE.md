# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Elixir library (`keen_auth_permissions`) that extends the base `keen_auth` library by providing comprehensive logic for permissions handling. The library is designed as a PostgreSQL-backed authentication and authorization system with stored procedures for data access.

## Commands

### Development Commands
- `mix deps.get` - Fetch dependencies
- `mix compile` - Compile the project
- `mix test` - Run tests
- `mix format` - Format code using the configured Elixir formatter
- `mix docs` - Generate documentation using ExDoc

### Database Setup
- Use `create-db.ps1` PowerShell script to set up the database

### Database Code Generation
- `db-gen-win.exe` - Windows executable for generating Elixir code from PostgreSQL stored procedures
- `db-gen-linux` - Linux executable for the same purpose
- Configuration and templates are located in `db-gen/` directory

## Architecture

### Core Design Principles
This library follows a database-first approach where business logic is implemented as PostgreSQL stored procedures in the `auth` schema. The Elixir code serves as a thin wrapper around these stored procedures.

### Key Components

#### 1. Database Layer (`lib/keen_auth_permissions/database/`)
- **Auto-generated Database Context** (`db_context.ex`): Contains ~170 auto-generated functions that call PostgreSQL stored procedures. Each function corresponds to a stored procedure in the `auth` schema.
- **Models** (`models/`): Data structures representing return types from stored procedures (e.g., `AuthCreateUserItem`, `AuthGetUserPermissionsItem`)
- **Parsers** (`parsers/`): Convert raw database results into structured Elixir data

#### 2. Provider Layer (`lib/keen_auth_permissions/providers/`)
- **AuthProvider**: Core authentication operations (login, registration, tokens)
- **UsersProvider**: User management and data operations
- **GroupsProvider**: User group management
- **PermissionsProvider**: Permission and authorization logic

#### 3. Manager Layer (`lib/keen_auth_permissions/managers/`)
- Higher-level business logic that combines multiple provider operations
- **UsersManager**: Complex user operations
- **GroupsManager**: Group management workflows
- **ManagerHelpers**: Shared utilities for managers

#### 4. Core Types
- **User** (`user.ex`): Main user struct with enforced keys for user data
- **Storage** (`storage.ex`): File/blob storage interface
- **Email** (`email.ex`): Email handling functionality
- **TenantResolver** (`tenant_resolver.ex`): Multi-tenancy support

### Database Integration
The library uses a macro-based approach where consuming applications include the database functionality:

```elixir
defmodule MyApp.Database do
  use KeenAuthPermissions.Database, repo: MyApp.Repo
end
```

This generates all the stored procedure wrapper functions in the consuming application's context.

### Multi-tenancy
The system is designed with multi-tenancy in mind - most operations require a `tenant_id` parameter to ensure data isolation between tenants.

### Error Handling
- Structured error handling through `KeenAuthPermissions.Error` modules
- Database errors are parsed and converted to application-specific error structures
- Common error types include permission denials, user not found, and validation failures

## Dependencies
- `keen_auth` (~> 0.2.2): Base authentication library
- `jason` (~> 1.3): JSON encoding/decoding
- `postgrex` (~> 0.16.4): PostgreSQL driver
- `ex_doc`: Documentation generation (dev only)

## Testing
- Test files are located in `test/`
- Main test file: `test/keen_auth_permissions_test.exs`
- Test helper: `test/test_helper.exs`

## Database Code Generation System

### Overview
This project includes a sophisticated code generation system for automatically creating Elixir code from PostgreSQL stored procedures. The system uses Go templates and database introspection to maintain the ~170 database wrapper functions.

### Configuration (`db-gen.json`)
The main configuration file specifies:
- **ConnectionString**: `"postgresql://postgresql_permissionmodel:Password3000!!@localhost:5432/postgresql_permissionmodel"`
- **OutputFolder**: `"./lib/keen_auth_permissions/database/"`
- **OutputNamespace**: `"KeenAuthPermissions.Database"`
- **Templates**: `DbContextTemplate`, `ModelTemplate`, `ParserTemplate` located in `db-gen/` directory
- **GeneratedFileCase**: `"snake_case"` - Output files use snake_case naming
- **Schema Focus**: Primarily the `auth` schema with `AllFunctions: true`

### Templates (`db-gen/` directory)
- **`dbcontext.gotmpl`**: Generates the main database context module with macro-based approach
- **`model.gotmpl`**: Creates Elixir struct models for stored procedure return types
- **`parser.gotmpl`**: Generates parser modules that convert Postgrex results to structs
- **`routines.json`**: Sample/cache file showing expected database metadata structure
- **`README.md`**: Comprehensive documentation of the generation system

### Generated Code Patterns
The templates produce code matching existing patterns:

```elixir
# Database Context Function
@spec auth_create_tenant(binary(), integer(), binary(), binary(), integer()) ::
        {:error, any()} | {:ok, [KeenAuthPermissions.Database.Models.AuthCreateTenantItem.t()]}
def auth_create_tenant(created_by, user_id, title, code, tenant_id) do
  Logger.debug("Calling stored procedure", procedure: "create_tenant")
  query("select * from auth.create_tenant($1, $2, $3, $4, $5)", [created_by, user_id, title, code, tenant_id])
  |> KeenAuthPermissions.Database.Parsers.AuthCreateTenantParser.parse_auth_create_tenant_result()
end

# Model Struct
defmodule KeenAuthPermissions.Database.Models.AuthCreateTenantItem do
  @fields [:created, :created_by, :modified, :modified_by, :tenant_id, :uuid, :title, :code, :is_removable, :is_assignable, :access_type_code]
  @enforce_keys @fields
  defstruct @fields
  @type t() :: %KeenAuthPermissions.Database.Models.AuthCreateTenantItem{}
end
```

### Type Mappings
PostgreSQL types are mapped to Elixir types:
- `text`, `varchar` → `String.t()`
- `int4`, `int8` → `integer()`
- `boolean` → `boolean()`
- `timestamptz` → `DateTime.t()`
- `uuid` → `String.t()`
- `_text` → `list(String.t())`

### Usage
The generation system works with executables (`db-gen-win.exe`, `db-gen-linux`) that:
1. Connect to PostgreSQL using the configuration
2. Introspect the `auth` schema for stored procedures
3. Generate metadata in JSON format
4. Process Go templates to create Elixir code
5. Output files to specified directories

## Code Conventions
- Auto-generated files are marked with "This code has been auto-generated" comments
- Database functions follow the pattern `auth_*` matching stored procedure names
- All database operations return `{:ok, result}` or `{:error, reason}` tuples
- Extensive logging of stored procedure calls for debugging
- Functions include comprehensive @spec type annotations
- Snake case naming throughout (Elixir standard)
- Macro-based integration via `use KeenAuthPermissions.Database, repo: MyApp.Repo`