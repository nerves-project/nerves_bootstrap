# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Integration.CompilationTest do
  use ExUnit.Case
  import MixHelper

  # Allow a minute in case downloads are slow
  @test_timeout 60_000

  setup_all do
    # Build and install the current bootstrap archive
    {_, 0} =
      System.cmd("mix", ["do", "archive.build", "+", "archive.install", "--force"],
        cd: File.cwd!(),
        into: IO.stream()
      )

    :ok
  end

  setup do
    # The shell asks to install deps.
    # We will politely say not to.
    send(self(), {:mix_shell_input, :yes?, false})
    :ok
  end

  @tag integration: :host
  @tag timeout: @test_timeout
  test "building host", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run(["my_test_project"])

      project_dir = Path.join(File.cwd!(), "my_test_project")

      {_, 0} =
        System.cmd("mix", ["deps.get"],
          cd: project_dir,
          env: [{"MIX_ENV", "dev"}, {"MIX_TARGET", "host"}],
          into: IO.stream()
        )

      {_, 0} =
        System.cmd("mix", ["compile", "--warnings-as-errors"],
          cd: project_dir,
          env: [{"MIX_ENV", "dev"}, {"MIX_TARGET", "host"}],
          into: IO.stream()
        )
    end)
  end

  @tag integration: :target
  @tag timeout: @test_timeout
  test "building for rpi0", context do
    in_tmp(context.test, fn ->
      Mix.Tasks.Nerves.New.run(["my_test_project"])

      project_dir = Path.join(File.cwd!(), "my_test_project")

      {_, 0} =
        System.cmd("mix", ["deps.get"],
          cd: project_dir,
          env: [{"MIX_ENV", "dev"}, {"MIX_TARGET", "rpi0"}],
          into: IO.stream()
        )

      {_, 0} =
        System.cmd("mix", ["compile", "--warnings-as-errors"],
          cd: project_dir,
          env: [{"MIX_ENV", "dev"}, {"MIX_TARGET", "rpi0"}],
          into: IO.stream()
        )
    end)
  end
end
