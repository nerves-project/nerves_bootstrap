defmodule Mix.Tasks.Local.Nerves do
  use Mix.Task

  @shortdoc "Checks for updates to nerves_bootstrap"

  @moduledoc """
  Check for updates to nerves_bootstrap

  Example:

      mix local.nerves

  This accepts the same command line options as `archive.install`.
  """
  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("archive.install", ["hex", "nerves_bootstrap", "~> 1.0"])
  end
end
