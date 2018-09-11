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
        assert file =~ "app: :#{@app_name}"
        assert file =~ "defp system(\"rpi\"), do: [{:nerves_system_rpi, \"~> 1.0\""
        assert file =~ "defp system(\"rpi0\"), do: [{:nerves_system_rpi0, \"~> 1.0\""
        assert file =~ "defp system(\"rpi2\"), do: [{:nerves_system_rpi2, \"~> 1.0\""
        assert file =~ "defp system(\"rpi3\"), do: [{:nerves_system_rpi3, \"~> 1.0\""
        assert file =~ "defp system(\"bbb\"), do: [{:nerves_system_bbb, \"~> 1.0\""
        assert file =~ "defp system(\"ev3\"), do: [{:nerves_system_ev3, \"~> 1.0\""
        assert file =~ "defp system(\"x86_64\"), do: [{:nerves_system_x86_64, \"~> 1.0\""
      end)
    end)
  end

  test "new project single target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "app: :#{@app_name}"
        assert file =~ "defp system(\"rpi\"), do: [{:nerves_system_rpi, \"~> 1.0\""
        refute file =~ "defp system(\"rpi0\"), do: [{:nerves_system_rpi0, \"~> 1.0\""
      end)
    end)
  end

  test "new project multiple target", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--target", "rpi", "--target", "rpi3"])

      assert_file("#{@app_name}/README.md")

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ "app: :#{@app_name}"
        assert file =~ "defp system(\"rpi\"), do: [{:nerves_system_rpi, \"~> 1.0\""
        assert file =~ "defp system(\"rpi3\"), do: [{:nerves_system_rpi3, \"~> 1.0\""
        refute file =~ "defp system(\"rpi0\"), do: [{:nerves_system_rpi0, \"~> 1.0\""
      end)
    end)
  end

  test "new project defined cookie set", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--cookie", "12345"])

      assert_file("#{@app_name}/rel/vm.args", fn file ->
        assert file =~ "-setcookie 12345"
      end)
    end)
  end

  test "new project default cookie set", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/rel/vm.args", fn file ->
        assert file =~ ~r/.*-setcookie [a-zA-Z0-9]{64}\n|\r|\n\r/s
      end)
    end)
  end

  test "new project adds comment about enabling heart", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/rel/vm.args", fn file ->
        assert file =~ "#-heart -env HEART_BEAT_TIMEOUT"
      end)
    end)
  end

  test "new project adds runtime_tools", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r"extra_applications:.*runtime_tools"
      end)
    end)
  end

  test "new project includes ring_logger", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r":ring_logger"
      end)

      assert_file("#{@app_name}/config/config.exs", fn file ->
        assert file =~ ~r"RingLogger"
      end)
    end)
  end

  test "new project init gadget", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run([@app_name, "--init-gadget"])

      assert_file("#{@app_name}/mix.exs", fn file ->
        assert file =~ ~r"nerves_init_gadget"
      end)

      assert_file("#{@app_name}/config/config.exs", fn file ->
        assert file =~ ~r"nerves_init_gadget"
        assert file =~ ~r"nerves_firmware_ssh"
      end)
    end)
  end
end
