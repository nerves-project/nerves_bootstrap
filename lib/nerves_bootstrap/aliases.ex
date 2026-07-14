# SPDX-FileCopyrightText: 2018 Justin Schneck
# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.Aliases do
  @moduledoc false

  @spec inject_aliases_if_top((keyword() -> keyword())) :: :ok
  def inject_aliases_if_top(add_aliases_fn) do
    with %{} <- Mix.ProjectStack.peek(),
         %{name: name, config: config, file: file} <- Mix.ProjectStack.pop(),
         nil <- Mix.ProjectStack.peek() do
      adjusted_config = update_in(config, [:aliases], add_aliases_fn)

      :ok = Mix.ProjectStack.push(name, adjusted_config, file)
    else
      # We are not at the top of the stack. Do nothing.
      _ -> :ok
    end
  end

  @spec add_aliases(keyword()) :: keyword()
  def add_aliases(aliases) do
    aliases
    |> prepend("deps.loadpaths", "nerves_bootstrap.init")
    |> prepend("compile", "nerves_bootstrap.init")
    |> replace("run", &NervesBootstrap.Aliases.run/1)
  end

  @spec add_error_report_aliases(String.t(), keyword()) :: keyword()
  def add_error_report_aliases(msg, aliases) do
    raise_fun = raise_alias(msg)

    aliases
    |> replace("deps.get", raise_fun)
    |> replace("deps.loadpaths", raise_fun)
    |> replace("deps.update", raise_fun)
    |> replace("loadpaths", raise_fun)
    |> replace("compile", raise_fun)
  end

  @spec add_no_compilation_aliases(String.t(), keyword()) :: keyword()
  def add_no_compilation_aliases(msg, aliases) do
    raise_fun = raise_alias(msg)

    aliases
    |> replace("deps.compile", raise_fun)
    |> replace("compile", raise_fun)
  end

  @spec raise_alias(String.t()) :: (term() -> no_return())
  defp raise_alias(msg) do
    fn _ -> Mix.raise(msg) end
  end

  @spec add_aliases_v1(atom(), keyword()) :: keyword()
  def add_aliases_v1(:host, aliases) do
    aliases
    |> append("deps.get", "nerves.bootstrap")
    |> append("deps.get", "nerves.deps.get")
    |> prepend("deps.precompile", "nerves.bootstrap")
    |> replace_at_end("deps.update", &NervesBootstrap.Aliases.deps_update/1)
  end

  def add_aliases_v1(_target, aliases) do
    aliases
    |> append("deps.get", "nerves.bootstrap")
    |> append("deps.get", "nerves.deps.get")
    |> prepend("deps.precompile", "nerves.bootstrap")
    |> replace_at_end("deps.update", &NervesBootstrap.Aliases.deps_update/1)
    |> prepend("deps.loadpaths", "nerves.loadpaths")
    |> prepend("deps.loadpaths", "nerves.bootstrap")
    |> prepend("deps.compile", "nerves.loadpaths")
    |> prepend("deps.compile", "nerves.bootstrap")
    |> replace_at_end("run", &NervesBootstrap.Aliases.run/1)
  end

  @spec run([String.t()]) :: :ok
  def run(args) do
    target = Mix.target()

    if target == :host do
      Mix.Tasks.Run.run(args)
    else
      Mix.shell().error("""
      You are trying to run code compiled for the '#{target}' target
      on your host. Please unset MIX_TARGET to run in host mode.
      """)
    end
  end

  # v1 only
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

  defp replace_at_end(aliases, a, fun) do
    # This maintains v1 semantics for replace()
    key = String.to_atom(a)
    Keyword.update(aliases, key, [fun], &(drop(drop(&1, a), fun) ++ [fun]))
  end

  defp replace(aliases, a, fun) do
    key = String.to_atom(a)
    Keyword.update(aliases, key, [fun], &do_replace(&1, a, fun))
  end

  defp do_replace(values, from, to), do: Enum.map(values, &maybe_replace(&1, from, to))
  defp maybe_replace(value, from, to) when value == from, do: to
  defp maybe_replace(value, _from, _to), do: value

  defp drop(aliases, a) do
    Enum.reject(aliases, &(&1 === a))
  end
end
