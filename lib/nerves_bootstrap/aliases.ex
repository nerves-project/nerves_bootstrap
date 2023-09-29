defmodule Nerves.Bootstrap.Aliases do
  @moduledoc false

  @spec init() :: :ok
  def init() do
    with %{} <- Mix.ProjectStack.peek(),
         %{name: name, config: config, file: file} <- Mix.ProjectStack.pop(),
         nil <- Mix.ProjectStack.peek() do
      adjusted_config =
        config
        |> update_host_config()
        |> update_target_config(Nerves.Bootstrap.mix_target())

      :ok = Mix.ProjectStack.push(name, adjusted_config, file)
    else
      # We are not at the top of the stack. Do nothing.
      _ ->
        :ok
    end
  end

  defp update_host_config(config) do
    update_in(config, [:aliases], &add_host_aliases(&1))
  end

  defp update_target_config(config, :host), do: config

  defp update_target_config(config, _target) do
    update_in(config, [:aliases], &add_target_aliases(&1))
  end

  @spec add_aliases(keyword()) :: keyword()
  def add_aliases(aliases) do
    aliases
    |> add_host_aliases()
    |> add_target_aliases()
  end

  @spec add_host_aliases(keyword()) :: keyword()
  def add_host_aliases(aliases) do
    aliases
    |> append("deps.get", "nerves.bootstrap")
    |> append("deps.get", "nerves.deps.get")
    |> prepend("deps.precompile", "nerves.bootstrap")
    |> replace("deps.update", &Nerves.Bootstrap.Aliases.deps_update/1)
  end

  @spec add_target_aliases(keyword()) :: keyword()
  def add_target_aliases(aliases) do
    aliases
    |> prepend("deps.loadpaths", "nerves.loadpaths")
    |> prepend("deps.loadpaths", "nerves.bootstrap")
    |> prepend("deps.compile", "nerves.loadpaths")
    |> prepend("deps.compile", "nerves.bootstrap")
    |> replace("run", &Nerves.Bootstrap.Aliases.run/1)
  end

  @spec run([String.t()]) :: :ok
  def run(args) do
    case Nerves.Bootstrap.mix_target() do
      :host ->
        Mix.Tasks.Run.run(args)

      target ->
        msg = """
        You are trying to run code compiled for #{target}
        on your host. Please unset MIX_TARGET to run in host mode.
        """

        Mix.shell().error([:inverse, :red, "|nerves_bootstrap| ", msg, :reset])
    end
  end

  @spec deps_update([String.t()]) :: :ok
  def deps_update(args) do
    Mix.Tasks.Deps.Update.run(args)
    Mix.Task.run("nerves.bootstrap", [])
    Mix.Task.run("nerves.deps.get", [])
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
