defmodule KeenAuthPermissions.SysParams do
  @moduledoc """
  Facade for system parameter operations.

  **These functions are for initial database setup and configuration of the
  [postgresql-permissions-model](https://github.com/KeenMate/postgresql-permissions-model) only.**
  They are not intended for end-user or application-level use.

  System parameters are set once during deployment/provisioning and rarely changed afterwards.

  ## Access control

  - `get/2` can be called without authentication.
  - `update/5` can only be called by user_id 1 (the system user).

  ## Available parameters

  Seeded by the permissions model:

  | group_code   | code             | default    | type            | description                                                                                              |
  |--------------|------------------|------------|-----------------|----------------------------------------------------------------------------------------------------------|
  | `journal`    | `level`          | `"update"` | text            | Journal logging verbosity. `"all"` = log everything including reads, `"update"` = state-changing only, `"none"` = disable journaling |
  | `journal`    | `retention_days` | `"365"`    | text (cast int) | How many days of journal entries to keep. Used by `unsecure.purge_journal()`                             |
  | `journal`    | `storage_mode`   | `"local"`  | text            | Where journal data goes. `"local"` = INSERT only, `"notify"` = pg_notify only, `"both"` = INSERT + pg_notify |
  | `user_event` | `retention_days` | `"365"`    | text (cast int) | How many days of user events to keep. Used by `unsecure.purge_user_events()`                             |
  | `user_event` | `storage_mode`   | `"local"`  | text            | Where user event data goes. Same modes as journal                                                        |
  | `partition`  | `months_ahead`   | `3`        | number          | How many future monthly partitions to pre-create for journal and user_event tables. Used by `unsecure.ensure_audit_partitions()` |

  Not seeded but read by code:

  | group_code | code                      | default               | type   | description                                                              |
  |------------|---------------------------|-----------------------|--------|--------------------------------------------------------------------------|
  | `auth`     | `perm_cache_timeout_in_s` | `300` (hardcoded fallback) | number | Permission cache TTL in seconds. Used by `unsecure.recalculate_user_permissions()` |

  ## Examples

      # Read a system parameter
      KeenAuthPermissions.SysParams.get("journal", "level")

      # Update a system parameter (must be user_id 1)
      KeenAuthPermissions.SysParams.update("journal", "level", "all")

      # Update a numeric parameter
      KeenAuthPermissions.SysParams.update("partition", "months_ahead", nil, 6)
  """

  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  @doc """
  Gets a system parameter by group code and code.

  This is a low-level setup function for reading postgresql-permissions-model configuration.
  No authentication is required.

  Calls `auth.get_sys_param`.
  """
  @spec get(String.t(), String.t()) :: {:ok, map()} | {:error, any()}
  def get(group_code, code) do
    case db_context().auth_get_sys_param(group_code, code)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Updates a system parameter. Only user_id 1 (system) can call this.

  This is a low-level setup function for configuring the postgresql-permissions-model.
  Intended to be called once during database provisioning/deployment.

  Each parameter can hold a text value, a number value, a boolean value, or any combination.

  Calls `auth.update_sys_param`.
  """
  @spec update(String.t(), String.t(), String.t() | nil, integer() | nil, boolean() | nil) ::
          {:ok, map()} | {:error, any()}
  def update(group_code, code, text_value \\ nil, number_value \\ nil, bool_value \\ nil) do
    case db_context().auth_update_sys_param(
           1,
           group_code,
           code,
           text_value,
           number_value,
           bool_value
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end
end
