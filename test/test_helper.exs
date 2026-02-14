# Load support files
Code.require_file("support/test_repo.ex", __DIR__)
Code.require_file("support/test_database.ex", __DIR__)
Code.require_file("support/test_factory.ex", __DIR__)
Code.require_file("support/data_case.ex", __DIR__)

# Start ExUnit
ExUnit.start(exclude: [:skip])

# Start the test repo
case KeenAuthPermissions.TestRepo.start_link() do
  {:ok, _pid} ->
    IO.puts("TestRepo started successfully")

  {:error, {:already_started, _pid}} ->
    IO.puts("TestRepo already started")

  {:error, reason} ->
    IO.puts("Warning: Failed to start TestRepo: #{inspect(reason)}")
    IO.puts("Some tests may fail if database is not available")
end
