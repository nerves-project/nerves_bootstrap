# SPDX-FileCopyrightText: 2017 Justin Schneck
# SPDX-FileCopyrightText: 2022 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Nerves.Bootstrap do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, _args) do
    Nerves.Bootstrap.Aliases.init()
    {:ok, self()}
  end

  @doc """
  Returns the version of nerves_bootstrap
  """
  @spec version() :: String.t()
  def version(), do: unquote(Mix.Project.config()[:version])

  @doc """
  Read the Nerves dependency version of the bootstrapped project
  """
  @spec nerves_version() :: String.t() | nil
  def nerves_version() do
    if path = Mix.Project.deps_paths()[:nerves] do
      Mix.Project.in_project(:nerves, path, fn _ -> Mix.Project.config()[:version] end)
    end
  catch
    _, _ -> nil
  end

  @doc """
  Add the required Nerves bootstrap aliases to the existing ones
  """
  defdelegate add_aliases(aliases), to: Nerves.Bootstrap.Aliases
end
