defmodule Mjw.MixProject do
  use Mix.Project

  def project do
    [
      app: :mjw,
      version: "1.0.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Mjw.Application, []},
      extra_applications: [:logger, :crypto, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.21"},
      {:phoenix_html, "~> 4.2"},
      {:phoenix_live_reload, "~> 1.3", only: :dev},
      {:phoenix_live_view, "~> 1.0"},
      {:floki, "~> 0.38", only: :test},
      {:phoenix_live_dashboard, "~> 0.8"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.19"},
      {:finch, "~> 0.20"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.3"},
      {:gettext, "~> 0.26"},
      {:jason, "~> 1.4"},
      {:dns_cluster, "~> 0.2"},
      {:bandit, "~> 1.7"},
      {:dart_sass, "~> 0.7", runtime: Mix.env() == :dev},
      {:ex_cldr_numbers, "~> 2.35"},

      # Normally we'd use Ecto for UUID generation
      {:uniq, "~> 0.6"},
      # Static code analysis
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "assets.setup", "assets.build"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": [
        "sass default --no-source-map --style=compressed",
        "tailwind default --minify",
        "esbuild default --minify"
      ],
      "assets.deploy": ["assets.build", "phx.digest"]
    ]
  end
end
