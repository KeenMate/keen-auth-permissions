defmodule KeenAuthPermissions.Translations do
  @moduledoc """
  Facade for the i18n system — translations plus the language catalog they reference.

  Every translatable string in ppm is keyed by:

  - `language_code` (`"en"`, `"cs"`, ...)
  - `data_group` (`"permission"`, `"perm_set"`, `"resource_type"`, `"event_code"`, ...)
  - Either `data_object_code` (canonical text code) or `data_object_id` (numeric id)
  - `context` — the slot within that object (e.g. `"title"`, `"description"`, `"text"`)

  The `(language_code, data_group, data_object_key, context)` tuple is the unique
  translation row. `context` is not-null with a default of `"text"` (see 045 migration).

  ## Languages

  Each language has three capability flags:

  - `is_frontend_language` — available in user-facing UIs
  - `is_backend_language` — available for admin / backend rendering
  - `is_communication_language` — available for outbound emails / SMS / notifications

  Exactly one default per capability is allowed per tenant; the getters below
  return localized labels using `display_language_code`.
  """

  alias KeenAuthPermissions.User
  alias KeenAuthPermissions.RequestContext
  alias KeenAuthPermissions.Error.ErrorParsers

  defp db_context(), do: KeenAuthPermissions.DbContext.get_global_db_context()

  # ============================================================================
  # Translation CRUD
  # ============================================================================

  @doc """
  Creates a translation. Either `data_object_code` or `data_object_id` must be set.

  Options:
    * `:data_object_code` — canonical text key
    * `:data_object_id` — numeric key
    * `:context` — slot name; defaults to `"text"`
    * `:tenant_id` — defaults to `1`

  Calls `public.create_translation`.
  """
  @spec create(RequestContext.t(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, any()}
  def create(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        language_code,
        data_group,
        value,
        opts \\ []
      ) do
    data_object_code = Keyword.get(opts, :data_object_code)
    data_object_id = Keyword.get(opts, :data_object_id)
    context = Keyword.get(opts, :context, "text")
    tenant_id = Keyword.get(opts, :tenant_id, 1)

    case db_context().create_translation(
           username,
           user_id,
           request_id,
           language_code,
           data_group,
           value,
           data_object_code,
           data_object_id,
           context,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates the `value` of an existing translation row.

  Calls `public.update_translation`.
  """
  @spec update(RequestContext.t(), integer(), String.t(), integer()) ::
          {:ok, map()} | {:error, any()}
  def update(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        translation_id,
        value,
        tenant_id \\ 1
      ) do
    case db_context().update_translation(
           username,
           user_id,
           request_id,
           translation_id,
           value,
           tenant_id
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc "Deletes a translation. Calls `public.delete_translation`."
  @spec delete(RequestContext.t(), integer(), integer()) :: :ok | {:error, any()}
  def delete(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        translation_id,
        tenant_id \\ 1
      ) do
    db_context().delete_translation(username, user_id, request_id, translation_id, tenant_id)
  end

  # ============================================================================
  # Translation queries
  # ============================================================================

  @doc """
  Searches translations. All filter args except `display_language_code`, page,
  and `tenant_id` are optional — pass `nil` to skip.

  `display_language_code` controls the language of any labels returned; the
  `language_code` filter scopes *which* rows are searched by target language.

  Calls `public.search_translations`.
  """
  @spec search(
          RequestContext.t(),
          String.t(),
          keyword()
        ) :: {:ok, list(map())} | {:error, any()}
  def search(
        %RequestContext{user: %User{user_id: user_id}, request_id: request_id},
        display_language_code,
        opts \\ []
      ) do
    search_text = Keyword.get(opts, :search_text)
    language_code = Keyword.get(opts, :language_code)
    data_group = Keyword.get(opts, :data_group)
    data_object_code = Keyword.get(opts, :data_object_code)
    data_object_id = Keyword.get(opts, :data_object_id)
    context = Keyword.get(opts, :context)
    page = Keyword.get(opts, :page, 1)
    page_size = Keyword.get(opts, :page_size, 50)
    tenant_id = Keyword.get(opts, :tenant_id, 1)

    db_context().search_translations(
      user_id,
      request_id,
      display_language_code,
      search_text,
      language_code,
      data_group,
      data_object_code,
      data_object_id,
      context,
      page,
      page_size,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Fetches every translation in a `data_group` for a language + context slot.

  Useful for hydrating a full dictionary for UI rendering (e.g. every
  `permission` title in `"en"`).

  Calls `public.get_group_translations`.
  """
  @spec get_group(String.t(), String.t(), String.t(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def get_group(language_code, data_group, context \\ "text", tenant_id \\ 1) do
    db_context().get_group_translations(language_code, data_group, context, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Copies translations between languages (e.g. seed a new language from existing
  English rows). When `overwrite` is `false`, existing target rows are preserved.

  If `data_group` is nil, all groups are copied.

  Calls `public.copy_translations`.
  """
  @spec copy(
          RequestContext.t(),
          String.t(),
          String.t(),
          keyword()
        ) :: {:ok, list()} | {:error, any()}
  def copy(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        from_language_code,
        to_language_code,
        opts \\ []
      ) do
    overwrite = Keyword.get(opts, :overwrite, false)
    data_group = Keyword.get(opts, :data_group)
    from_tenant_id = Keyword.get(opts, :from_tenant_id, 1)
    to_tenant_id = Keyword.get(opts, :to_tenant_id, 1)
    tenant_id = Keyword.get(opts, :tenant_id, 1)

    db_context().copy_translations(
      username,
      user_id,
      request_id,
      from_language_code,
      to_language_code,
      overwrite,
      data_group,
      from_tenant_id,
      to_tenant_id,
      tenant_id
    )
    |> ErrorParsers.parse_if_error()
  end

  # ============================================================================
  # Languages
  # ============================================================================

  @doc """
  Creates a new language entry.

  Options toggle capability flags and default-per-capability status. Pass
  `logical_order` keys for explicit sort positions in selector UIs.

  Options:
    * `:is_frontend_language` / `:is_backend_language` / `:is_communication_language`
    * `:frontend_logical_order` / `:backend_logical_order` / `:communication_logical_order`
    * `:is_default_frontend` / `:is_default_backend` / `:is_default_communication`
    * `:custom_data` — arbitrary JSONB
    * `:tenant_id` — defaults to `1`

  Calls `public.create_language`.
  """
  @spec create_language(RequestContext.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, any()}
  def create_language(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        value,
        opts \\ []
      ) do
    case db_context().create_language(
           username,
           user_id,
           request_id,
           code,
           value,
           Keyword.get(opts, :is_frontend_language, true),
           Keyword.get(opts, :is_backend_language, true),
           Keyword.get(opts, :is_communication_language, true),
           Keyword.get(opts, :frontend_logical_order, 0),
           Keyword.get(opts, :backend_logical_order, 0),
           Keyword.get(opts, :communication_logical_order, 0),
           Keyword.get(opts, :is_default_frontend, false),
           Keyword.get(opts, :is_default_backend, false),
           Keyword.get(opts, :is_default_communication, false),
           Keyword.get(opts, :custom_data),
           Keyword.get(opts, :tenant_id, 1)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :creation_failed}
      error -> error
    end
  end

  @doc """
  Updates an existing language. Accepts the same options as `create_language/4`.

  Calls `public.update_language`.
  """
  @spec update_language(RequestContext.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, any()}
  def update_language(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        value,
        opts \\ []
      ) do
    case db_context().update_language(
           username,
           user_id,
           request_id,
           code,
           value,
           Keyword.get(opts, :is_frontend_language, true),
           Keyword.get(opts, :is_backend_language, true),
           Keyword.get(opts, :is_communication_language, true),
           Keyword.get(opts, :frontend_logical_order, 0),
           Keyword.get(opts, :backend_logical_order, 0),
           Keyword.get(opts, :communication_logical_order, 0),
           Keyword.get(opts, :is_default_frontend, false),
           Keyword.get(opts, :is_default_backend, false),
           Keyword.get(opts, :is_default_communication, false),
           Keyword.get(opts, :custom_data),
           Keyword.get(opts, :tenant_id, 1)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :update_failed}
      error -> error
    end
  end

  @doc "Deletes a language. Calls `public.delete_language`."
  @spec delete_language(RequestContext.t(), String.t(), integer()) :: :ok | {:error, any()}
  def delete_language(
        %RequestContext{
          user: %User{username: username, user_id: user_id},
          request_id: request_id
        },
        code,
        tenant_id \\ 1
      ) do
    db_context().delete_language(username, user_id, request_id, code, tenant_id)
  end

  @doc """
  Returns a single language by code, or `:not_found`.

  Calls `public.get_language`.
  """
  @spec get_language(String.t()) :: {:ok, map()} | {:error, any()}
  def get_language(code) do
    case db_context().get_language(code)
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc """
  Lists languages with optional capability filters.

  `is_frontend` / `is_backend` / `is_communication` are three-valued — pass
  `nil` to not filter on the capability, `true` / `false` to narrow.

  Options:
    * `:is_frontend` / `:is_backend` / `:is_communication`
    * `:tenant_id` — defaults to `1`

  Calls `public.get_languages`.
  """
  @spec list_languages(String.t(), keyword()) :: {:ok, list(map())} | {:error, any()}
  def list_languages(display_language_code \\ "en", opts \\ []) do
    db_context().get_languages(
      display_language_code,
      Keyword.get(opts, :is_frontend),
      Keyword.get(opts, :is_backend),
      Keyword.get(opts, :is_communication),
      Keyword.get(opts, :tenant_id, 1)
    )
    |> ErrorParsers.parse_if_error()
  end

  @doc """
  Returns the default language for a given capability.

  Exactly one of `:is_frontend` / `:is_backend` / `:is_communication` should be
  `true` — that's the capability whose default is requested.

  Calls `public.get_default_language`.
  """
  @spec get_default_language(String.t(), keyword()) :: {:ok, map()} | {:error, any()}
  def get_default_language(display_language_code \\ "en", opts \\ []) do
    case db_context().get_default_language(
           display_language_code,
           Keyword.get(opts, :is_frontend, false),
           Keyword.get(opts, :is_backend, false),
           Keyword.get(opts, :is_communication, false),
           Keyword.get(opts, :tenant_id, 1)
         )
         |> ErrorParsers.parse_if_error() do
      {:ok, [result]} -> {:ok, result}
      {:ok, []} -> {:error, :not_found}
      error -> error
    end
  end

  @doc "Shortcut for frontend languages. Calls `public.get_frontend_languages`."
  @spec list_frontend_languages(String.t(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def list_frontend_languages(display_language_code \\ "en", tenant_id \\ 1) do
    db_context().get_frontend_languages(display_language_code, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc "Shortcut for backend languages. Calls `public.get_backend_languages`."
  @spec list_backend_languages(String.t(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def list_backend_languages(display_language_code \\ "en", tenant_id \\ 1) do
    db_context().get_backend_languages(display_language_code, tenant_id)
    |> ErrorParsers.parse_if_error()
  end

  @doc "Shortcut for communication languages. Calls `public.get_communication_languages`."
  @spec list_communication_languages(String.t(), integer()) ::
          {:ok, list(map())} | {:error, any()}
  def list_communication_languages(display_language_code \\ "en", tenant_id \\ 1) do
    db_context().get_communication_languages(display_language_code, tenant_id)
    |> ErrorParsers.parse_if_error()
  end
end
