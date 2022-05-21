defmodule Nerves.Bootstrap.Aliases do
  @moduledoc false

  @type instruction :: (list() -> list())

  @spec init() :: :ok
  def init() do
    with %{} <- Mix.ProjectStack.peek(),
         nerves_ver = Nerves.Bootstrap.nerves_version(),
         %{name: name, config: config, file: file} <- Mix.ProjectStack.pop(),
         nil <- Mix.ProjectStack.peek() do
      instructions = instructions_for_nerves_version(nerves_ver)

      adjusted_config =
        config
        |> update_host_config(instructions.host)
        |> update_target_config(Nerves.Bootstrap.mix_target(), instructions.target)

      :ok = Mix.ProjectStack.push(name, adjusted_config, file)
    else
      # We are not at the top of the stack. Do nothing.
      _ ->
        :ok
    end
  end

  defp instructions_for_nerves_version(ver) do
    if not is_nil(ver) and Version.match?(ver, "< 1.8.0") do
      %{
        host: [
          &append(&1, "deps.get", "nerves.bootstrap.deps.get"),
          fn a -> replace(a, "deps.update", &__MODULE__.old_deps_update/1) end,
          &replace(&1, "nerves.clean", "nerves.bootstrap.clean"),
          &replace(&1, "nerves.system.shell", "nerves.bootstrap.system.shell")
        ],
        target: [
          &prepend(&1, "deps.loadpaths", "nerves.bootstrap.loadpaths"),
          &prepend(&1, "deps.compile", "nerves.bootstrap.loadpaths")
        ]
      }
    else
      %{
        host: [
          &append(&1, "deps.get", "nerves.bootstrap"),
          &append(&1, "deps.get", "nerves.deps.get"),
          fn a -> replace(a, "deps.update", &__MODULE__.deps_update/1) end
        ],
        target: [
          &prepend(&1, "deps.loadpaths", "nerves.loadpaths"),
          &prepend(&1, "deps.loadpaths", "nerves.bootstrap"),
          &prepend(&1, "deps.compile", "nerves.loadpaths"),
          &prepend(&1, "deps.compile", "nerves.bootstrap")
        ]
      }
    end
  end

  defp update_host_config(config, instructions) do
    update_in(config, [:aliases], &add_host_aliases(&1, instructions))
  end

  defp update_target_config(config, :host, _), do: config

  defp update_target_config(config, _target, instructions) do
    update_in(config, [:aliases], &add_target_aliases(&1, instructions))
  end

  @spec add_aliases(keyword(), Version.version() | nil) :: keyword()
  def add_aliases(aliases, nerves_version \\ nil) do
    instructions = instructions_for_nerves_version(nerves_version)

    aliases
    |> add_host_aliases(instructions.host)
    |> add_target_aliases(instructions.target)
  end

  @spec add_host_aliases(keyword()) :: keyword()
  @deprecated "Use add_host_aliases/2"
  def add_host_aliases(aliases) do
    aliases
    |> append("deps.get", "nerves.deps.get")
    |> replace("deps.update", &Nerves.Bootstrap.Aliases.deps_update/1)
  end

  @spec add_target_aliases(keyword()) :: keyword()
  @deprecated "Use add_target_aliases/2"
  def add_target_aliases(aliases) do
    aliases
    |> prepend("deps.loadpaths", "nerves.loadpaths")
    |> prepend("deps.compile", "nerves.loadpaths")
    |> replace("run", &Nerves.Bootstrap.Aliases.run/1)
  end

  @spec add_host_aliases(keyword(), [instruction()]) :: keyword()
  def add_host_aliases(aliases, instructions) do
    Enum.reduce(instructions, aliases, & &1.(&2))
  end

  @spec add_target_aliases(keyword(), [instruction()]) :: keyword()
  def add_target_aliases(aliases, instructions) do
    Enum.reduce(instructions, aliases, & &1.(&2))
    |> replace("run", &Nerves.Bootstrap.Aliases.run/1)
  end

  @spec run([String.t()]) :: :ok
  def run(args) do
    case Nerves.Bootstrap.mix_target() do
      :host ->
        Mix.Tasks.Run.run(args)

      target ->
        Mix.Nerves.Bootstrap.IO.shell_warn("""
        You are trying to run code compiled for #{target}
        on your host. Please unset MIX_TARGET to run in host mode.
        """)
    end
  end

  @spec deps_update([String.t()]) :: :ok
  def deps_update(args) do
    Mix.Nerves.Bootstrap.IO.debug_info("deps.update start")
    Mix.Tasks.Deps.Update.run(args)
    Mix.Task.run("nerves.bootstrap", [])
    Mix.Task.run("nerves.deps.get", [])
    Mix.Nerves.Bootstrap.IO.debug_info("deps.update end")
  end

  @spec old_deps_update([String.t()]) :: :ok
  def old_deps_update(args) do
    Mix.Nerves.Bootstrap.IO.debug_info("deps.update start")
    Mix.Tasks.Deps.Update.run(args)
    Mix.Tasks.Nerves.Bootstrap.Deps.Get.run([])
    Mix.Nerves.Bootstrap.IO.debug_info("deps.update end")
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
