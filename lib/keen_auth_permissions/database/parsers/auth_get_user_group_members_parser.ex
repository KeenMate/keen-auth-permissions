# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Parsers.AuthGetUserGroupMembersParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_auth_get_user_group_members_result({:ok, Postgrex.Result.t()} | {:error, any()}) ::
          {:ok,
           [
             KeenAuthPermissions.Database.Models.AuthGetUserGroupMembersItem.t()
           ]}
          | {:error, any()}
  def parse_auth_get_user_group_members_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "auth_get_user_group_members",
      reason: inspect(reason)
    )

    err
  end

  def parse_auth_get_user_group_members_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_auth_get_user_group_members_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_auth_get_user_group_members_result_row([
        created,
        created_by,
        member_id,
        manual_assignment,
        user_id,
        user_display_name,
        user_is_system,
        user_is_active,
        user_is_locked,
        mapping_id,
        mapping_mapped_object_name,
        mapping_provider_code
      ]) do
    {
      :ok,
      %KeenAuthPermissions.Database.Models.AuthGetUserGroupMembersItem{
        created: created,
        created_by: created_by,
        member_id: member_id,
        manual_assignment: manual_assignment,
        user_id: user_id,
        user_display_name: user_display_name,
        user_is_system: user_is_system,
        user_is_active: user_is_active,
        user_is_locked: user_is_locked,
        mapping_id: mapping_id,
        mapping_mapped_object_name: mapping_mapped_object_name,
        mapping_provider_code: mapping_provider_code
      }
    }
  end

  def parse_auth_get_user_group_members_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end