defmodule Nerves.Bootstrap.Mixfile do
  use Mix.Project

  @version "1.7.1"
  @source_url "https://github.com/nerves-project/nerves_bootstrap"

  def project do
    [
      app: :nerves_bootstrap,
      version: @version,
      elixir: "~> 1.7",
      aliases: aliases(),
      xref: [exclude: [Nerves.Env, Nerves.Artifact]],
      docs: docs(),
      description: description(),
      package: package(),
      deps: deps()
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
      {:ex_doc, "~> 0.19", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Nerves mix integration bootstrap and new project generator"
  end

  defp package do
    [
      maintainers: ["Justin Schneck", "Frank Hunleth", "Greg Mefford"],
      files: ["lib", "LICENSE", "mix.exs", "README.md", "test", "templates"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
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
