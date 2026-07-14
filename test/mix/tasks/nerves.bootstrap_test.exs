# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Nerves.BootstrapTest do
  use ExUnit.Case

  test "raises when :nerves is not a dependency" do
    NervesBootstrap.start(:normal, [])

    # Check that error alias is registered with the expected error message
    aliases = Mix.Project.config()[:aliases]
    [raise_fn | _] = Keyword.get(aliases, :"deps.loadpaths")

    assert_raise Mix.Error, ~r/:nerves is not a project dependency/, fn ->
      raise_fn.([])
    end
  end
end
