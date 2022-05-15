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

    unless Code.ensure_loaded?(Nerves.Env) do
      _ = Mix.Tasks.Deps.Loadpaths.run(["--no-compile"])

      check_nerves_version!()
      Mix.Tasks.Deps.Compile.run(["nerves", "--include-children"])
    end

    Nerves.Bootstrap.check_for_update()

    debug("load nerves END")
  end

  defp check_nerves_version!() do
    version = Nerves.Bootstrap.nerves_version()

    if Version.match?(version, "< 1.8.0") do
      Mix.raise("""
      The Nerves mix integration requires `:nerves >= 1.8.0`. Got: #{version}

      You can fix this by updating to the latest version of `:nerves`:

        mix deps.update nerves

      Or by downgrading the Nerves mix intergation with:

        mix archive.install hex nerves_bootstrap 1.10.6
      """)
    end
  end

  defp debug(msg) do
    if System.get_env("NERVES_DEBUG") == "1" do
      Mix.shell().info([:inverse, "|nerves_boostrap| #{msg}", :reset])
    end
  end
end
