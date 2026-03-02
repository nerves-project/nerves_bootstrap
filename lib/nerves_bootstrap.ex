# SPDX-FileCopyrightText: 2017 Justin Schneck
# SPDX-FileCopyrightText: 2022 Frank Hunleth
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap do
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

    NervesBootstrap.Aliases.init()
    {:ok, self()}
  end

  defp has_compile_partition_count?() do
    case System.fetch_env("MIX_OS_DEPS_COMPILE_PARTITION_COUNT") do
      :error -> false
      {:ok, "1"} -> false
      _ -> true
    end
  end
end
