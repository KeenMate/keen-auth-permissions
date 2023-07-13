defmodule KeenAuthPermissions.Providers.AuthProvider do
  alias KeenAuthPermissions.Error.{ErrorParsers, ErrorStruct}

  def db_context() do
    KeenAuthPermissions.DbContext.get_global_db_context()
  end

  def create_auth_event(created_by, user_id, event_type, target_user_id, payload_map) do
    db_context().auth_create_user_event(
      created_by,
      user_id,
      event_type,
      target_user_id,
      nil,
      nil,
      nil,
      Jason.encode!(payload_map),
      nil,
      nil
    )
    |> ErrorParsers.parse_if_error()
  end

  def get_user_identity_by_email(email) do
    case db_context().auth_get_user_identity_by_email(1, email, "email") do
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, ErrorStruct.create(:no_user, "No user with given email exists")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  def get_user_by_id(user_id) do
    case db_context().auth_get_user_by_id(user_id) do
      {:ok, [user | _]} -> {:ok, user}
      {:ok, []} -> {:error, ErrorStruct.create(:no_user, "No user with given email exists")}
      {:error, error} -> {:error, ErrorParsers.parse_error(error)}
    end
  end

  def validate_user_token(user_id, token, token_type, invalidate \\ false) do
    case db_context().auth_validate_token(
           "system",
           1,
           user_id,
           nil,
           token,
           token_type,
           nil,
           nil,
           nil,
           invalidate
         ) do
      {:ok, [token | _]} -> {:ok, token}
      {:error, err} -> {:error, ErrorParsers.parse_error(err)}
    end
  end

  def update_password(user_id, hashed_password) do
    db_context().auth_update_user_password(
      "system",
      1,
      user_id,
      hashed_password,
      nil,
      nil,
      nil,
      nil
    )
    |> ErrorParsers.parse_if_error()
  end

  def register_user(email, hashed_password, name) do
    db_context().auth_register_user(
      "system",
      1,
      email,
      hashed_password,
      name,
      nil
    )
    |> ErrorParsers.parse_if_error()
  end

  def create_email_verification_token(user_id, auth_event_id, token) do
    db_context().auth_create_token(
      "system",
      1,
      user_id,
      nil,
      auth_event_id,
      "email_verification",
      "email",
      token,
      nil,
      nil
    )
    |> ErrorParsers.parse_if_error()
  end

  def create_password_reset_token(method, user_id, auth_event_id, token) do
    db_context().auth_create_token(
      "system",
      1,
      user_id,
      nil,
      auth_event_id,
      "password_reset",
      method,
      token,
      nil,
      nil
    )
    |> ErrorParsers.parse_if_error()
  end

  def activate_email(user_id) do
    db_context().auth_enable_user_identity("system", 1, user_id, "email")
    |> ErrorParsers.parse_if_error()
  end

  def add_to_default_groups_in_tenant(target_user_id, tenant_id) do
    db_context().auth_add_user_to_default_groups("system", 1, target_user_id, tenant_id)
    |> ErrorParsers.parse_if_error()
  end
end
