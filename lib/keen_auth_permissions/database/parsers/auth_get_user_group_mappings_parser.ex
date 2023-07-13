# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Parsers.AuthGetUserGroupMappingsParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_auth_get_user_group_mappings_result({:ok, Postgrex.Result.t()} | {:error, any()}) ::
          {:ok,
           [
             KeenAuthPermissions.Database.Models.AuthGetUserGroupMappingsItem.t()
           ]}
          | {:error, any()}
  def parse_auth_get_user_group_mappings_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "auth_get_user_group_mappings",
      reason: inspect(reason)
    )

    err
  end

  def parse_auth_get_user_group_mappings_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_auth_get_user_group_mappings_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_auth_get_user_group_mappings_result_row([
        created,
        created_by,
        ug_mapping_id,
        group_id,
        provider_code,
        mapped_object_id,
        mapped_object_name,
        mapped_role
      ]) do
    {
      :ok,
      %KeenAuthPermissions.Database.Models.AuthGetUserGroupMappingsItem{
        created: created,
        created_by: created_by,
        ug_mapping_id: ug_mapping_id,
        group_id: group_id,
        provider_code: provider_code,
        mapped_object_id: mapped_object_id,
        mapped_object_name: mapped_object_name,
        mapped_role: mapped_role
      }
    }
  end

  def parse_auth_get_user_group_mappings_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end