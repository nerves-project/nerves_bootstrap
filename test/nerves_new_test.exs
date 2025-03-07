# SPDX-FileCopyrightText: 2017 Justin Schneck
# SPDX-FileCopyrightText: 2018 Frank Hunleth
# SPDX-FileCopyrightText: 2019 Milton Mazzarri
# SPDX-FileCopyrightText: 2019 Todd Resudek
# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Jon Carstens
# SPDX-FileCopyrightText: 2022 Ryota Kinukawa
# SPDX-FileCopyrightText: 2023 Masatoshi Nishiguchi
#
# SPDX-License-Identifier: Apache-2.0
#
Code.require_file("mix_helper.exs", __DIR__)

defmodule Nerves.NewTest do
  use ExUnit.Case
  import MixHelper

  @app_name "my_device"

  setup do
    # The shell asks to install deps.
    # We will politely say not to.
    send(self(), {:mix_shell_input, :yes?, false})
    :ok
  end

  test "new project default targets", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 1.24\", runtime: false, targets: :rpi"
        assert file =~ "{:nerves_system_rpi0, \"~> 1.24\", runtime: false, targets: :rpi0"
        assert file =~ "{:nerves_system_rpi2, \"~> 1.24\", runtime: false, targets: :rpi2"
        assert file =~ "{:nerves_system_rpi3, \"~> 1.24\", runtime: false, targets: :rpi3"
        assert file =~ "{:nerves_system_rpi3a, \"~> 1.24\", runtime: false, targets: :rpi3a"
        assert file =~ "{:nerves_system_rpi4, \"~> 1.24\", runtime: false, targets: :rpi4"
        assert file =~ "{:nerves_system_rpi5, \"~> 0.2\", runtime: false, targets: :rpi5"
        assert file =~ "{:nerves_system_bbb, \"~> 2.19\", runtime: false, targets: :bbb"

        assert file =~
                 "{:nerves_system_osd32mp1, \"~> 0.15\", runtime: false, targets: :osd32mp1"

        assert file =~ "{:nerves_system_x86_64, \"~> 1.24\", runtime: false, targets: :x86_64"
        assert file =~ "{:nerves_system_grisp2, \"~> 0.8\", runtime: false, targets: :grisp2"

        assert file =~
                 "{:nerves_system_mangopi_mq_pro, \"~> 0.6\", runtime: false, targets: :mangopi_mq_pro"
      end)
    end)
  end

  test "new project single target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 1.24\", runtime: false, targets: :rpi"
        refute file =~ "{:nerves_system_rpi0, \"~> 1.24\", runtime: false, targets: :rpi0"
      end)
    end)
  end

  test "new project multiple target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi", "--target", "rpi3"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 1.24\", runtime: false, targets: :rpi"
        assert file =~ "{:nerves_system_rpi3, \"~> 1.24\", runtime: false, targets: :rpi3"
        refute file =~ "{:nerves_system_rpi0, \"~> 1.24\", runtime: false, targets: :rpi0"
      end)
    end)
  end

  test "new project cookie set", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--cookie", "foo"])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~s{cookie: "foo"}
      end)
    end)
  end

  test "new project provides a default cookie", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "cookie: \"\#{@app}_cookie\""
      end)
    end)
  end

  test "new project enables heart", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/rel/vm.args.eex", fn file ->
        assert file =~ "-heart -env HEART_BEAT_TIMEOUT"
      end)
    end)
  end

  test "new project enables embedded mode", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/rel/vm.args.eex", fn file ->
        assert file =~ "-mode embedded"
      end)
    end)
  end

  test "new project has correct shell settings", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      expected =
        if Version.match?(System.version(), ">= 1.15.0") do
          function =
            if Version.match?(System.version(), ">= 1.17.0"), do: "start_cli", else: "start_iex"

          ~r/-user elixir\n-run elixir #{function}/
        else
          ~r/-user Elixir.IEx.CLI/
        end

      assert_file("#{@app_name}/rel/vm.args.eex", fn file ->
        assert file =~ expected
      end)
    end)
  end

  test "new project adds runtime_tools", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/extra_applications:.*runtime_tools/
      end)
    end)
  end

  test "new project includes ring_logger", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/:ring_logger/
      end)

      assert_file("#{@app_name}/config/target.exs", fn file ->
        assert file =~ ~r/RingLogger/
      end)
    end)
  end

  test "new project includes toolshed", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/:toolshed/
      end)
    end)
  end

  test "new project does not set build_embedded", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        refute file =~ ~r/build_embedded:/
      end)
    end)
  end

  test "new project with nerves_pack", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--nerves-pack"])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/:nerves_pack/
      end)

      assert_file("#{@app_name}/config/target.exs", fn file ->
        assert file =~ ~r"nerves_ssh"
        assert file =~ ~r"vintage_net"
        assert file =~ ~r"mdns_lite"
      end)
    end)
  end

  test "new project with implicit nerves_pack", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/:nerves_pack/
      end)

      assert_file("#{@app_name}/config/target.exs", fn file ->
        assert file =~ ~r"nerves_ssh"
        assert file =~ ~r"vintage_net"
        assert file =~ ~r"mdns_lite"
      end)
    end)
  end

  test "new project without nerves pack", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--no-nerves-pack"])

      assert_file("#{@app_name}/mix.exs", fn file ->
        refute file =~ ~r"nerves_pack"
      end)

      assert_file("#{@app_name}/config/config.exs", fn file ->
        refute file =~ ~r"nerves_pack"
        refute file =~ ~r"nerves_ssh"
      end)
    end)
  end

  test "new projects cannot use reserved names", context do
    in_tmp(context.test, fn ->
      assert_raise(Mix.Error, "New projects cannot be named 'nerves'", fn ->
        Mix.Tasks.Nerves.New.run(["nerves"])
      end)
    end)
  end

  test "new project sets source_date_epoch time", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--source-date-epoch", "1234"])

      assert_file("#{@app_name}/config/config.exs", fn file ->
        assert file =~ ~r/source_date_epoch: "1234"/
      end)
    end)
  end

  test "new project generates source_date_epoch time", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/config/config.exs", fn file ->
        assert file =~ ~r/source_date_epoch: /
      end)
    end)
  end

  test "new project generates sample erlinit config", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/config/target.exs", fn file ->
        assert file =~ ~r"erlinit"
      end)
    end)
  end
end
