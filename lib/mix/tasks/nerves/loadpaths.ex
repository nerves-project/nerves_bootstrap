defmodule Mix.Tasks.Nerves.Loadpaths do
  use Mix.Task
  import Mix.Nerves.IO

  def run(_args) do
    unless System.get_env("NERVES_PRECOMPILE") == "1" do
      debug_info("Loadpaths Start")
      
      case Code.ensure_compiled?(Nerves.Env) do
        true ->
          try do
            Mix.Task.run("nerves.env", [])
            Nerves.Env.bootstrap()
            reload_cache()
            env_info()
          rescue
            e ->
              reraise e, System.stacktrace()
          end
        false ->
          Mix.Task.run("nerves.precompile")
      end
      debug_info("Loadpaths End")
    end
  end

  def env(k) do
    case System.get_env(k) do
      unset when unset == nil or unset == "" -> "unset"
      set -> Path.relative_to_cwd(set)
    end
  end

  def env_info do
    debug_info("Environment Variable List", """
      target:     #{Mix.Project.config()[:target] || "unset"}
      toolchain:  #{env("NERVES_TOOLCHAIN")}
      system:     #{env("NERVES_SYSTEM")}
      app:        #{env("NERVES_APP")}
    """)
  end

  defp reload_cache do
    # Fetch the app names from the cached dependencies
    #  Then consult the Mix.ProjectStack to get the 
    #  Mixfile module and purge it from the code server
    # This will force the reevaluation of the dependency
    #  ensuring that it is evaluated agains the bootstrapped env
    Mix.Dep.cached()
    |> Enum.map(&Map.get(&1, :app))
    |> Enum.uniq
    |> Enum.map(&Mix.ProjectStack.read_cache({:app, &1}))
    |> Enum.each(fn({mod, _file}) ->  
      :code.purge(mod)
      :code.delete(mod)
    end)

    # Clear the Mix.ProjectStack cache
    Mix.ProjectStack.clear_cache()

    :ok
  end
end
