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
        assert file =~ "{:nerves_system_rpi, \"~> 1.8\", runtime: false, targets: :rpi"
        assert file =~ "{:nerves_system_rpi0, \"~> 1.8\", runtime: false, targets: :rpi0"
        assert file =~ "{:nerves_system_rpi2, \"~> 1.8\", runtime: false, targets: :rpi2"
        assert file =~ "{:nerves_system_rpi3, \"~> 1.8\", runtime: false, targets: :rpi3"
        assert file =~ "{:nerves_system_rpi3a, \"~> 1.8\", runtime: false, targets: :rpi3a"
        assert file =~ "{:nerves_system_bbb, \"~> 2.3\", runtime: false, targets: :bbb"
        assert file =~ "{:nerves_system_x86_64, \"~> 1.8\", runtime: false, targets: :x86_64"
      end)
    end)
  end

  test "new project single target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 1.8\", runtime: false, targets: :rpi"
        refute file =~ "{:nerves_system_rpi0, \"~> 1.8\", runtime: false, targets: :rpi0"
      end)
    end)
  end

  test "new project multiple target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi", "--target", "rpi3"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "@app :#{@app_name}"
        assert file =~ "{:nerves_system_rpi, \"~> 1.8\", runtime: false, targets: :rpi"
        assert file =~ "{:nerves_system_rpi3, \"~> 1.8\", runtime: false, targets: :rpi3"
        refute file =~ "{:nerves_system_rpi0, \"~> 1.8\", runtime: false, targets: :rpi0"
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

      assert_file("#{@app_name}/config/config.exs", fn file ->
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

  test "new project sets build_embedded", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/build_embedded:/
      end)
    end)
  end

  test "new project sets includes nerves_init_gadget", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r/:nerves_init_gadget/
      end)

      assert_file("#{@app_name}/config/target.exs", fn file ->
        assert file =~ ~r"nerves_init_gadget"
        assert file =~ ~r"nerves_firmware_ssh"
      end)
    end)
  end

  test "new project without init gadget", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--no-init-gadget"])

      assert_file("#{@app_name}/mix.exs", fn file ->
        refute file =~ ~r"nerves_init_gadget"
      end)

      assert_file("#{@app_name}/config/config.exs", fn file ->
        refute file =~ ~r"nerves_init_gadget"
        refute file =~ ~r"nerves_firmware_ssh"
      end)
    end)
  end
end
