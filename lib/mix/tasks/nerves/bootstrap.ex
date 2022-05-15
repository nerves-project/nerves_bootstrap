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

      # Nerves.Bootstrap used to manage all the Nerves mix tasks and continues
      # to define them for backwards compatibilty. But the mix tasks were moved
      # to Nerves in new versions to be maintained there. So if the newer Nerves
      # version is being used, then there will be lots of warnings about modules
      # from Nerves.Bootstrap being redefined in Nerves, so we opt to suppress
      # them only while we compile Nerves, and then set back to original option
      {ignore?, prev} = get_ignore_opts()
      Code.put_compiler_option(:ignore_module_conflict, ignore?)
      Mix.Tasks.Deps.Compile.run(["nerves", "--include-children"])
      Code.put_compiler_option(:ignore_module_conflict, prev)
    end

    Nerves.Bootstrap.check_for_update()

    debug("load nerves END")
  end

  defp get_ignore_opts() do
    version = Nerves.Bootstrap.nerves_version()
    prev = Code.get_compiler_option(:ignore_module_conflict) || false

    if version && Version.match?(version, "> 1.7.16") do
      debug("ignoring module conflict warnings with Nerves")
      {true, prev}
    else
      {false, false}
    end
  end

  defp debug(msg) do
    if System.get_env("NERVES_DEBUG") == "1" do
      Mix.shell().info([:inverse, "|nerves_boostrap| #{msg}", :reset])
    end
  end
end
