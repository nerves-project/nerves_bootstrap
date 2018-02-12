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

      Mix.Project.config()[:aliases]
      |> check_aliases()

      Mix.Tasks.Nerves.Env.run([])

      Nerves.Env.packages()
      |> Enum.each(&compile/1)

      Mix.Task.reenable("deps.compile")
      Mix.Task.reenable("compile")

      System.put_env("NERVES_PRECOMPILE", "0")

      Mix.Task.rerun("nerves.loadpaths")
    end

    debug_info("Precompile End")
  end

  def check_aliases(aliases) do
    deps_get = Keyword.get(aliases, String.to_atom("deps.get"), [])

    unless Enum.member?(deps_get, "nerves.deps.get") do
      Code.ensure_loaded(Nerves.Bootstrap)
      Nerves.Bootstrap.update_text()
      |> Mix.raise()
    end
  end

  defp compile(%{app: app}) do
    cond do
      Mix.Project.config()[:app] == app ->
        Mix.Tasks.Compile.run([app, "--include-children"])

      true ->
        Mix.Tasks.Deps.Compile.run([app, "--no-deps-check", "--include-children"])
    end
  end
end
