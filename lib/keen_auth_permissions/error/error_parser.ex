defmodule KeenAuthPermissions.Error.ErrorParsers do
  @moduledoc """
  Translates `Postgrex.Error` structs raised by the PostgreSQL stored procedures
  into `KeenAuthPermissions.Error.ErrorStruct` values with a stable `reason` atom.

  The project's stored procedures raise with SQLSTATEs in the **3xxxx** range
  (PostgreSQL reserves 5xxxx for built-ins). The numeric code is also the
  project's `event_id` — see the `public.event_*` tables. Every parsed error
  carries the raw `event_id` in `metadata` so callers can disambiguate codes
  even when the atom falls through to `:unknown`.
  """

  import KeenAuthPermissions.Error.ErrorStruct

  def parse_if_error({:error, error}), do: {:error, parse_error(error)}
  def parse_if_error(val), do: val

  # ============================================================================
  # Constraint-specific clauses (PostgreSQL built-in 23505 unique_violation).
  # These match by constraint name before falling through to the generic clause.
  # ============================================================================

  def parse_error(%Postgrex.Error{
        postgres: %{
          constraint: "uq_user_identity",
          pg_code: "23505"
        }
      }) do
    create(:user_with_email_exists, "User identity with same email already exists", %{
      event_id: 23505
    })
  end

  def parse_error(%Postgrex.Error{
        postgres: %{
          constraint: "uq_user_group_member",
          pg_code: "23505"
        }
      }) do
    create(:user_already_member, "User is already member of this group", %{event_id: 23505})
  end

  def parse_error(%Postgrex.Error{
        postgres: %{
          constraint: "user_group_mapping_provider_code_fkey",
          pg_code: "23505"
        }
      }) do
    create(:provider_doesnt_exist, "Given provider doesnt exist", %{event_id: 23505})
  end

  # Generic: dispatch on pg_code, preserve event_id in metadata.
  def parse_error(%Postgrex.Error{postgres: %{pg_code: code, message: msg}}) do
    {event_id, _} = Integer.parse(code, 10)
    create(parse_reason(event_id), msg, %{event_id: event_id})
  end

  # ============================================================================
  # Reason atoms by event_id. See ppm seed data (029_seed_data.sql etc.) for the
  # source-of-truth catalog. Atom names mirror the SQL `err_*` names minus the prefix.
  # ============================================================================

  # Security / Auth (30xxx)
  def parse_reason(30001), do: :api_key_invalid
  def parse_reason(30002), do: :token_invalid
  def parse_reason(30003), do: :token_wrong_user
  def parse_reason(30004), do: :token_already_used
  def parse_reason(30005), do: :token_not_found

  # Validation (31xxx)
  def parse_reason(31001), do: :either_group_or_user
  def parse_reason(31002), do: :either_perm_set_or_perm
  def parse_reason(31003), do: :either_perm_id_or_code
  def parse_reason(31004), do: :either_mapping_id_or_role
  def parse_reason(31010), do: :event_code_is_system
  def parse_reason(31011), do: :event_code_not_found
  def parse_reason(31012), do: :event_category_not_empty
  def parse_reason(31013), do: :event_id_out_of_range
  def parse_reason(31014), do: :event_category_not_found

  # Permissions (32xxx)
  def parse_reason(32001), do: :no_permission
  def parse_reason(32002), do: :permission_not_found
  def parse_reason(32003), do: :permission_not_assignable
  def parse_reason(32004), do: :perm_set_not_found
  def parse_reason(32005), do: :perm_set_not_assignable
  def parse_reason(32006), do: :perm_set_wrong_tenant
  def parse_reason(32007), do: :parent_permission_not_found
  def parse_reason(32008), do: :some_perms_not_assignable

  # User / Identity / Group (33xxx)
  def parse_reason(33001), do: :user_not_found
  def parse_reason(33002), do: :user_is_system
  def parse_reason(33003), do: :user_not_active
  def parse_reason(33004), do: :user_locked
  def parse_reason(33005), do: :user_cannot_login
  def parse_reason(33006), do: :user_no_email_provider
  def parse_reason(33007), do: :identity_already_used
  def parse_reason(33008), do: :identity_not_active
  def parse_reason(33009), do: :identity_not_found
  def parse_reason(33010), do: :provider_not_active
  def parse_reason(33011), do: :group_not_found
  def parse_reason(33012), do: :group_not_active
  def parse_reason(33013), do: :group_not_assignable
  def parse_reason(33014), do: :group_is_system
  def parse_reason(33015), do: :not_owner
  def parse_reason(33016), do: :provider_no_group_mapping
  def parse_reason(33017), do: :provider_no_group_sync
  def parse_reason(33018), do: :user_blacklisted
  def parse_reason(33019), do: :identity_blacklisted
  def parse_reason(33020), do: :user_not_resolvable
  def parse_reason(33021), do: :group_not_resolvable

  # Tenant (34xxx)
  def parse_reason(34001), do: :no_tenant_access
  def parse_reason(34002), do: :cross_tenant_requires_admin
  def parse_reason(34003), do: :tenant_not_resolvable

  # Resource access / roles (35xxx)
  def parse_reason(35001), do: :no_resource_access
  def parse_reason(35002), do: :resource_grant_no_target
  def parse_reason(35003), do: :resource_type_not_found
  def parse_reason(35004), do: :resource_access_flag_not_found
  def parse_reason(35005), do: :resource_id_invalid
  def parse_reason(35006), do: :resource_flag_not_valid
  def parse_reason(35007), do: :resource_role_not_found
  def parse_reason(35008), do: :resource_role_invalid_flag
  def parse_reason(35009), do: :resource_role_type_mismatch
  def parse_reason(35010), do: :resource_identifier_required

  # Token config (36xxx)
  def parse_reason(36001), do: :token_type_not_found
  def parse_reason(36002), do: :token_type_is_system

  # Language / Translation (37xxx)
  def parse_reason(37001), do: :language_not_found
  def parse_reason(37002), do: :translation_not_found

  # MFA (38xxx)
  def parse_reason(38001), do: :mfa_already_enrolled
  def parse_reason(38002), do: :mfa_not_enrolled
  def parse_reason(38003), do: :mfa_not_confirmed
  def parse_reason(38004), do: :mfa_invalid_code
  def parse_reason(38005), do: :mfa_required
  def parse_reason(38006), do: :mfa_type_not_found
  def parse_reason(38007), do: :mfa_policy_not_found

  # Invitation (39xxx)
  def parse_reason(39001), do: :invitation_not_found
  def parse_reason(39002), do: :invitation_not_pending
  def parse_reason(39003), do: :invitation_expired
  def parse_reason(39004), do: :invitation_action_not_found
  def parse_reason(39005), do: :invitation_action_not_pending
  def parse_reason(39006), do: :invitation_template_not_found

  def parse_reason(_), do: :unknown
end
