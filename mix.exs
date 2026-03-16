# SPDX-FileCopyrightText: None
# SPDX-License-Identifier: CC0-1.0
defmodule NervesBootstrap.MixProject do
  use Mix.Project

  @version "1.15.1"
  @source_url "https://github.com/nerves-project/nerves_bootstrap"

  def project do
    [
      app: :nerves_bootstrap,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: ["lib", "compat"],
      aliases: aliases(),
      xref: [exclude: [Nerves.Env, Hex, Hex.API.Package, EEx]],
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      test_coverage: [
        summary: [threshold: 75],
        ignore_modules: [Mix.Tasks.Local.Nerves, NervesBootstrap]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: %{
        dialyzer: :lint,
        docs: :docs,
        credo: :lint,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    # 1. Don't start Nerves tooling automatically when testing
    # 2. Don't include any `:extra_applications` even if they're need since
    #    user applications call `Application.start/1` and not
    #    `Application.ensure_all_started/`
    if Mix.env() in [:dev, :prod] do
      [mod: {NervesBootstrap, []}]
    else
      []
    end
  end

  def aliases do
    [
      install: [
        "archive.build -o nerves_bootstrap.ez",
        "archive.install nerves_bootstrap.ez --force"
      ]
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: :lint, runtime: false},
      {:dialyxir, "~> 1.1", only: :lint, runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp description do
    "Nerves mix integration bootstrap and new project generator"
  end

  defp package do
    [
      files: [
        "CHANGELOG.md",
        "compat",
        "lib",
        "LICENSES/*",
        "mix.exs",
        "NOTICE",
        "README.md",
        "REUSE.toml",
        "templates"
      ],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "REUSE Compliance" =>
          "https://api.reuse.software/info/github.com/nerves-project/nerves_bootstrap"
      }
    ]
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs],
      plt_add_apps: [:mix, :eex]
    ]
  end
end
