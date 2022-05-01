defmodule Mix.Tasks.Local.Nerves do
  @shortdoc "Checks for updates to nerves_bootstrap"

  @moduledoc """
  Check for updates to nerves_bootstrap

  Example:

      mix local.nerves

  This accepts the same command line options as `archive.install`.
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("archive.install", ["hex", "nerves_bootstrap", "~> 1.0"])
  end
end
