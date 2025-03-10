defmodule Nerves.Bootstrap.MixProject do
  use Mix.Project

  @version "1.13.1"
  @source_url "https://github.com/nerves-project/nerves_bootstrap"

  def project do
    [
      app: :nerves_bootstrap,
      version: @version,
      elixir: "~> 1.13",
      aliases: aliases(),
      xref: [exclude: [Nerves.Env, Hex, Hex.API.Package, EEx]],
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps(),
      dialyzer: dialyzer(),
      preferred_cli_env: %{
        credo: :lint,
        dialyzer: :lint,
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {Nerves.Bootstrap, []}
    ]
  end

  def aliases do
    [
      "compile.elixir": [&unload_bootstrap/1, "compile.elixir"],
      run: [&unload_bootstrap/1, "run"],
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

  defp unload_bootstrap(_) do
    Application.stop(:nerves_bootstrap)
    paths = Path.wildcard(Path.join(archives_path(), "nerves_bootstrap*"))

    Enum.each(paths, fn archive ->
      ebin = archive_ebin(archive)
      Code.delete_path(ebin)

      {:ok, files} = ebin |> :unicode.characters_to_list() |> :erl_prim_loader.list_dir()

      Enum.each(files, fn file ->
        file = List.to_string(file)
        size = byte_size(file) - byte_size(".beam")

        case file do
          <<name::binary-size(size), ".beam">> ->
            module = String.to_atom(name)
            :code.delete(module)
            :code.purge(module)

          _ ->
            :ok
        end
      end)
    end)
  end

  defp archives_path do
    cond do
      function_exported?(Mix, :path_for, 1) -> apply(Mix, :path_for, [:archives])
      function_exported?(Mix.Local, :path_for, 1) -> apply(Mix.Local, :path_for, [:archive])
      true -> apply(Mix.Local, :archives_path, [])
    end
  end

  defp archive_ebin(archive) do
    if function_exported?(Mix.Local, :archive_ebin, 1),
      do: apply(Mix.Local, :archive_ebin, [archive]),
      else: apply(Mix.Archive, :ebin, [archive])
  end
end
