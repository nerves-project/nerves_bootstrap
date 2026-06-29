# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Nerves.BootstrapTest do
  use ExUnit.Case

  test "raises when :nerves is not a dependency" do
    assert_raise Mix.Error, fn -> Mix.Tasks.Nerves.Bootstrap.run([]) end
  end
end
