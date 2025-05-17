# SPDX-FileCopyrightText: 2025 Frank Hunleth
# SPDX-FileCopyrightText: 2025 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Nerves.New do
  use Mix.Task

  @reserved_names ~w[nerves]

  @switches [
    app: :string,
    module: :string,
    target: :keep
  ]

  @impl Mix.Task
  def run(argv) do
    {opts, argv} =
      case OptionParser.parse(argv, strict: @switches) do
        {opts, argv, []} ->
          {opts, argv}

        {_opts, _argv, [switch | _]} ->
          Mix.raise("Invalid option: " <> switch_to_string(switch))
      end

    case argv do
      [] ->
        Mix.Task.run("help", ["nerves.new"])

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))

        run_new(app, opts)
    end
  end

  defp run_new(app, _opts) when app in @reserved_names,
    do: Mix.raise("New projects cannot be named '#{app}'")

  defp run_new(app, opts) do
    System.cmd("mix", ["new", app] ++ OptionParser.to_argv(opts), into: IO.stream(:stdio, :line))
    File.cd!(app)
    Mix.Task.run("igniter.install", ["nerves"])
    print_mix_info(app)
  end

  defp print_mix_info(path) do
    command = ["$ cd #{path}"]

    Mix.shell().info("""
    TODO: Update to be correct to new ways...

    Your Nerves project was created successfully.

    You should now pick a target. See https://hexdocs.pm/nerves/supported-targets.html
    for supported targets. If your target is on the list, set `MIX_TARGET`
    to its tag name:

    For example, for the Raspberry Pi 3 you can either
      $ export MIX_TARGET=rpi3
    Or prefix `mix` commands like the following:
      $ MIX_TARGET=rpi3 mix firmware

    If you will be using a custom system, update the `mix.exs`
    dependencies to point to desired system's package.

    Now download the dependencies and build a firmware archive:
      #{Enum.join(command, "\n")}
      $ mix deps.get
      $ mix firmware

    If your target boots up using an SDCard (like the Raspberry Pi 3),
    then insert an SDCard into a reader on your computer and run:
      $ mix burn

    Plug the SDCard into the target and power it up. See target documentation
    above for more information and other targets.
    """)
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val
end
