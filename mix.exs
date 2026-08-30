defmodule KeenAuthPermissions.MixProject do
  use Mix.Project

  def project do
    [
      app: :keen_auth_permissions,
      version: "1.0.0-rc.10",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      name: "KeenAuthPermissions",
      source_url: "https://github.com/KeenMate/keen-auth-permissions",
      homepage_url: "https://hexdocs.pm/keen_auth_permissions"
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

  defp docs do
    [
      main: "readme",
      extras: [
        "README.md",
        "CHANGELOG.md",
        "docs/sse-event-handling.md",
        "LICENSE"
      ],
      before_closing_body_tag: &before_closing_body_tag/1,
      groups_for_modules: [
        Facades: [
          KeenAuthPermissions.Auth,
          KeenAuthPermissions.Users,
          KeenAuthPermissions.UserGroups,
          KeenAuthPermissions.Permissions,
          KeenAuthPermissions.Tenants,
          KeenAuthPermissions.PermSets,
          KeenAuthPermissions.ApiKeys,
          KeenAuthPermissions.ResourceAccess,
          KeenAuthPermissions.Blacklist,
          KeenAuthPermissions.Mfa,
          KeenAuthPermissions.Invitations,
          KeenAuthPermissions.Audit
        ],
        Core: [
          KeenAuthPermissions.User,
          KeenAuthPermissions.RequestContext,
          KeenAuthPermissions.PermissionHelpers,
          KeenAuthPermissions.PermissionsMap,
          KeenAuthPermissions.ServiceAccounts,
          KeenAuthPermissions.TokenTypes,
          KeenAuthPermissions.SysParams
        ],
        Providers: [
          KeenAuthPermissions.Providers.AuthProvider,
          KeenAuthPermissions.Providers.UsersProvider,
          KeenAuthPermissions.Providers.GroupsProvider,
          KeenAuthPermissions.Providers.PermissionsProvider
        ],
        Managers: [
          KeenAuthPermissions.Managers.UsersManager,
          KeenAuthPermissions.Managers.GroupsManager,
          KeenAuthPermissions.Managers.ManagerHelpers
        ],
        Processors: [
          KeenAuthPermissions.Processor.AzureAD,
          KeenAuthPermissions.Processor.Email,
          KeenAuthPermissions.Mapper.Email
        ],
        Plugs: [
          KeenAuthPermissions.Plug.RevalidateSession
        ],
        Database: [
          KeenAuthPermissions.Database,
          KeenAuthPermissions.DbContext
        ],
        Infrastructure: [
          KeenAuthPermissions.PgListener,
          KeenAuthPermissions.PgListener.Resolver,
          KeenAuthPermissions.EventClassification,
          KeenAuthPermissions.Notifier,
          KeenAuthPermissions.TenantResolver
        ],
        Errors: [
          KeenAuthPermissions.Error.ErrorParsers,
          KeenAuthPermissions.Error.ErrorStruct
        ],
        Utilities: [
          KeenAuthPermissions.Email,
          KeenAuthPermissions.Storage
        ]
      ],
      nest_modules_by_prefix: [
        KeenAuthPermissions.Providers,
        KeenAuthPermissions.Managers,
        KeenAuthPermissions.Processor,
        KeenAuthPermissions.PgListener,
        KeenAuthPermissions.Error
      ]
    ]
  end

  defp before_closing_body_tag(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({ startOnLoad: false, theme: "default" });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          graphEl.classList.add("mermaid-graph");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg}) => {
            graphEl.innerHTML = svg;
            preEl.replaceWith(graphEl);
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""

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
      files: ~w(lib docs .formatter.exs mix.exs README.md CHANGELOG.md LICENSE),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/KeenMate/keen_auth_permissions"}
    ]
  end
end
