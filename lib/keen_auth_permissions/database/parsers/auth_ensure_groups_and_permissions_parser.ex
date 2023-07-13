# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Parsers.AuthEnsureGroupsAndPermissionsParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_auth_ensure_groups_and_permissions_result(
          {:ok, Postgrex.Result.t()}
          | {:error, any()}
        ) ::
          {:ok,
           [
             KeenAuthPermissions.Database.Models.AuthEnsureGroupsAndPermissionsItem.t()
           ]}
          | {:error, any()}
  def parse_auth_ensure_groups_and_permissions_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "auth_ensure_groups_and_permissions",
      reason: inspect(reason)
    )

    err
  end

  def parse_auth_ensure_groups_and_permissions_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_auth_ensure_groups_and_permissions_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_auth_ensure_groups_and_permissions_result_row([tenant_id, groups, permissions]) do
    {
      :ok,
      %KeenAuthPermissions.Database.Models.AuthEnsureGroupsAndPermissionsItem{
        tenant_id: tenant_id,
        groups: groups,
        permissions: permissions
      }
    }
  end

  def parse_auth_ensure_groups_and_permissions_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end