# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Parsers.AuthGetAllPermissionsParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_auth_get_all_permissions_result({:ok, Postgrex.Result.t()} | {:error, any()}) ::
          {:ok,
           [
             KeenAuthPermissions.Database.Models.AuthGetAllPermissionsItem.t()
           ]}
          | {:error, any()}
  def parse_auth_get_all_permissions_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "auth_get_all_permissions",
      reason: inspect(reason)
    )

    err
  end

  def parse_auth_get_all_permissions_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_auth_get_all_permissions_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_auth_get_all_permissions_result_row([
        permission_id,
        is_assignable,
        title,
        code,
        full_code,
        has_children
      ]) do
    {
      :ok,
      %KeenAuthPermissions.Database.Models.AuthGetAllPermissionsItem{
        permission_id: permission_id,
        is_assignable: is_assignable,
        title: title,
        code: code,
        full_code: full_code,
        has_children: has_children
      }
    }
  end

  def parse_auth_get_all_permissions_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end