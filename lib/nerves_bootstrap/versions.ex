# SPDX-FileCopyrightText: 2026 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.Versions do
  # This module contains all of the version and dependency requirements in a central place
  @moduledoc false

  @bootstrap_vsn Mix.Project.config()[:version]

  @spec elixir_req() :: String.t()
  def elixir_req(), do: "~> 1.15"

  @spec bootstrap_vsn() :: String.t()
  def bootstrap_vsn(), do: @bootstrap_vsn

  @spec bootstrap_req() :: String.t()
  def bootstrap_req() do
    v = Version.parse!(bootstrap_vsn())
    "~> #{v.major}.#{v.minor}"
  end

  @spec supported_elixir?() :: boolean()
  def supported_elixir?(), do: Version.match?(System.version(), elixir_req())

  @spec package_reqs() :: %{atom() => String.t()}
  def package_reqs() do
    %{
      nerves: "~> 1.13",
      nerves_pack: "~> 0.7.1",
      nerves_runtime: "~> 0.13.12",
      nerves_system_bbb: "~> 2.19",
      nerves_system_grisp2: "~> 0.8",
      nerves_system_mangopi_mq_pro: "~> 0.6",
      nerves_system_npi_imx6ull: "~> 0.21",
      nerves_system_osd32mp1: "~> 0.15",
      nerves_system_qemu_aarch64: "~> 0.1",
      nerves_system_rpi: "~> 2.0",
      nerves_system_rpi0: "~> 2.0",
      nerves_system_rpi0_2: "~> 2.0",
      nerves_system_rpi2: "~> 2.0",
      nerves_system_rpi3: "~> 2.0",
      nerves_system_rpi3a: "~> 2.0",
      nerves_system_rpi4: "~> 2.0",
      nerves_system_rpi5: "~> 2.0",
      nerves_system_trellis: "~> 0.4",
      nerves_system_x86_64: "~> 1.24",
      ring_logger: "~> 0.11.0",
      shoehorn: "~> 0.9.1",
      toolshed: "~> 0.5.0"
    }
  end
end
