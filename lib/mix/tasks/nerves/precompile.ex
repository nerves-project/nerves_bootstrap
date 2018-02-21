defmodule Mix.Tasks.Nerves.Precompile do
  use Mix.Task
  import Mix.Nerves.IO

  def run(_args) do
    debug_info("Precompile Start")

    # Note: We have to directly use the environment variable here instead of
    # calling Nerves.Env.enabled?/0 because the nerves.precompile step happens
    # before the nerves dependency is compiled, which is where Nerves.Env
    # currently lives. This would be improved by moving Nerves.Env to
    # nerves_bootstrap.
    unless System.get_env("NERVES_ENV_DISABLED") do
      System.put_env("NERVES_PRECOMPILE", "1")

      Mix.Tasks.Nerves.Env.run([])

      Nerves.Env.packages()
      |> compile_check()
      |> Enum.each(&compile/1)

      Mix.Task.reenable("deps.compile")
      Mix.Task.reenable("compile")

      System.put_env("NERVES_PRECOMPILE", "0")

      Mix.Task.rerun("nerves.loadpaths")
    end

    debug_info("Precompile End")
  end

  defp compile(%{app: app}) do
    cond do
      Mix.Project.config()[:app] == app ->
        Mix.Tasks.Compile.run([app, "--include-children"])

      true ->
        Mix.Tasks.Deps.Compile.run([app, "--no-deps-check", "--include-children"])
    end
  end

  defp compile_check(packages) do
    stale =
      packages
      |> Enum.reject(&(Mix.Project.config()[:app] == &1.app))
      |> Enum.filter(&(:nerves_package in Map.get(&1, :compilers, Mix.compilers())))
      |> Enum.filter(&(Nerves.Artifact.expand_sites(&1) != []))
      |> Enum.filter(&Nerves.Artifact.stale?/1)
      |> Enum.reject(&Keyword.get(Map.get(&1, :dep_opts, []), :compile, false))

    case stale do
      [] ->
        packages

      packages ->
        stale_packages =
          packages
          |> Enum.map(&Map.get(&1, :app))
          |> Enum.map(&Atom.to_string/1)
          |> Enum.join("\n  ")

        example = List.first(packages)

        Mix.raise("""

        The following Nerves packages need to be built:

          #{stale_packages}

        The build process for each of these can take a significant amount of
        time so the maintainers have listed URLs for downloading pre-built packages.
        If you have not modified these packages, please try running `mix deps.get`
        or `mix deps.update` to download the precompiled versions.

        If you have limited network access and are able to obtain the files via
        other means, copy them to `~/.nerves/dl` or the location specified by
        `$NERVES_DL_DIR`.

        If you are making modifications to one of the packages or want to force
        local compilation, add `nerves_compile: true` to the dependency. For
        example:

          {:#{example.app}, "~> #{example.version}", nerves: [compile: true]}

        If the package is a dependency of a dependency, you will need to
        override it on the parent project with `override: true`.
        """)
    end
  end
end
