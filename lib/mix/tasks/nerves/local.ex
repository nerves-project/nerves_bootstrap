defmodule Mix.Tasks.Local.Nerves do
  use Mix.Task

  @shortdoc "Updates Nerves locally"

  @moduledoc """
  Updates Nerves locally.

      mix local.nerves

  Accepts the same command line options as `archive.install`.
  """
  def run(args) do
    Mix.Task.run "archive.install", ["hex", "nerves_bootstrap"]
  end
end
