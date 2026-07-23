# SPDX-FileCopyrightText: 2026 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.NervesBootstrap.Init do
  # Nerves v2 initialization
  #
  # This mix task ensures that the nerves.init task is run first
  # so that it can configure the compilation environment for
  # building other packages. This is important since it affects
  # how NIFs and ports get compiled.
  @moduledoc false

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    # Check if Nerves has already been compiled and we can chain directly to it
    minimal_loadpaths()

    if not Code.ensure_loaded?(Nerves) do
      # Compile Nerves and its dependencies
      Mix.Tasks.Deps.Compile.run(["--include-children", "nerves"])

      # Make Nerves available in the load path
      minimal_loadpaths()
    end

    # Do not call Nerves Bootstrap code from other modules here. The modules
    # aren't available in Elixir 1.18 and earlier if `:nerves` doesn't pull
    # them in.

    # Chain to the Nerves tooling
    Mix.Task.run("nerves.init", [])
  end

  defp minimal_loadpaths() do
    # Load only what's available. Really, only "--no-deps-check" is needed, but
    # might as well skip other work.
    Mix.Tasks.Deps.Loadpaths.run([
      "--no-deps-check",
      "--no-elixir-version-check",
      "--no-archives-check",
      "--no-compile",
      "--no-listeners"
    ])
  end
end
