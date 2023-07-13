# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Parsers.AuthAssignApiKeyPermissionsParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_auth_assign_api_key_permissions_result({:ok, Postgrex.Result.t()} | {:error, any()}) ::
          {:ok,
           [
             KeenAuthPermissions.Database.Models.AuthAssignApiKeyPermissionsItem.t()
           ]}
          | {:error, any()}
  def parse_auth_assign_api_key_permissions_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "auth_assign_api_key_permissions",
      reason: inspect(reason)
    )

    err
  end

  def parse_auth_assign_api_key_permissions_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_auth_assign_api_key_permissions_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_auth_assign_api_key_permissions_result_row([
        assignment_id,
        tenant_id,
        perm_set_id,
        perm_set_code,
        perm_set_title,
        permission_full_code,
        permission_full_title,
        permission_title
      ]) do
    {
      :ok,
      %KeenAuthPermissions.Database.Models.AuthAssignApiKeyPermissionsItem{
        assignment_id: assignment_id,
        tenant_id: tenant_id,
        perm_set_id: perm_set_id,
        perm_set_code: perm_set_code,
        perm_set_title: perm_set_title,
        permission_full_code: permission_full_code,
        permission_full_title: permission_full_title,
        permission_title: permission_title
      }
    }
  end

  def parse_auth_assign_api_key_permissions_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end