defmodule KeenAuthPermissions.MixProject do
  use Mix.Project

  def project do
    [
      app: :keen_auth_permissions,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:keen_auth, github: "keenmate/keen_auth", branch: "new-vision"},
      {:jason, "~> 1.3"},
      {:postgrex, "~> 0.16.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
