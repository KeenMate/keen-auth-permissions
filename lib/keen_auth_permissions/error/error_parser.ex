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
          pg_code: code,
          message: msg
        }
      }) do
    {code, _} = Integer.parse(code, 10)
    {:error, create(parse_reason(code), msg)}
  end

  def parse_reason(50003), do: :permission_denied

  # * USERS
  def parse_reason(52101),
    do: :cannot_ensure_user

  def parse_reason(52102),
    do: :identity_used

  def parse_reason(52103), do: :user_doesnt_exist

  def parse_reason(52104), do: :user_is_system
  def parse_reason(52105), do: :user_inactive

  def parse_reason(52106), do: :user_locked

  def parse_reason(52107), do: :provider_inactive

  def parse_reason(52108), do: :user_not_in_tenant

  def parse_reason(52109), do: :no_permission

  def parse_reason(52110), do: :identity_inactive

  def parse_reason(52111),
    do: :identity_doesnt_exist

  def parse_reason(52112), do: :login_disabled

  # * GROUPS
  def parse_reason(52171), do: :group_not_found

  def parse_reason(52172),
    do: :group_inactive

  def parse_reason(52173),
    do: :group_unassignable_or_external

  def parse_reason(52174),
    do: :object_id_and_role_undefined

  # * PERMISSIONS
  def parse_reason(52175),
    do: :permission_set_unassignable

  def parse_reason(52176), do: :permission_unassignable

  def parse_reason(52177),
    do: :permission_undefined

  def parse_reason(52178),
    do: :some_permission_unassignable

  def parse_reason(52271),
    do: :cant_delete_system_group

  def parse_reason(52272),
    do: :group_and_targe_user_undefined

  def parse_reason(52273),
    do: :permission_and_permission_set_undefined

  def parse_reason(52274),
    do: :permission_id_and_code_undefined

  def parse_reason(52275), do: :permission_doesnt_exist

  # * TOKENS
  def parse_reason(52276), do: :token_used

  def parse_reason(52277), do: :token_doesnt_exist

  def parse_reason(52278),
    do: :token_invalid_or_expired

  def parse_reason(52279), do: :token_wrong_user

  # * FALLBACK
  def parse_reason(code), do: :unknown
end
