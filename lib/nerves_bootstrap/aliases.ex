defmodule Nerves.Bootstrap.Aliases do
  def init() do
    with %{} <- Mix.ProjectStack.peek(),
         %{name: name, config: config, file: file} <- Mix.ProjectStack.pop(),
         nil <- Mix.ProjectStack.peek() do
      target = System.get_env("MIX_TARGET")

      config =
        config
        |> host_config()
        |> target_config(target)

      Mix.ProjectStack.push(name, config, file)
    else
      # We are not at the top of the stack. Do nothing.
      _ ->
        :noop
    end
  end

  def host_config(config) do
    update_in(config, [:aliases], &add_host_aliases(&1))
  end

  def target_config(config, target) when target in [nil, "host"], do: config

  def target_config(config, _target) do
    update_in(config, [:aliases], &add_target_aliases(&1))
  end

  def add_aliases(aliases) do
    aliases
    |> add_host_aliases()
    |> add_target_aliases()
  end

  def add_host_aliases(aliases) do
    aliases
    |> append("deps.get", "nerves.deps.get")
    |> replace("deps.update", &Nerves.Bootstrap.Aliases.deps_update/1)
  end

  def add_target_aliases(aliases) do
    aliases
    |> prepend("deps.loadpaths", "nerves.loadpaths")
    |> replace("run", &Nerves.Bootstrap.Aliases.run/1)
  end

  def run(args) do
    case System.get_env("MIX_TARGET") do
      nil ->
        Mix.Tasks.Run.run(args)

      target ->
        Mix.raise("""
        You are trying to run code compiled for #{target}
        on your host. Please unset MIX_TARGET to run in host mode.
        """)
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
    Keyword.update(aliases, key, [na, a], &[na | drop(&1, na)])
  end

  defp replace(aliases, a, fun) do
    key = String.to_atom(a)
    Keyword.update(aliases, key, [fun], &(drop(&1, fun) ++ [fun]))
  end

  defp drop(aliases, a) do
    Enum.reject(aliases, &(&1 === a))
  end
end
