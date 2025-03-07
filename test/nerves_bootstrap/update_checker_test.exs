# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule UpdateChecker.UpdateCheckerTest do
  use ExUnit.Case

  alias Nerves.Bootstrap.UpdateChecker

  test "excludes pre-release updates normally" do
    current_version = Version.parse!("0.8.0")

    releases = [
      "0.8.2",
      "1.0.0-rc.0",
      "0.8.1"
    ]

    releases = Enum.map(releases, &Version.parse!/1)
    assert Version.parse!("0.8.2") == UpdateChecker.select_update(releases, current_version)
  end

  test "selects pre-release update if on pre" do
    current_version = Version.parse!("1.0.0-rc.0")

    releases = [
      "0.8.2",
      "1.0.0-rc.0",
      "0.8.1",
      "1.0.0-rc.1"
    ]

    releases = Enum.map(releases, &Version.parse!/1)

    assert Version.parse!("1.0.0-rc.1") ==
             UpdateChecker.select_update(releases, current_version)
  end

  test "selects update when moving from pre to stable" do
    current_version = Version.parse!("1.0.0-rc.0")

    releases = [
      "1.0.0",
      "1.0.0-rc.1",
      "0.8.2",
      "1.0.0-rc.0",
      "0.8.1"
    ]

    releases = Enum.map(releases, &Version.parse!/1)

    assert Version.parse!("1.0.0") ==
             UpdateChecker.select_update(releases, current_version)
  end

  test "check for update excluding pre release message" do
    current_version = Version.parse!("0.8.0")
    latest_version = Version.parse!("0.8.1")
    UpdateChecker.render_update_message(current_version, latest_version)
    assert_receive {:mix_shell, :info, [message]}
    assert message =~ "mix local.nerves"
  end

  test "check for update including pre release message" do
    current_version = Version.parse!("1.0.0-rc.0")
    latest_version = Version.parse!("1.0.0-rc.1")
    UpdateChecker.render_update_message(current_version, latest_version)
    assert_receive {:mix_shell, :info, [message]}
    assert message =~ "mix archive.install hex nerves_bootstrap 1.0.0-rc.1"
  end

  test "check for update moving from pre to stable message" do
    current_version = Version.parse!("1.0.0-rc.0")
    latest_version = Version.parse!("1.0.0")
    UpdateChecker.render_update_message(current_version, latest_version)
    assert_receive {:mix_shell, :info, [message]}
    assert message =~ "mix local.nerves"
  end
end
