# This module provides a clean API for MFA (multi-factor authentication) operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Mfa do
  @moduledoc """
  Clean facade API for multi-factor authentication operations.

  Covers enrollment lifecycle, challenge/verify flow, policy management,
  and login verification with auto-lockout support.

  ## Examples

      # Enroll a user in TOTP MFA
      KeenAuthPermissions.Mfa.enroll(ctx, target_user_id, "totp", "encrypted_secret")

      # Check MFA status
      KeenAuthPermissions.Mfa.get_status(ctx, target_user_id)

      # Check if MFA is required
      KeenAuthPermissions.Mfa.is_required?(ctx, target_user_id, tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Enrollment Lifecycle
  # ============================================================================

  @doc """
  Enrolls a user in MFA.

  Calls `auth.enroll_mfa`.
  Returns enrollment info including recovery codes.
  """
  @spec enroll(RequestContext.t(), integer(), String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def enroll(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        mfa_type_code,
        secret_encrypted
      ) do
    case db_context().auth_enroll_mfa(
           username,
           user_id,
           request_id,
           target_user_id,
           mfa_type_code,
           secret_encrypted,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :enroll_failed}
      error -> error
    end
  end

  @doc """
  Confirms MFA enrollment after the user has verified their code.

  Calls `auth.confirm_mfa_enrollment`.
  """
  @spec confirm_enrollment(RequestContext.t(), integer(), String.t(), boolean()) ::
          :ok | {:error, any()}
  def confirm_enrollment(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        mfa_type_code,
        code_is_valid
      ) do
    db_context().auth_confirm_mfa_enrollment(
      username,
      user_id,
      request_id,
      target_user_id,
      mfa_type_code,
      code_is_valid,
      RequestContext.to_context_map(ctx)
    )
    |> ErrorParsers.parse_if_error()
    |> case do
      :ok -> :ok
      error -> error
    end
  end

  @doc """
  Disables MFA for a user.

  Calls `auth.disable_mfa`.
  """
  @spec disable(RequestContext.t(), integer(), String.t()) :: :ok | {:error, any()}
  def disable(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        mfa_type_code
      ) do
    db_context().auth_disable_mfa(
      username,
      user_id,
      request_id,
      target_user_id,
      mfa_type_code,
      RequestContext.to_context_map(ctx)
    )
    |> ErrorParsers.parse_if_error()
    |> case do
      :ok -> :ok
      error -> error
    end
  end

  @doc """
  Gets the MFA status for a user.

  Calls `auth.get_mfa_status`.
  Returns a list of MFA enrollments (may be empty).
  """
  @spec get_status(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def get_status(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        target_user_id
      ) do
    db_context().auth_get_mfa_status(user_id, request_id, target_user_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Resets MFA for a user, generating new recovery codes.

  Calls `auth.reset_mfa`.
  Returns the new recovery codes.
  """
  @spec reset(RequestContext.t(), integer(), String.t()) :: {:ok, map()} | {:error, any()}
  def reset(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        mfa_type_code
      ) do
    case db_context().auth_reset_mfa(
           username,
           user_id,
           request_id,
           target_user_id,
           mfa_type_code,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :reset_failed}
      error -> error
    end
  end

  # ============================================================================
  # Challenge / Verify
  # ============================================================================

  @doc """
  Creates an MFA challenge token for verification.

  Calls `auth.create_mfa_challenge`.
  Returns the token UID and expiration.
  """
  @spec create_challenge(RequestContext.t(), integer(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def create_challenge(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        mfa_type_code
      ) do
    case db_context().auth_create_mfa_challenge(
           username,
           user_id,
           request_id,
           target_user_id,
           mfa_type_code,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :challenge_failed}
      error -> error
    end
  end

  @doc """
  Verifies an MFA challenge.

  Calls `auth.verify_mfa_challenge`.
  """
  @spec verify_challenge(RequestContext.t(), integer(), String.t(), boolean(), String.t() | nil) ::
          :ok | {:error, any()}
  def verify_challenge(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        target_user_id,
        token_uid,
        code_is_valid,
        recovery_code \\ nil
      ) do
    db_context().auth_verify_mfa_challenge(
      username,
      user_id,
      request_id,
      target_user_id,
      token_uid,
      code_is_valid,
      recovery_code,
      RequestContext.to_context_map(ctx)
    )
    |> ErrorParsers.parse_if_error()
    |> case do
      :ok -> :ok
      error -> error
    end
  end

  # ============================================================================
  # Policy Management
  # ============================================================================

  @doc """
  Creates an MFA policy.

  Calls `auth.create_mfa_policy`.
  Returns the new policy ID.
  """
  @spec create_policy(
          RequestContext.t(),
          integer() | nil,
          integer() | nil,
          integer() | nil,
          boolean()
        ) ::
          {:ok, map()} | {:error, any()}
  def create_policy(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        tenant_id,
        user_group_id,
        target_user_id,
        mfa_required
      ) do
    case db_context().auth_create_mfa_policy(
           username,
           user_id,
           request_id,
           tenant_id,
           user_group_id,
           target_user_id,
           mfa_required,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :create_policy_failed}
      error -> error
    end
  end

  @doc """
  Deletes an MFA policy.

  Calls `auth.delete_mfa_policy`.
  """
  @spec delete_policy(RequestContext.t(), integer()) :: :ok | {:error, any()}
  def delete_policy(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        mfa_policy_id
      ) do
    db_context().auth_delete_mfa_policy(
      username,
      user_id,
      request_id,
      mfa_policy_id,
      RequestContext.to_context_map(ctx)
    )
    |> ErrorParsers.parse_if_error()
    |> case do
      :ok -> :ok
      error -> error
    end
  end

  @doc """
  Gets MFA policies.

  Calls `auth.get_mfa_policies`.
  Pass `nil` for any filter to skip it.
  """
  @spec get_policies(RequestContext.t(), integer() | nil, integer() | nil, integer() | nil) ::
          {:ok, list()} | {:error, any()}
  def get_policies(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        tenant_id,
        user_group_id,
        target_user_id
      ) do
    db_context().auth_get_mfa_policies(
      user_id,
      request_id,
      tenant_id,
      user_group_id,
      target_user_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Checks if MFA is required for a user in a tenant.

  Calls `auth.is_mfa_required`.
  Returns `{:ok, boolean()}`.
  """
  @spec is_required?(RequestContext.t(), integer(), integer()) ::
          {:ok, boolean()} | {:error, any()}
  def is_required?(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        target_user_id,
        tenant_id
      ) do
    case db_context().auth_is_mfa_required(user_id, request_id, target_user_id, tenant_id) do
      {:ok, [%{is_mfa_required: result}]} -> {:ok, result}
      {:ok, []} -> {:ok, false}
      error -> error
    end
  end

  # ============================================================================
  # Login Verification
  # ============================================================================

  @doc """
  Verifies a user by email and password hash.

  Calls `auth.verify_user_by_email`.
  Returns user data on success.
  """
  @spec verify_user_by_email(RequestContext.t(), String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def verify_user_by_email(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id} = ctx,
        email,
        password_hash
      ) do
    case db_context().auth_verify_user_by_email(
           user_id,
           request_id,
           email,
           password_hash,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :verification_failed}
      error -> error
    end
  end

  @doc """
  Records a login failure for auto-lockout tracking.

  Calls `auth.record_login_failure`.
  Note: This may raise a database error if the account gets locked.
  """
  @spec record_login_failure(RequestContext.t(), integer(), String.t()) ::
          :ok | {:error, any()}
  def record_login_failure(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id} = ctx,
        target_user_id,
        email
      ) do
    db_context().auth_record_login_failure(
      user_id,
      request_id,
      target_user_id,
      email,
      RequestContext.to_context_map(ctx)
    )
    |> ErrorParsers.parse_if_error()
    |> case do
      :ok -> :ok
      error -> error
    end
  end
end
