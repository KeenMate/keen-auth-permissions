defmodule KeenAuthPermissions.TestRepo do
  @moduledoc """
  Test repository for database operations.

  This module wraps Postgrex to provide the `query/2` function expected by the
  `KeenAuthPermissions.Database` macro.
  """

  @doc """
  Starts the Postgrex connection.
  """
  def start_link(opts \\ []) do
    config = Application.get_env(:keen_auth_permissions, __MODULE__, [])

    merged_opts =
      Keyword.merge(
        [
          hostname: config[:hostname] || "localhost",
          username: config[:username] || "postgresql_permissionmodel",
          password: config[:password] || "Password3000!!",
          database: config[:database] || "postgresql_permissionmodel",
          port: config[:port] || 5432,
          name: __MODULE__,
          after_connect: fn conn ->
            Postgrex.query!(conn, "SET search_path TO auth,helpers,ext,public,const", [])
          end
        ],
        opts
      )

    Postgrex.start_link(merged_opts)
  end

  @doc """
  Executes a SQL query against the database.

  Returns `{:ok, %Postgrex.Result{}}` or `{:error, %Postgrex.Error{}}`.
  """
  def query(sql, params \\ []) do
    Postgrex.query(__MODULE__, sql, params)
  end

  @doc """
  Executes a SQL query and raises on error.
  """
  def query!(sql, params \\ []) do
    Postgrex.query!(__MODULE__, sql, params)
  end
end
