defmodule Mix.Tasks.Nerves.Deps.Get do
  use Mix.Task

  import Mix.Nerves.IO

  def run(args) do
    debug_info("Nerves.Deps.Get Start")

    unless "--skip-deps-get" in args do
      Mix.Task.run("deps.get", args)
    end

    # We want to start Nerves.Env so it compiles `nerves`
    # but pass --disable to prevent it from compiling
    # the system and toolchain during this time.
    Mix.Tasks.Nerves.Env.run(["--disable"])
    Mix.Task.run("nerves.artifact.get", [])
    Nerves.Bootstrap.check_for_update()

    debug_info("Nerves.Deps.Get End")
  end
end
