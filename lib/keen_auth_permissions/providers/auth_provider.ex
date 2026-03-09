defmodule KeenAuthPermissions.Providers.AuthProvider do
  @moduledoc """
  DEPRECATED: Use `KeenAuthPermissions.Auth` and `KeenAuthPermissions.Users` instead.

  This module is kept for backward compatibility and delegates to the new facades.
  """

  @deprecated "Use KeenAuthPermissions.Auth or KeenAuthPermissions.Users instead"

  alias KeenAuthPermissions.Auth
  alias KeenAuthPermissions.Users
  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  defp ctx(%User{} = user), do: RequestContext.new(user)

  # Create a system user for operations that don't have a current user
  defp system_user do
    %User{
      user_id: 1,
      code: "system",
      uuid: nil,
      username: "system",
      email: nil,
      display_name: "System",
      groups: [],
      permissions: []
    }
  end

  defp system_ctx, do: ctx(system_user())

  @doc deprecated: "Use KeenAuthPermissions.Auth.create_event_with_payload/4 instead"
  def create_auth_event(created_by, user_id, event_type, target_user_id, payload_map) do
    user = %User{
      user_id: user_id,
      code: nil,
      uuid: nil,
      username: created_by,
      email: nil,
      display_name: nil,
      groups: [],
      permissions: []
    }

    Auth.create_event_with_payload(ctx(user), event_type, target_user_id, payload_map)
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.get_identity_by_email/3 instead"
  def get_user_identity_by_email(email) do
    case Users.get_identity_by_email(1, email, "email") do
      {:ok, user} -> {:ok, user}
      {:error, %ErrorStruct{}} = error -> error
      {:error, _} -> {:error, ErrorStruct.create(:no_user, "No user with given email exists")}
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.get_by_id/1 instead"
  def get_user_by_id(user_id) do
    case Users.get_by_id(user_id) do
      {:ok, user} -> {:ok, user}
      {:error, %ErrorStruct{}} = error -> error
      {:error, _} -> {:error, ErrorStruct.create(:no_user, "No user with given id exists")}
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.Auth.validate_token/6 instead"
  def validate_user_token(user_id, token, token_type, invalidate \\ false) do
    case Auth.validate_token(
           system_ctx(),
           user_id,
           nil,
           token,
           token_type,
           invalidate
         ) do
      {:ok, token_result} -> {:ok, token_result}
      {:error, %ErrorStruct{}} = error -> error
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.update_password/4 instead"
  def update_password(user_id, hashed_password) do
    Users.update_password(system_ctx(), user_id, hashed_password)
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.register/5 instead"
  def register_user(email, hashed_password, name) do
    Users.register(system_ctx(), email, hashed_password, name, nil)
  end

  @doc deprecated: "Use KeenAuthPermissions.Auth.create_token/9 instead"
  def create_email_verification_token(user_id, auth_event_id, token) do
    Auth.create_token(
      system_ctx(),
      user_id,
      nil,
      auth_event_id,
      "email_verification",
      "email",
      token,
      nil,
      nil
    )
  end

  @doc deprecated: "Use KeenAuthPermissions.Auth.create_token/9 instead"
  def create_password_reset_token(method, user_id, auth_event_id, token) do
    Auth.create_token(
      system_ctx(),
      user_id,
      nil,
      auth_event_id,
      "password_reset",
      method,
      token,
      nil,
      nil
    )
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.enable_identity/3 instead"
  def activate_email(user_id) do
    Users.enable_identity(system_ctx(), user_id, "email")
  end

  @doc deprecated: "Use KeenAuthPermissions.Users.assign_default_groups/3 instead"
  def add_to_default_groups_in_tenant(target_user_id, tenant_id) do
    Users.assign_default_groups(system_ctx(), target_user_id, tenant_id)
  end
end
