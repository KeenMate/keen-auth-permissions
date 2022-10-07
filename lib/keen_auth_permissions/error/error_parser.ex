defmodule KeenAuthPermissions.Error.ErrorParsers do
  import KeenAuthPermissions.Error.ErrorStruct

  def parse_if_error({:error, error}), do: {:error, parse_error(error)}
  def parse_if_error(val), do: val

  # * NON
  def parse_error(%Postgrex.Error{
        postgres: %{
          constraint: "uq_user_identity",
          pg_code: "23505"
        }
      }) do
    create(:user_with_email_exists, "User identity with same email already exists")
  end

  def parse_error(%Postgrex.Error{
        postgres: %{
          pg_code: code
        }
      }) do
    {code, _} = Integer.parse(code, 10)
    parse_error(code)
  end

  def parse_error(50003), do: create(:permission_denied, "Permission denied")

  # * USERS
  def parse_error(52101), do: create(:cannot_ensure_user, "Cannot ensure user for email provider")

  def parse_error(52102),
    do: create(:identity_used, "User cannot register user because the identity is already in use")

  def parse_error(52103), do: create(:user_doesnt_exist, "User does not exist")

  def parse_error(52104), do: create(:user_is_system, "User is a system user")
  def parse_error(52105), do: create(:user_inactive, "User is in inactive state")

  def parse_error(52106), do: create(:user_locked, "User is locked")

  def parse_error(52107), do: create(:provider_inactive, "Provider is not active")

  def parse_error(52108), do: create(:user_not_in_tenant, "User has no access to tenant")

  def parse_error(52109), do: create(:no_permission, "User has no correct permission in tenant")

  def parse_error(52110), do: create(:identity_inactive, "User provider identity is not active")

  def parse_error(52111),
    do: create(:identity_doesnt_exist, "User provider identity does not exist")

  def parse_error(52112), do: create(:login_disabled, "User is not supposed to log in")

  # * GROUPS
  def parse_error(52171), do: create(:group_not_found, "User group not found")

  def parse_error(52172),
    do: create(:group_inactive, "User cannot be added to group because the group is not active")

  def parse_error(52173),
    do:
      create(
        :group_unassignable_or_external,
        "User cannot be added to group because it's either not assignable or an external group"
      )

  def parse_error(52174),
    do: create(:object_id_and_role_undefined, "Either mapped object id or role must not be empty")

  # * PERMISSIONS
  def parse_error(52175),
    do: create(:permission_set_unassignable, "Permission set is not assignable")

  def parse_error(52176), do: create(:permission_unassignable, "Permission is not assignable")

  def parse_error(52177),
    do: create(:permission_undefined, "Permission set is not defined in tenant")

  def parse_error(52178),
    do: create(:some_permission_unassignable, "Some permission is not assignable")

  def parse_error(52271),
    do:
      create(
        :cant_delete_system_group,
        "User group cannot be deleted because it's a system group"
      )

  def parse_error(52272),
    do:
      create(
        :group_and_targe_user_undefined,
        "Either user group id or target user id has to be not null"
      )

  def parse_error(52273),
    do:
      create(
        :permission_and_permission_set_undefined,
        "Either permission set code or permission code has to be not null "
      )

  def parse_error(52274),
    do:
      create(:permission_id_and_code_undefined, "Either permission id or code has to be not null")

  def parse_error(52275), do: create(:permission_doesnt_exist, "Permission does not exist")

  # * TOKENS
  def parse_error(52276), do: create(:token_used, "The same token is already used")

  def parse_error(52277), do: create(:token_doesnt_exist, "Token does not exist")

  def parse_error(52278),
    do: create(:token_invalid_or_expired, "Token is not valid or has expired")

  def parse_error(52279), do: create(:token_wrong_user, "Token was created for different user")

  # * FALLBACK
  def parse_error(code), do: IO.inspect(code, label: "unknown error code")

  create(:unknown, "Unknown error code")
end
