# SSE Event Handling

This document describes the tiered SSE (Server-Sent Events) event handling system for real-time auth notifications in LiveView applications.

## Overview

When auth-related changes happen in the database (user disabled, permissions changed, group deleted, etc.), PostgreSQL triggers fire notifications through PgListener, which broadcasts them via PubSub to connected LiveViews. The event handling system classifies these events into three severity tiers and responds appropriately.

## Event Tiers

### Hard — Access Revoked

The user can no longer use the application. A full-screen blocking overlay appears, the session is cleared server-side, and the user is redirected to `/login`.

| Event | Message |
|:------|:--------|
| `user_deleted` | Your account has been deleted. |
| `user_disabled` | Your account has been disabled. |
| `user_locked` | Your account has been locked. |
| `tenant_deleted` | Your tenant has been deleted. |
| `provider_deleted` | Your authentication provider has been removed. |
| `provider_disabled` | Your authentication provider has been disabled. |

### Medium — Significant Change

The user's permissions or group membership changed in a way that may affect what they can see or do. A dismissible warning banner appears at the top of the page with a "Reload" button.

| Event | Message |
|:------|:--------|
| `group_deleted` | A group you belong to has been deleted. Reload to update your access. |
| `group_disabled` | A group you belong to has been disabled. Reload to update your access. |
| `group_type_changed` | A group type has changed. Reload to update your access. |
| `permission_assignability_changed` | Permission assignability has changed. Reload to update your access. |
| `perm_set_updated` | A permission set has been updated. Reload to update your access. |
| `perm_set_permissions_added` | Permissions were added to a set. Reload to update your access. |
| `perm_set_permissions_removed` | Permissions were removed from a set. Reload to update your access. |
| `group_mapping_created` | A group mapping has been created. Reload to update your access. |
| `group_mapping_deleted` | A group mapping has been deleted. Reload to update your access. |

### Soft — Minor Change

Data is silently refreshed in the background. No visible notification.

| Event |
|:------|
| `user_enabled`, `user_unlocked` |
| `permission_assigned`, `permission_unassigned` |
| `group_member_added`, `group_member_removed`, `group_enabled` |
| `owner_created`, `owner_deleted` |
| `provider_enabled` |
| `api_key_created`, `api_key_deleted` |

Unknown events default to soft behavior.

## Architecture

```
PostgreSQL trigger
    |
    v
PgListener (keen_auth_permissions)
    |
    v
Phoenix.PubSub broadcast  {:sse_event, event_name, payload}
    |
    v
LiveView handle_info
    |
    v
AuthEventHandler.handle_sse_event/4
    |
    +-- classifies via EventClassification.classify/1
    |
    +-- :hard  --> assign auth_blocked, push_event "auth:hard_block"
    |               --> JS hook: overlay + POST /auth/clear + redirect
    |
    +-- :medium --> assign auth_warning + auth_warning_message
    |               --> warning banner with Reload / Dismiss
    |
    +-- :soft  --> call reload function silently
```

## Components

### EventClassification (library)

**Module**: `KeenAuthPermissions.EventClassification`
**Location**: `keen_auth_permissions/lib/keen_auth_permissions/event_classification.ex`

Provides two functions:

```elixir
# Returns :hard, :medium, :soft, or :unknown
EventClassification.classify("user_disabled")
#=> :hard

# Returns a human-readable message
EventClassification.message("user_disabled")
#=> "Your account has been disabled."
```

#### Overriding Classifications

Consuming applications can override the default tier for any event via config:

```elixir
# config/config.exs
config :keen_auth_permissions, :event_classification, %{
  "provider_disabled" => :medium,  # downgrade from hard to medium
  "my_custom_event" => :hard       # add a custom event
}
```

App-level overrides take precedence over built-in defaults.

### SessionClearPlug (keen_auth)

**Module**: `KeenAuth.SessionClearPlug`
**Location**: `keen_auth/lib/session_clear_plug.ex`

A Plug that clears the session and returns `204 No Content`. Used by the JS hard-block handler to invalidate the session without a page redirect.

