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
defmodule Mix.Tasks.Nerves.NewTest do
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
        assert file =~ "{:nerves_system_rpi, \"~> 2.0\", runtime: false, targets: :rpi"
        assert file =~ "{:nerves_system_rpi0, \"~> 2.0\", runtime: false, targets: :rpi0"
        assert file =~ "{:nerves_system_rpi0_2, \"~> 2.0\", runtime: false, targets: :rpi0_2"
        assert file =~ "{:nerves_system_rpi2, \"~> 2.0\", runtime: false, targets: :rpi2"
        assert file =~ "{:nerves_system_rpi3, \"~> 2.0\", runtime: false, targets: :rpi3"
        assert file =~ "{:nerves_system_rpi4, \"~> 2.0\", runtime: false, targets: :rpi4"
        assert file =~ "{:nerves_system_rpi5, \"~> 2.0\", runtime: false, targets: :rpi5"
        assert file =~ "{:nerves_system_bbb, \"~> 2.19\", runtime: false, targets: :bbb"
        assert file =~ "{:nerves_system_x86_64, \"~> 1.24\", runtime: false, targets: :x86_64"

        assert file =~
                 "{:nerves_system_mangopi_mq_pro, \"~> 0.6\", runtime: false, targets: :mangopi_mq_pro"

        assert file =~
                 "{:nerves_system_qemu_aarch64, \"~> 0.1\", runtime: false, targets: :qemu_aarch64"
      end)
    end)
  end

  test "new prerelease project", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run(["--prerelease", @app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~s({:nerves, "~> 2.0.0-pre.3", runtime: false})
        assert file =~ ~s({:logger_backends, "~> 1.0"})
      end)
    end)
  end

  test "new project single target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 2.0\", runtime: false, targets: :rpi"
        refute file =~ "{:nerves_system_rpi0, \"~> 2.0\", runtime: false, targets: :rpi0"
      end)
    end)
  end

  test "new project multiple target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi", "--target", "rpi3"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 2.0\", runtime: false, targets: :rpi"
        assert file =~ "{:nerves_system_rpi3, \"~> 2.0\", runtime: false, targets: :rpi3"
        refute file =~ "{:nerves_system_rpi0, \"~> 2.0\", runtime: false, targets: :rpi0"
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
        refute file =~ "-mode embedded"
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

      assert_file("#{@app_name}/config/runtime.exs", fn file ->
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
        refute file =~ ~r"all_targets"
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

  describe "--igniter" do
    setup do
      test_pid = self()

      # Stand in for `mix igniter.new`. See NervesBootstrap.IgniterNew.run/1.
      Application.put_env(:nerves_bootstrap, :igniter_new_runner, fn [path | _] = argv ->
        send(test_pid, {:igniter_new, argv})
        File.mkdir_p!(Path.join(path, "config"))
        File.write!(Path.join(path, "config/target.exs"), "import Config\n")
        # igniter.new leaves the current directory in the new project
        File.cd!(path)
        :ok
      end)

      on_exit(fn -> Application.delete_env(:nerves_bootstrap, :igniter_new_runner) end)
    end

    test "delegates to igniter.new", context do
      in_tmp(context.test, fn ->
        cwd = File.cwd!()
        Mix.Tasks.Nerves.New.run([@app_name, "--igniter"])

        assert_received {:igniter_new,
                         [
                           @app_name,
                           "--install",
                           "nerves,nerves_ssh,mdns_lite,vintage_net,vintage_net_direct,vintage_net_ethernet,vintage_net_wifi,nerves_time,nerves_motd",
                           "--sup",
                           "--no-git",
                           "--yes"
                         ]}

        assert_received {:mix_shell, :info,
                         ["Your Nerves project was created successfully." <> _]}

        # None of the template was used
        refute_file("#{cwd}/#{@app_name}/mix.exs")
        assert File.cwd!() == cwd
      end)
    end

    test "passes options through", context do
      in_tmp(context.test, fn ->
        Mix.Tasks.Nerves.New.run([
          "some/#{@app_name}",
          "--igniter",
          "--app",
          "my_fw",
          "--module",
          "My.Fw",
          "--target",
          "rpi5",
          "--target",
          "rpi0",
          "--no-nerves-pack",
          "--install",
          "nerves_motd,nerves_time",
          "--install",
          "nerves@path:/src/nerves"
        ])

        assert_received {:igniter_new,
                         [
                           "some/my_device",
                           "--install",
                           "nerves@path:/src/nerves,nerves_motd,nerves_time",
                           "--module",
                           "My.Fw",
                           "--sup",
                           "--no-git",
                           "--with-args=--app my_fw",
                           "--yes",
                           "--target",
                           "rpi5",
                           "--target",
                           "rpi0"
                         ]}
      end)
    end

    test "prerelease selects the Nerves prerelease", context do
      in_tmp(context.test, fn ->
        Mix.Tasks.Nerves.New.run([@app_name, "--igniter", "--prerelease"])

        assert_received {:igniter_new, [@app_name, "--install", "nerves@2.0.0-pre." <> _ | _]}
      end)
    end

    test "validates names and targets before running igniter.new", context do
      in_tmp(context.test, fn ->
        assert_raise Mix.Error, ~r/Unknown target :not_a_target/, fn ->
          Mix.Tasks.Nerves.New.run([@app_name, "--igniter", "--target", "not_a_target"])
        end

        assert_raise Mix.Error, ~r/Application name must start with a letter/, fn ->
          Mix.Tasks.Nerves.New.run(["007", "--igniter"])
        end

        assert_raise Mix.Error, ~r/cannot be named 'nerves'/, fn ->
          Mix.Tasks.Nerves.New.run(["nerves", "--igniter"])
        end

        refute_received {:igniter_new, _}
      end)
    end

    test "rejects options that only the template supports", context do
      in_tmp(context.test, fn ->
        assert_raise Mix.Error, "--cookie is not supported together with --igniter", fn ->
          Mix.Tasks.Nerves.New.run([@app_name, "--igniter", "--cookie", "foo"])
        end

        assert_raise Mix.Error,
                     "--source-date-epoch is not supported together with --igniter",
                     fn ->
                       Mix.Tasks.Nerves.New.run([
                         @app_name,
                         "--igniter",
                         "--source-date-epoch",
                         "1234"
                       ])
                     end

        refute_received {:igniter_new, _}
      end)
    end

    test "explains how to install igniter_new when it is missing", context do
      Application.put_env(:nerves_bootstrap, :igniter_new_runner, fn _argv ->
        {:error, :not_installed}
      end)

      in_tmp(context.test, fn ->
        assert_raise Mix.Error, ~r/mix archive\.install hex igniter_new/, fn ->
          Mix.Tasks.Nerves.New.run([@app_name, "--igniter"])
        end

        refute File.exists?(@app_name)
      end)
    end

    test "fails when the installed Nerves had no installer", context do
      Application.put_env(:nerves_bootstrap, :igniter_new_runner, fn [path | _] ->
        File.mkdir_p!(path)
        :ok
      end)

      in_tmp(context.test, fn ->
        error =
          assert_raise Mix.Error, fn ->
            Mix.Tasks.Nerves.New.run([@app_name, "--igniter", "--app", "my_fw"])
          end

        assert error.message =~ "wasn't set up for Nerves"
        assert error.message =~ "--install nerves@github:nerves-project/nerves"

        assert error.message =~
                 ~s(mix igniter.new my_device --install nerves,nerves_ssh,mdns_lite,vintage_net,vintage_net_direct,vintage_net_ethernet,vintage_net_wifi,nerves_time,nerves_motd --sup --no-git "--with-args=--app my_fw" --yes)
      end)
    end
  end

  test "--install requires --igniter", context do
    in_tmp(context.test, fn ->
      assert_raise Mix.Error, "--install is only supported together with --igniter", fn ->
        Mix.Tasks.Nerves.New.run([@app_name, "--install", "nerves_motd"])
      end

      refute File.exists?(@app_name)
    end)
  end

  test "the template is used without --igniter", context do
    Application.put_env(:nerves_bootstrap, :igniter_new_runner, fn _argv ->
      flunk("igniter.new must not be run")
    end)

    on_exit(fn -> Application.delete_env(:nerves_bootstrap, :igniter_new_runner) end)

    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])
      assert_file("#{@app_name}/config/target.exs")
    end)
  end
end
