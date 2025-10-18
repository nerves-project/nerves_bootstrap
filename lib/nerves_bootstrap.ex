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
    if Version.match?(System.version(), ">= 1.19.0") and has_compile_partition_count?() do
      Mix.shell().error("""
      Nerves does not support MIX_OS_DEPS_COMPILE_PARTITION_COUNT yet.

      Disabling it for this build. To silence this warning, either unset
      MIX_OS_DEPS_COMPILE_PARTITION_COUNT or set it to 1 before you build.

      Follow https://github.com/nerves-project/nerves/issues/1093 to track
      progress.
      """)

      System.delete_env("MIX_OS_DEPS_COMPILE_PARTITION_COUNT")
    end

    Nerves.Bootstrap.Aliases.init()
    {:ok, self()}
  end

  defp has_compile_partition_count?() do
    case System.fetch_env("MIX_OS_DEPS_COMPILE_PARTITION_COUNT") do
      :error -> false
      {:ok, "1"} -> false
      _ -> true
    end
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
