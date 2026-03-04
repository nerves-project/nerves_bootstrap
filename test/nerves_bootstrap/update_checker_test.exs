# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.UpdateCheckerTest do
  use ExUnit.Case

  alias NervesBootstrap.UpdateChecker

  @check_timestamp_file "nerves/nerves_bootstrap_update_check"

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

  describe "should_check?/0" do
    @tag :tmp_dir
    test "returns whether a recent check file exists", %{tmp_dir: tmp_dir} do
      set_data_dir(tmp_dir)

      assert UpdateChecker.should_check?()
      UpdateChecker.mark_checked()
      refute UpdateChecker.should_check?()
    end

    @tag :tmp_dir
    test "returns true when check file is older than interval", %{tmp_dir: tmp_dir} do
      set_data_dir(tmp_dir)

      # < 1 day
      manual_mark_checked(tmp_dir, -86000)
      refute UpdateChecker.should_check?()

      # > 1 day
      manual_mark_checked(tmp_dir, -86_401)
      assert UpdateChecker.should_check?()
    end

    @tag :tmp_dir
    test "returns true when check file is far in the future", %{tmp_dir: tmp_dir} do
      set_data_dir(tmp_dir)

      manual_mark_checked(tmp_dir, 86_500)
      assert UpdateChecker.should_check?()
    end
  end

  describe "check/0" do
    @tag :tmp_dir
    test "returns :ok immediately when recently checked", %{tmp_dir: tmp_dir} do
      set_data_dir(tmp_dir)
      UpdateChecker.mark_checked()

      assert :ok == UpdateChecker.check()
    end

    @tag :tmp_dir
    test "runs do_check and rescues when Hex is unavailable", %{tmp_dir: tmp_dir} do
      set_data_dir(tmp_dir)

      # No check file exists, so should_check?() returns true and do_check() runs.
      # Hex isn't started in test, so do_check() rescues and mark_checked() runs.
      assert :ok == UpdateChecker.check()

      # Verify mark_checked() was called by confirming a subsequent check is skipped
      refute UpdateChecker.should_check?()
    end
  end

  defp manual_mark_checked(tmp_dir, offset) do
    path = Path.join(tmp_dir, @check_timestamp_file)
    timestamp = System.os_time(:second) + offset
    File.touch!(path, timestamp)
  end

  defp set_data_dir(tmp_dir) do
    previous_value = System.get_env("XDG_DATA_HOME")
    System.put_env("XDG_DATA_HOME", tmp_dir)

    File.mkdir!(Path.join(tmp_dir, "nerves"))

    on_exit(fn ->
      File.rm_rf!(tmp_dir)

      if previous_value do
        System.put_env("XDG_DATA_HOME", previous_value)
      else
        System.delete_env("XDG_DATA_HOME")
      end
    end)
  end
end
