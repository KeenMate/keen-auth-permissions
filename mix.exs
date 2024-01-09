defmodule KeenAuthPermissions.MixProject do
  use Mix.Project

  def project do
    [
      app: :keen_auth_permissions,
      version: "0.1.1",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:keen_auth, "~> 0.2.2"},
      {:jason, "~> 1.3"},
      {:postgrex, "~> 0.16.4"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp description() do
    """
    Library that extends base `keen_auth` by providing necessary logic for permissions handling
    """
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "keen_auth_permissions",
      # organization: "keenmate",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KeenMate/keen_auth_permissions"}
    ]
  end
end