**Router setup** (requires `:browser` + `:authentication` pipelines for session access and CSRF, but NOT `:require_auth` since the user may already be deleted/disabled):

```elixir
scope "/auth" do
  pipe_through [:browser, :authentication]
  post "/clear", KeenAuth.SessionClearPlug, []
end
```

### AuthEventHandler (test app)

**Module**: `KeenAuthPermissionsTestWeb.AuthEventHandler`

Shared handler that replaces duplicated `handle_info` clauses across LiveViews:

```elixir
# Before: 4 handle_info clauses per LiveView (duplicated x6)
def handle_info({:sse_event, "user_deleted", _payload}, socket), do: ...
def handle_info({:sse_event, "user_disabled", _payload}, socket), do: ...
def handle_info({:sse_event, "user_locked", _payload}, socket), do: ...
def handle_info({:sse_event, _event, _payload}, socket), do: ...

# After: 1 handle_info clause
def handle_info({:sse_event, event, payload}, socket) do
  {:noreply, AuthEventHandler.handle_sse_event(socket, event, payload, &load_users/1)}
end
```

The fourth argument is the reload function specific to each LiveView (`&load_users/1`, `&load_groups/1`, etc.).

### AuthComponents (test app)

**Module**: `KeenAuthPermissionsTestWeb.AuthComponents`

Function component `<.auth_event_listener>` that renders:
1. A hidden `<div>` with `phx-hook="AuthEvents"` — anchor for the JS hook
2. A fixed-position warning banner (DaisyUI `alert-warning`) when `@auth_warning` is true

```heex
<.auth_event_listener
  auth_blocked={@auth_blocked}
  auth_warning={@auth_warning}
  auth_warning_message={@auth_warning_message}
/>
```

Imported globally via `html_helpers` in `keen_auth_permissions_test_web.ex`.

### AuthEvents JS Hook (test app)

**Location**: `assets/js/hooks/auth_events.js`

Listens for the `auth:hard_block` push event from LiveView and:
1. Creates a full-screen non-dismissible overlay with an error message and spinner
2. POSTs to `/auth/clear` with the CSRF token to invalidate the server session
3. Disconnects the LiveView websocket
4. Redirects to `/login` after a 2-second delay (so the user can read the message)

Registered in `app.js`:
```javascript
import AuthEvents from "./hooks/auth_events"

hooks: {...colocatedHooks, AuthEvents}
```

## Integration Guide

To add tiered event handling to a new LiveView:

### 1. Add assigns in mount

```elixir
socket
|> assign(
  auth_blocked: false,
  auth_warning: false,
  auth_warning_message: ""
)
```

### 2. Add single handle_info

```elixir
@impl true
def handle_info({:sse_event, event, payload}, socket) do
  {:noreply, AuthEventHandler.handle_sse_event(socket, event, payload, &load_my_data/1)}
end
```

### 3. Add dismiss handler

```elixir
def handle_event("dismiss_auth_warning", _params, socket) do
  {:noreply, assign(socket, auth_warning: false, auth_warning_message: "")}
end
```

### 4. Add component to render

```heex
<.auth_event_listener
  auth_blocked={@auth_blocked}
  auth_warning={@auth_warning}
  auth_warning_message={@auth_warning_message}
/>
```

## Testing

1. **Hard event**: From IEx, broadcast `user_disabled` to the logged-in user's topic. Expect: blocking overlay, session cleared, redirect to `/login`.
2. **Medium event**: Broadcast `group_disabled`. Expect: warning banner with "Reload" and "Dismiss" buttons.
3. **Soft event**: Broadcast `permission_assigned`. Expect: data silently refreshes, no visible notification.
4. **Session cleared**: After a hard block, navigate to a protected route directly. Expect: redirect to `/login` (session is gone).
5. **Multiple tabs**: Open 2 tabs, trigger a hard event. Both tabs should show the blocking overlay.

```elixir
# Example IEx broadcast for testing
Phoenix.PubSub.broadcast(
  KeenAuthPermissionsTest.PubSub,
  "keen_auth:user:1",
  {:sse_event, "user_disabled", %{}}
)
```
