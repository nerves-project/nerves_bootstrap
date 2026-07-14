# SPDX-FileCopyrightText: 2017 Justin Schneck
# SPDX-FileCopyrightText: 2022 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap do
  @moduledoc false
  use Application

  alias NervesBootstrap.Aliases

  @impl Application
  def start(_type, _args) do
    NervesBootstrap.UpdateChecker.check()

    nerves_version = nerves_version()

    # Check that the Nerves version is new enough to support this
    # version of Nerves Bootstrap.
    #
    # This version of Nerves Bootstrap fails to install when the
    # Elixir version is less than 1.15, so we're guaranteed that
    # version. That forces a constraint on what Nerves versions
    # can be used. Here's a truncated list for convenience.
    #
    # | Nerves version | Min Elixir version          | Max Elixir |
    # |----------------|-----------------------------|------------|
    # | 1.11.3         | 1.13                        | 1.18       |
    # | 1.12.0         | 1.15.1                      | 1.19       |
    # | 1.14.3         | 1.15.1 (inherited)          | 1.20       |

    cond do
      nerves_version == :no_dependency ->
        report_error("""
        The Nerves tooling is required, but :nerves is not a project dependency.

        Check your mix.exs or add the following to your dependencies:

            {:nerves, "~> 1.15", runtime: false}
        """)

      nerves_version == :need_deps_get ->
        handle_undownloaded_nerves_package()

      Version.match?(nerves_version, "< 1.11.3") ->
        report_error("""
        You are using :nerves #{nerves_version} which is incompatible with this version
        of nerves_bootstrap and will result in compilation failures.

        Please update to :nerves >= 1.11.3
        """)

      Version.match?(nerves_version, "< 2.0.0-dev") ->
        start_nerves_v1(nerves_version)

      true ->
        report_error("""
        You are using :nerves #{nerves_version} which is not supported by this version
        of nerves_bootstrap.

        Please update your version of nerves_bootstrap.
        """)
    end

    {:ok, self()}
  end

  defp start_nerves_v1(nerves_version) do
    workaround_v1_compile_partition_issue(nerves_version)
    Aliases.inject_aliases_if_top(&Aliases.add_aliases_v1(Mix.target(), &1))
  end

  defp handle_undownloaded_nerves_package() do
    req = nerves_mix_requirement_string()

    if definitely_nerves_1_x?(req) do
      # This is a workaround to not break the Nerves 1.x feature that
      # mix deps.get can both get the Nerves tooling for the first time AND
      # use it to download artifacts.
      start_nerves_v1("<unknown>")
    else
      disallow_compilation("""
      The :nerves package wasn't available at the beginning of compilation.

      Please run `mix deps.get` to get the :nerves package. If you got this
      error when running a list of mix tasks that included `deps.get`, run
      `mix deps.get` by itself and then follow it with the rest of the tasks.
      """)
    end
  end

  defp report_error(msg) do
    # Mix.raise only works from Mix tasks, so defer error to when a task is run
    Aliases.inject_aliases_if_top(&Aliases.add_error_report_aliases(msg, &1))
  end

  defp disallow_compilation(msg) do
    Aliases.inject_aliases_if_top(&Aliases.add_no_compilation_aliases(msg, &1))
  end

  defp nerves_version() do
    path = Mix.Project.deps_paths()[:nerves]

    cond do
      path == nil ->
        :no_dependency

      File.dir?(path) ->
        Mix.Project.in_project(:nerves, path, fn _ -> Mix.Project.config()[:version] end)

      true ->
        :need_deps_get
    end
  end

  @doc false
  @spec definitely_nerves_1_x?(String.t() | nil) :: boolean
  def definitely_nerves_1_x?(req) when is_binary(req) do
    # See the calling context. This isn't meant to be perfect.
    case Version.parse_requirement(req) do
      {:ok, r} -> Version.match?("1.999.999", r) and not Version.match?("2.999.999", r)
      _ -> false
    end
  end

  def definitely_nerves_1_x?(_req), do: false

  defp nerves_mix_requirement_string() do
    case Enum.find(Mix.Project.config()[:deps], &(elem(&1, 0) == :nerves)) do
      {:nerves, req} -> req
      {:nerves, req, _opts} -> req
      _ -> nil
    end
  end

  defp workaround_v1_compile_partition_issue(nerves_version) do
    if Version.match?(System.version(), ">= 1.19.0") and has_compile_partition_count?() do
      Mix.shell().error("""
      Nerves #{nerves_version} does not support MIX_OS_DEPS_COMPILE_PARTITION_COUNT.

      Disabling it for this build. To silence this warning, either unset
      MIX_OS_DEPS_COMPILE_PARTITION_COUNT or set it to 1 before you build.

      Follow https://github.com/nerves-project/nerves/issues/1093 to track
      progress.
      """)

      System.delete_env("MIX_OS_DEPS_COMPILE_PARTITION_COUNT")
    end
  end

  defp has_compile_partition_count?() do
    case System.fetch_env("MIX_OS_DEPS_COMPILE_PARTITION_COUNT") do
      :error -> false
      {:ok, "1"} -> false
      _ -> true
    end
  end
end
