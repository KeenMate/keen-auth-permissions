# This code has been auto-generated
# Changes to this file will be lost on next generation

defmodule KeenAuthPermissions.Database.Parsers.AuthGetUserDataParser do
  @moduledoc """
  This module contains functions to parse output from db's stored procedure's calls
  """

  require Logger

  @spec parse_auth_get_user_data_result({:ok, Postgrex.Result.t()} | {:error, any()}) ::
          {:ok,
           [
             KeenAuthPermissions.Database.Models.AuthGetUserDataItem.t()
           ]}
          | {:error, any()}
  def parse_auth_get_user_data_result({:error, reason} = err) do
    Logger.error("Error occured while calling stored procedure",
      procedure: "auth_get_user_data",
      reason: inspect(reason)
    )

    err
  end

  def parse_auth_get_user_data_result({:ok, %Postgrex.Result{rows: rows}}) do
    Logger.debug("Parsing successful response from database")

    parsed_results =
      rows
      |> Enum.map(&parse_auth_get_user_data_result_row/1)

    # todo: Handle rows that could not be parsed

    successful_results =
      parsed_results
      |> Enum.filter(&(elem(&1, 0) == :ok))
      |> Enum.map(&elem(&1, 1))

    Logger.debug("Parsed response")

    {:ok, successful_results}
  end

  def parse_auth_get_user_data_result_row([
        created,
        created_by,
        modified,
        modified_by,
        user_data_id,
        user_id,
        first_name,
        middle_name,
        last_name
      ]) do
    {
      :ok,
      %KeenAuthPermissions.Database.Models.AuthGetUserDataItem{
        created: created,
        created_by: created_by,
        modified: modified,
        modified_by: modified_by,
        user_data_id: user_data_id,
        user_id: user_id,
        first_name: first_name,
        middle_name: middle_name,
        last_name: last_name
      }
    }
  end

  def parse_auth_get_user_data_result_row(_unknown_row) do
    Logger.warn("Found result row that does not have valid number of columns")

    {:error, :einv_columns}
  end
end