defmodule KeenAuthPermissions.TestDatabase do
  @moduledoc """
  Test database context that uses the generated database functions.

  This module uses the `KeenAuthPermissions.Database` macro with the TestRepo
  to provide access to all stored procedure wrapper functions.
  """

  use KeenAuthPermissions.Database, repo: KeenAuthPermissions.TestRepo
end
