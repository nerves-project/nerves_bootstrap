# SPDX-FileCopyrightText: 2017 Timmo Verlaan
# SPDX-FileCopyrightText: 2019 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Local.Nerves do
  @shortdoc "Updates the Nerves bootstrap archive locally"
  @moduledoc """
  Updates the Nerves bootstrap archive locally.

      $ mix local.nerves

  Accepts the same command line options as `archive.install hex nerves_bootstrap`.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("archive.install", ["hex", "nerves_bootstrap" | args])
  end
end
