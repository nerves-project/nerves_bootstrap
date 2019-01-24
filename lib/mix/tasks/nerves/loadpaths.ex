defmodule Mix.Tasks.Nerves.Loadpaths do
  use Mix.Task
  import Mix.Nerves.IO

  @moduledoc false

  def run(_args) do
    unless System.get_env("NERVES_PRECOMPILE") == "1" do
      debug_info("Loadpaths Start")

      case Code.ensure_compiled?(Nerves.Env) do
        true ->
          try do
            nerves_env_info()
            Mix.Task.run("nerves.env", [])
            Nerves.Env.bootstrap()
            clear_deps_cache()
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
      target:     #{Nerves.Bootstrap.mix_target()}
      toolchain:  #{env("NERVES_TOOLCHAIN")}
      system:     #{env("NERVES_SYSTEM")}
      app:        #{env("NERVES_APP")}
    """)
  end

  defp clear_deps_cache() do
    if :erlang.function_exported(Mix.Project, :clear_deps_cache, 0) do
      apply(Mix.Project, :clear_deps_cache, [])
    else
      if project = Mix.Project.get() do
        key = {:cached_deps, Mix.env(), project}
        Agent.cast(Mix.ProjectStack, &%{&1 | cache: Map.delete(&1.cache, key)})
      end
    end
  end
end
