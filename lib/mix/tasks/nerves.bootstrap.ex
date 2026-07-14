# SPDX-FileCopyrightText: 2022 Jon Carstens
# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Nerves.Bootstrap do
  # Bootstrap Nerves tooling into the current Mix tooling
  #
  # The purpose of this task is to ensure the Nerves integration is compiled
  # first and available to be injected into the Mix tooling since NervesBootstrap
  # is available as an archive. (i.e. this is like having `:nerves` as a
  # dependency of this archive even though archives do not allow traditional
  # dependencies)
  #
  # It is not intended to be run manually

  @moduledoc false
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    if Mix.target() != :host and not Code.ensure_loaded?(Nerves.Env) do
      # The tooling mix tasks are maintained in :nerves so we need to
      # ensure it is compiled here first so the tasks are available.
      # If the target is host, then this will be handled by the regular
      # compilation process
      _ = Mix.Tasks.Deps.Loadpaths.run(["--no-compile"])
      Mix.Tasks.Deps.Compile.run(["nerves", "--include-children"])
    end

    # Do not call Nerves Bootstrap code from other modules here. The modules
    # aren't available in Elixir 1.18 and earlier if `:nerves` doesn't pull
    # them in.
  end
end
