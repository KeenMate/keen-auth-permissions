import Config

# Configure your database
config :keen_auth_permissions, Mix.Tasks.Generate.Repo,
  username: "keen_auth_permissions_generator_dev",
  password: "keen_auth_permissions_generator_dev",
  hostname: "localhost",
  database: "keen_auth_permissions_generator_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
