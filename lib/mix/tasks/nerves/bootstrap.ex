defmodule Mix.Tasks.Nerves.Bootstrap do
  @moduledoc """
  Bootstrap Nerves tooling into the current Mix tooling

  The Nerves lib contains all the tasks and tooling for setting up the
  environment needed to use the Nerves project. However, some of that
  tooling needs to be injected early in the build process before everything
  is compiled.

  The purpose of this task is to ensure the Nerves integration is compiled
  first and available to be injected into the Mix tooling since Nerves.Bootstrap
  is available as an archive. (i.e. this is like having `:nerves` as a
  dependency of this archive even though archives do not allow traditional
  dependencies)

  It is not intended to be run manually
  """
  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    debug("load nerves START")

    nerves_ver = Nerves.Bootstrap.nerves_version()

    if is_nil(nerves_ver) do
      Mix.raise(":nerves is required as a dependency of this project")
    end

    if Version.match?(nerves_ver, "< 1.8.0") do
      Mix.raise("""
      You are using :nerves #{nerves_ver} which is incompatible with this version
      of nerves_bootstrap and will result in compilation failures.

      Please update to :nerves >= 1.8.0 or downgrade your nerves_bootstrap <= 1.11.5
      """)
    end

    if Mix.target() != :host and not Code.ensure_loaded?(Nerves.Env) do
      # The tooling mix tasks are maintained in :nerves so we need to
      # ensure it is compiled here first so the tasks are available.
      # If the target is host, then this will be handled by the regular
      # compilation process
      _ = Mix.Tasks.Deps.Loadpaths.run(["--no-compile"])
      Mix.Tasks.Deps.Compile.run(["nerves", "--include-children"])
    end

    Nerves.Bootstrap.check_for_update()

    debug("load nerves END")
  end

  defp debug(msg) do
    if System.get_env("NERVES_DEBUG") == "1" do
      Mix.shell().info([:inverse, "|nerves_boostrap| #{msg}", :reset])
    end
  end
end
