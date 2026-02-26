defmodule KeenAuthPermissions.EventClassification do
  @moduledoc """
  Classifies SSE auth events into severity tiers.

  - `:hard` — user's access is revoked, must force re-auth
  - `:medium` — significant permission change, suggest reload
  - `:soft` — minor change, silently refresh data

  Default classifications can be overridden per-app via config:

      config :keen_auth_permissions, :event_classification, %{
        "provider_disabled" => :medium
      }
  """

  @hard_events ~w(
    user_deleted
    user_disabled
    user_locked
    tenant_deleted
    provider_deleted
    provider_disabled
  )

  @medium_events ~w(
    group_deleted
    group_disabled
    group_type_changed
    permission_assignability_changed
    perm_set_updated
    perm_set_permissions_added
    perm_set_permissions_removed
    group_mapping_created
    group_mapping_deleted
  )

  @soft_events ~w(
    user_enabled
    user_unlocked
    permission_assigned
    permission_unassigned
    group_member_added
    group_member_removed
    group_enabled
    owner_created
    owner_deleted
    provider_enabled
    api_key_created
    api_key_deleted
  )

  @default_classification Map.merge(
                            Map.merge(
                              Map.new(@hard_events, &{&1, :hard}),
                              Map.new(@medium_events, &{&1, :medium})
                            ),
                            Map.new(@soft_events, &{&1, :soft})
                          )

  @doc """
  Classify an event name into `:hard`, `:medium`, `:soft`, or `:unknown`.

  Checks app-level overrides first, then falls back to built-in defaults.
  """
  @spec classify(String.t()) :: :hard | :medium | :soft | :unknown
  def classify(event_name) when is_binary(event_name) do
    overrides = Application.get_env(:keen_auth_permissions, :event_classification, %{})

    case Map.get(overrides, event_name) do
      nil -> Map.get(@default_classification, event_name, :unknown)
      tier -> tier
    end
  end

  @doc """
  Returns a human-readable message for a given event.
  """
  @spec message(String.t()) :: String.t()
  def message("user_deleted"), do: "Your account has been deleted."
  def message("user_disabled"), do: "Your account has been disabled."
  def message("user_locked"), do: "Your account has been locked."
  def message("tenant_deleted"), do: "Your tenant has been deleted."
  def message("provider_deleted"), do: "Your authentication provider has been removed."
  def message("provider_disabled"), do: "Your authentication provider has been disabled."

  def message("group_deleted"),
    do: "A group you belong to has been deleted. Reload to update your access."

  def message("group_disabled"),
    do: "A group you belong to has been disabled. Reload to update your access."

  def message("group_type_changed"), do: "A group type has changed. Reload to update your access."

  def message("permission_assignability_changed"),
    do: "Permission assignability has changed. Reload to update your access."

  def message("perm_set_updated"),
    do: "A permission set has been updated. Reload to update your access."

  def message("perm_set_permissions_added"),
    do: "Permissions were added to a set. Reload to update your access."

  def message("perm_set_permissions_removed"),
    do: "Permissions were removed from a set. Reload to update your access."

  def message("group_mapping_created"),
    do: "A group mapping has been created. Reload to update your access."

  def message("group_mapping_deleted"),
    do: "A group mapping has been deleted. Reload to update your access."

  def message(_event), do: "Your access has been updated."
end
