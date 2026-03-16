# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Nerves.BootstrapTest do
  use ExUnit.Case

  test "returns Nerves Bootstrap version" do
    vsn = Nerves.Bootstrap.version()
    expected = Application.spec(:nerves_bootstrap, :vsn) |> to_string()

    assert vsn == expected
  end
end
