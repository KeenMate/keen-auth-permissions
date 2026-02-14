import Config

# Test database configuration
# Uses the same database as development but with test-specific settings
config :keen_auth_permissions, KeenAuthPermissions.TestRepo,
  username: "ovalenta",
  password: "Nocnijezdec!",
  hostname: "db-01.km8.local",
  database: "postgresql_permissionmodel",
  port: 5432,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  after_connect: {Postgrex, :query!, ["SET search_path TO auth,helpers,ext,public,const", []]}

# Configure the db_context for tests
config :keen_auth_permissions, :db_context, KeenAuthPermissions.TestDatabase

# Reduce log noise during tests
config :logger, level: :warning
