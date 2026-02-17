defmodule KeenAuthPermissions.MixProject do
  use Mix.Project

  def project do
    [
      app: :keen_auth_permissions,
      version: "0.2.0",
      elixir: "~> 1.14",
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
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:keen_auth, "~> 1.0"},
      {:jason, "~> 1.4"},
      {:postgrex, "~> 0.19"},
      {:pbkdf2_elixir, "~> 2.0"}
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
      files: ~w(lib .formatter.exs mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KeenMate/keen_auth_permissions"}
    ]
  end
end
