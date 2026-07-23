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
end
