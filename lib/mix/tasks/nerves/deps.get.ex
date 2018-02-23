defmodule Mix.Tasks.Nerves.Deps.Get do
  use Mix.Task

  import Mix.Nerves.IO

  @moduledoc false

  def run(_argv) do
    debug_info("Nerves.Deps.Get Start")

    # We want to start Nerves.Env so it compiles `nerves`
    # but pass --disable to prevent it from compiling
    # the system and toolchain during this time.
    Mix.Tasks.Nerves.Env.run(["--disable"])
    Mix.Task.run("nerves.artifact.get", [])
    Nerves.Bootstrap.check_for_update()

    debug_info("Nerves.Deps.Get End")
  end
end
