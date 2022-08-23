defmodule KeenAuthPermissions.Mapper.Email do
  alias KeenAuthPermissions.User

  @behaviour KeenAuth.Mapper

  @impl true
  def map(:email, user) do
    struct(User, user)
  end
end
