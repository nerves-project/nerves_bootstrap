defmodule Mix.Tasks.Nerves.Loadconfig do
  use Mix.Task

  def run(args) do
    System.get_env("MIX_TARGET")
    |> init()

    Mix.Task.run("loadconfig", args)
  end

  def init(nil), do: :noop
  def init("host"), do: :noop

  def init(target) do
    Mix.shell().info([
      :green,
      """
      Nerves environment
        MIX_TARGET:   #{target}
        MIX_ENV:      #{Mix.env()}
      """,
      :reset
    ])

    configure_project(Mix.ProjectStack.peek())
  end

  def configure_project(nil), do: :ok

  def configure_project(_) do
    %{name: name, config: config, file: file} = Mix.ProjectStack.pop()
    config = update_in(config, [:aliases], &Nerves.Bootstrap.add_aliases(&1))
    Mix.ProjectStack.push(name, config, file)
  end
end
