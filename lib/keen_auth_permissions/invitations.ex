# This module provides a clean API for invitation operations.
# It wraps the auto-generated database context functions with a cleaner interface.

defmodule KeenAuthPermissions.Invitations do
  @moduledoc """
  Clean facade API for the invitation system.

  Provides phase-based invitations with support for templates, actions, and lifecycle management.
  Invitations carry ordered, typed actions that execute across lifecycle phases:
  `on_create`, `on_accept`, `on_reject`, `on_expired`.

  ## Invitation Lifecycle

      pending → accepted → completed
      pending → rejected
      pending → revoked
      pending → expired

  ## Built-in Action Types

  **Database actions** (executed automatically by the DB):
  - `add_tenant_user`, `add_group_member`, `assign_perm_set`, `assign_permission`, `grant_resource_access`

  **Backend actions** (returned to the calling application for execution):
  - `send_welcome_email`, `send_sms_invite`, `notify_inviter`

  ## Examples

      # Create an invitation with inline actions
      KeenAuthPermissions.Invitations.create(ctx, tenant_id, "user@example.com", actions, "Welcome!", expires_at)

      # Create from a template
      KeenAuthPermissions.Invitations.create_from_template(ctx, tenant_id, "onboarding", "user@example.com", "Welcome!", expires_at)

      # Accept an invitation
      KeenAuthPermissions.Invitations.accept(ctx, invitation_id, target_user_id)

      # List invitations
      KeenAuthPermissions.Invitations.list(ctx, tenant_id)
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Invitation CRUD
  # ============================================================================

  @doc """
  Creates an invitation with inline actions.

  Returns the invitation ID, UUID, and any `on_create` actions that need backend execution.

  Calls `auth.create_invitation`.
  """
  @spec create(
          RequestContext.t(),
          integer(),
          String.t(),
          list(map()),
          String.t() | nil,
          DateTime.t() | nil,
          map() | nil
        ) :: {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        tenant_id,
        target_email,
        actions,
        message \\ nil,
        expires_at \\ nil,
        extra_data \\ nil
      ) do
    case db_context().auth_create_invitation(
           username,
           user_id,
           request_id,
           tenant_id,
           target_email,
           actions,
           message,
           expires_at,
           extra_data,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Creates an invitation from a template.

  The template defines the actions; you can override payload fields via `payload_overrides`.
  Returns the invitation ID, UUID, and any `on_create` actions that need backend execution.

  Calls `auth.create_invitation_from_template`.
  """
  @spec create_from_template(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          String.t() | nil,
          DateTime.t() | nil,
          map() | nil,
          map() | nil
        ) :: {:ok, map()} | {:error, any()}
  def create_from_template(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        tenant_id,
        template_code,
        target_email,
        message \\ nil,
        expires_at \\ nil,
        payload_overrides \\ nil,
        extra_data \\ nil
      ) do
    case db_context().auth_create_invitation_from_template(
           username,
           user_id,
           request_id,
           tenant_id,
           template_code,
           target_email,
           message,
           expires_at,
           payload_overrides,
           extra_data,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Lists invitations with optional filters.

  Calls `auth.get_invitations`.
  """
  @spec list(
          RequestContext.t(),
          integer(),
          String.t() | nil,
          String.t() | nil,
          integer() | nil
        ) :: {:ok, list()} | {:error, any()}
  def list(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        tenant_id,
        target_tenant_id \\ nil,
        status_code \\ nil,
        target_email \\ nil,
        inviter_user_id \\ nil
      ) do
    db_context().auth_get_invitations(
      username,
      user_id,
      request_id,
      tenant_id,
      target_tenant_id,
      status_code,
      target_email,
      inviter_user_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Gets the actions for an invitation.

  Returns the ordered list of actions with their status, payload, and results.

  Calls `auth.get_invitation_actions`.
  """
  @spec get_actions(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def get_actions(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        invitation_id,
        tenant_id \\ 1
      ) do
    db_context().auth_get_invitation_actions(
      username,
      user_id,
      request_id,
      invitation_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Invitation Lifecycle
  # ============================================================================

  @doc """
  Accepts an invitation.

  Executes database-level `on_accept` actions and returns any backend/external actions
  that need to be processed by the calling application.

  Calls `auth.accept_invitation`.
  """
  @spec accept(RequestContext.t(), integer(), integer()) :: {:ok, list()} | {:error, any()}
  def accept(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        invitation_id,
        target_user_id,
        tenant_id \\ 1
      ) do
    db_context().auth_accept_invitation(
      username,
      user_id,
      request_id,
      invitation_id,
      target_user_id,
      RequestContext.to_context_map(ctx),
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Rejects an invitation.

  Executes database-level `on_reject` actions and returns any backend/external actions
  that need to be processed by the calling application.

  Calls `auth.reject_invitation`.
  """
  @spec reject(RequestContext.t(), integer()) :: {:ok, list()} | {:error, any()}
  def reject(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        invitation_id,
        tenant_id \\ 1
      ) do
    db_context().auth_reject_invitation(
      username,
      user_id,
      request_id,
      invitation_id,
      RequestContext.to_context_map(ctx),
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Revokes an invitation (by the inviter or admin).

  Calls `auth.revoke_invitation`.
  """
  @spec revoke(RequestContext.t(), integer()) :: :ok | {:error, any()}
  def revoke(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        invitation_id,
        tenant_id \\ 1
      ) do
    db_context().auth_revoke_invitation(
      username,
      user_id,
      request_id,
      invitation_id,
      RequestContext.to_context_map(ctx),
      tenant_id
    )
  end

  # ============================================================================
  # Invitation Templates
  # ============================================================================

  @doc """
  Ensures invitation templates exist (upsert from JSONB array).

  Skips templates that already exist (by code + tenant_id), creates missing ones with their actions.
  When `is_final_state` is true, removes templates from `source` that are not in the input set.

  Calls `auth.ensure_invitation_templates`.
  """
  @spec ensure_templates(RequestContext.t(), list(map()), integer(), String.t() | nil, boolean()) ::
          {:ok, list()} | {:error, any()}
  def ensure_templates(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        templates,
        tenant_id,
        source \\ nil,
        is_final_state \\ false
      ) do
    db_context().auth_ensure_invitation_templates(
      username,
      user_id,
      request_id,
      templates,
      tenant_id,
      source,
      is_final_state,
      RequestContext.to_context_map(ctx)
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Creates an invitation template.

  Templates define reusable sets of actions with a code, title, description, and default message.

  Calls `auth.create_invitation_template`.
  Returns `{:ok, template_id}`.
  """
  @spec create_template(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          list(map())
        ) :: {:ok, integer()} | {:error, any()}
  def create_template(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        tenant_id,
        code,
        title,
        description \\ nil,
        default_message \\ nil,
        actions
      ) do
    case db_context().auth_create_invitation_template(
           username,
           user_id,
           request_id,
           tenant_id,
           code,
           title,
           description,
           default_message,
           actions,
           RequestContext.to_context_map(ctx)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [%{create_invitation_template: template_id}]} -> {:ok, template_id}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates an invitation template.

  Calls `auth.update_invitation_template`.
  """
  @spec update_template(
          RequestContext.t(),
          integer(),
          String.t(),
          String.t() | nil,
          String.t() | nil,
          boolean()
        ) :: :ok | {:error, any()}
  def update_template(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        template_id,
        title,
        description \\ nil,
        default_message \\ nil,
        is_active \\ true,
        tenant_id \\ 1
      ) do
    db_context().auth_update_invitation_template(
      username,
      user_id,
      request_id,
      template_id,
      title,
      description,
      default_message,
      is_active,
      RequestContext.to_context_map(ctx),
      tenant_id
    )
  end

  @doc """
  Deletes an invitation template.

  Calls `auth.delete_invitation_template`.
  """
  @spec delete_template(RequestContext.t(), integer()) :: :ok | {:error, any()}
  def delete_template(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        } = ctx,
        template_id,
        tenant_id \\ 1
      ) do
    db_context().auth_delete_invitation_template(
      username,
      user_id,
      request_id,
      template_id,
      RequestContext.to_context_map(ctx),
      tenant_id
    )
  end
end
