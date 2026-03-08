# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Integration.CompilationTest do
  use ExUnit.Case
  import MixHelper

  # Allow a minute in case downloads are slow
  @test_timeout 120_000

  setup_all do
    # Build and install the current bootstrap archive
    env = [{"MIX_ENV", "prod"}]
    run_cmd("mix", ["do", "archive.build", "+", "archive.install", "--force"], File.cwd!(), env)

    :ok
  end

  setup do
    # The shell asks to install deps.
    # We will politely say not to.
    send(self(), {:mix_shell_input, :yes?, false})
    :ok
  end

  # Tests for freshly generated projects
  @tag :integration
  @tag timeout: @test_timeout
  test "building host with a new project", context do
    if otp_release() == 28 do
      in_tmp(context.test, fn ->
        Mix.Tasks.Nerves.New.run(["my_test_project"])

        path = Path.join(File.cwd!(), "my_test_project")
        get_deps!(path, "host")
        build_firmware!(path, "host")
      end)
    end
  end

  @tag :integration
  @tag timeout: @test_timeout
  test "building for rpi0 with a new project", context do
    if otp_release() == 28 do
      in_tmp(context.test, fn ->
        Mix.Tasks.Nerves.New.run(["my_test_project"])

        path = Path.join(File.cwd!(), "my_test_project")
        get_deps!(path, "rpi0", &artifact_check/0)
        build_firmware!(path, "rpi0")
      end)
    end
  end

  # Tests for Nerves 1.x
  @tag :integration
  @tag timeout: @test_timeout
  test "nerves 1.x host", _context do
    path = fixture_for_nerves_version(1)
    clean_build!(path)
    get_deps!(path, "host")
    build_firmware!(path, "host")
  end

  @tag :integration
  @tag timeout: @test_timeout
  test "nerves 1.x rpi0", _context do
    path = fixture_for_nerves_version(1)
    clean_build!(path)
    get_deps!(path, "rpi0", &artifact_check/0)
    build_firmware!(path, "rpi0")
  end

  defp artifact_check() do
    artifacts_dir = Path.expand("~/.nerves/artifacts")

    with :ok <- check_artifact_exists(artifacts_dir, "nerves_system_rpi0-*") do
      check_artifact_exists(artifacts_dir, "nerves_toolchain_armv6_nerves_linux_gnueabihf-*")
    end
  end

  defp check_artifact_exists(artifacts_dir, pattern) do
    full_pattern = Path.join(artifacts_dir, pattern)

    if Path.wildcard(full_pattern) == [] do
      contents =
        case File.ls(artifacts_dir) do
          {:ok, files} -> Enum.join(files, "\n")
          {:error, reason} -> "Could not list directory: #{reason}"
        end

      {:error,
       """
       Expected artifact matching #{pattern} in #{artifacts_dir} after deps.get.

       Contents of #{artifacts_dir}:
       #{contents}
       """}
    else
      :ok
    end
  end

  defp clean_build!(path) do
    File.rm_rf!(Path.join(path, "_build"))
  end

  defp get_deps!(path, target, check \\ &no_check/0) do
    env = [{"MIX_ENV", "dev"}, {"MIX_TARGET", target}]
    run_cmd("mix", ["deps.get"], path, env, check)
  end

  defp build_firmware!(path, target) do
    env = [{"MIX_ENV", "dev"}, {"MIX_TARGET", target}]
    mix_task = if target == "host", do: "compile", else: "firmware"

    run_cmd("mix", [mix_task], path, env)
  end

  defp no_check(), do: :ok

  defp run_cmd(program, args, path, env, check_fn \\ &no_check/0) do
    {output, exit_code} = System.cmd(program, args, cd: path, env: env, stderr_to_stdout: true)

    if exit_code != 0 do
      flunk_cmd(program, args, path, env, output, "bad exit status of #{exit_code}")
    else
      case check_fn.() do
        :ok -> :ok
        {:error, reason} -> flunk_cmd(program, args, path, env, output, reason)
      end
    end
  end

  defp flunk_cmd(program, args, path, env, output, reason) do
    cmd = "#{program} #{Enum.join(args, " ")}"

    flunk("""
    `#{cmd}` failed: #{reason}.

    Path: #{path}
    Environment: #{inspect(env)}

    Log:
    #{output}
    """)
  end

  @spec fixture_for_nerves_version(integer()) :: String.t()
  defp fixture_for_nerves_version(nerves_major_version) do
    otp = otp_release()
    name = "nerves_#{nerves_major_version}x_otp#{otp}"

    # The test fixtures have to be kept on the root level since it wasn't
    # until Elixir 1.19 that there was a way to filter out Elixir files in
    # the fixture.
    path = Path.expand("../../test_fixtures/#{name}", __DIR__)

    if File.dir?(path) do
      path
    else
      flunk("No fixture for Nerves v#{nerves_major_version}.x on OTP #{otp}. Tried #{path}")
    end
  end

  defp otp_release() do
    :erlang.system_info(:otp_release) |> List.to_integer()
  end
end
