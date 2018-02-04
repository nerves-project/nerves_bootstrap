defmodule Mix.Tasks.Nerves.Deps.Update do
  use Mix.Task

  import Mix.Nerves.IO

  def run(args) do
    debug_info("Nerves.Deps.Update Start")

    Mix.Task.run("deps.update", args)
    Mix.Task.run("nerves.deps.get", ["--skip-deps-get" | args])

    debug_info("Nerves.Deps.Update End")
  end
end
