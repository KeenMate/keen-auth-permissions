defmodule KeenAuthPermissions.Managers.ManagerHelpers do
  def user(conn) when conn.assigns.current_user != nil, do: conn.assigns.current_user

  @doc """
  Ensure that variable is number
  """
  def num(n) when is_bitstring(n) do
    {n, _} = Integer.parse(n)
    n
  end

  def num(n) when is_number(n), do: n
end
