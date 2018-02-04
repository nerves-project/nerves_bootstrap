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
      parent = Mix.Project.config()[:app]
      system_app = Nerves.Env.system().app

      {m, f, a} =
        if parent == system_app do
          Mix.Tasks.Deps.Compile.run([Nerves.Env.toolchain().app, "--include-children"])
          {Mix.Tasks.Compile, :run, [["--no-deps-check"]]}
        else
          system_app_name = to_string(system_app)
          {Mix.Tasks.Deps.Compile, :run, [[system_app_name, "--include-children"]]}
        end

      apply(m, f, a)
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
      Mix.raise("""
      
        Nerves is missing an alias for \"deps.get\"
        Please update nerves to the latest version:

        mix deps.update nerves
        
        Also update your mix.exs target aliases to:
        
        defp aliases(_target) do
          [
            "deps.get": "nerves.deps.get",
            "deps.loadpaths": "nerves.loadpaths",
            "deps.update": "nerves.deps.update"
          ]
        end

      """)
    end
  end

end
