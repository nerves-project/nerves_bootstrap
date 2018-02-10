defmodule Nerves.Bootstrap.Aliases do
  
  def add_aliases(aliases) do
    aliases
    |> append("deps.get", "nerves.deps.get")
    |> prepend("deps.loadpaths", "nerves.loadpaths")
    |> replace("deps.update", &Nerves.Bootstrap.Aliases.deps_update/1)
    |> replace("run", &Nerves.Bootstrap.Aliases.run/1)
  end

  def run(args) do
    case System.get_env("MIX_TARGET") do
      nil ->
        Mix.Tasks.Run.run(args)
      target ->
        Mix.raise """
        You are trying to run code compiled for #{target}
        on your host. Please unset MIX_TARGET to run in host mode.
        """
    end
  end

  def deps_update(args) do
    Mix.Tasks.Deps.Update.run(args)
    Mix.Tasks.Nerves.Deps.Get.run([])
  end
  
  defp append(aliases, a, na) do
    key = String.to_atom(a)
    Keyword.update(aliases, key, [a, na], &(drop(&1, na) ++ [na]))
  end
  
  defp prepend(aliases, a, na) do
    key = String.to_atom(a)
    Keyword.update(aliases, key, [na, a], &([na | drop(&1, na)]))
  end

  defp replace(aliases, a, fun) do
    key = String.to_atom(a)
    Keyword.update(aliases, key, [fun], &(drop(&1, fun) ++ [fun]))
  end

  defp drop(aliases, a) do
    Enum.reject(aliases, &(&1 === a))
  end

end
