# SPDX-FileCopyrightText: 2026 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrapTest do
  use ExUnit.Case

  test "definitely_nerves_1_x?/1" do
    # Common cases in the wild
    assert NervesBootstrap.definitely_nerves_1_x?("~> 1.8")
    assert NervesBootstrap.definitely_nerves_1_x?("~> 1.11")
    assert NervesBootstrap.definitely_nerves_1_x?("~> 1.11.3 or ~> 1.12")

    # Not yet common in the wild
    refute NervesBootstrap.definitely_nerves_1_x?("~> 2.0.0-dev")
    refute NervesBootstrap.definitely_nerves_1_x?("~> 2.0")
    refute NervesBootstrap.definitely_nerves_1_x?("~> 1.11 or ~> 2.0")

    # Bad versions that return false to fail through to mix
    refute NervesBootstrap.definitely_nerves_1_x?(nil)
    refute NervesBootstrap.definitely_nerves_1_x?("oops")
  end

  test "uses a compatible Hex lock to disambiguate a mixed-major requirement" do
    req = "~> 1.11 or ~> 2.0 or ~> 2.0.0-dev"

    assert NervesBootstrap.definitely_nerves_1_x?(req, hex_lock("1.15.0"))
    refute NervesBootstrap.definitely_nerves_1_x?(req, hex_lock("2.0.0"))
    refute NervesBootstrap.definitely_nerves_1_x?(req, %{})
  end

  test "ignores stale, invalid, and non-Hex lock entries" do
    req = "~> 1.15 or ~> 2.0"

    refute NervesBootstrap.definitely_nerves_1_x?(req, hex_lock("1.14.0"))
    refute NervesBootstrap.definitely_nerves_1_x?(req, hex_lock("oops"))
    refute NervesBootstrap.definitely_nerves_1_x?("oops", hex_lock("1.15.0"))
    refute NervesBootstrap.definitely_nerves_1_x?(nil, hex_lock("1.15.0"))

    git_lock = %{nerves: {:git, "https://github.com/nerves-project/nerves.git", "abc", []}}
    refute NervesBootstrap.definitely_nerves_1_x?(req, git_lock)
    assert NervesBootstrap.definitely_nerves_1_x?("~> 1.11", git_lock)
  end

  defp hex_lock(version) do
    %{nerves: {:hex, :nerves, version, "checksum", [:mix], [], "hexpm", "outer_checksum"}}
  end
end
