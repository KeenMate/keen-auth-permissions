defmodule KeenAuthPermissions.Error.ErrorStruct do
  @keys [:reason, :message, :metadata]
  @enforce_keys [:reason]

  defstruct @keys

  @type t() :: %__MODULE__{
          reason: atom(),
          message: binary() | nil,
          metadata: map() | nil
        }

  @spec create(any, any, any) :: struct
  def create(reason, message, metadata \\ nil) do
    struct(__MODULE__, %{reason: reason, message: message, metadata: metadata})
  end
end
