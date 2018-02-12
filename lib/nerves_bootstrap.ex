defmodule Nerves.Bootstrap do
  use Application

  alias Nerves.Bootstrap.Config

  @version Mix.Project.config()[:version]
  @on_load :install_check

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  def start(_type, _args) do
    Config.upgrade()
    Nerves.Bootstrap.Aliases.init()
    {:ok, self()}
  end

  @doc """
  Returns the version of nerves_bootstrap
  """
  def version, do: @version

  @doc """
  Check the nerves_bootstrap updates from hex
  """
  def check_for_update() do
    try do
      Hex.start()
      {:ok, {200, resp, _}} = Hex.API.Package.get("hexpm", "nerves_bootstrap")

      latest_rel =
        resp
        |> Map.get("releases")
        |> List.first()

      latest_vsn =
        Map.get(latest_rel, "version")
        |> Version.parse!()

      current_vsn =
        Nerves.Bootstrap.version()
        |> Version.parse!()

      if Version.compare(current_vsn, latest_vsn) == :lt do
        Mix.shell().info([
          IO.ANSI.yellow(),
          "A new version of Nerves bootstrap is available(#{current_vsn} < #{latest_vsn}), " <>
            "please update with `mix local.nerves`",
          IO.ANSI.reset()
        ])
      end
    rescue
      _e -> :noop
    end
  end

  @doc """
  Add the required Nerves bootstrap aliases to the existing ones
  """
  defdelegate add_aliases(aliases), to: Nerves.Bootstrap.Aliases

  def install_check do
    case Config.read() do
      {:ok, config} ->
        if Version.compare(config.version, version()) == :lt do
           display(update_text())
        end
      _ ->
        display(install_text() <> update_text())
    end
  end

  def install_text() do
    """

    Installing Nerves will create the directory ~/.nerves which is used
    for storing large downloads often in size > 100MBs.

    For more information visit
      
      https://hexdocs.pm/nerves/getting-started.html
    """
  end

  def update_text() do
    """

    Upgrading from < v0.8.0

    You will need to update your mix file

    First change your aliases to

      def project do
        [
          # ...
          aliases: ["loadconfig": [&bootstrap/1]]
        ]
      end

    Second add the bootstrap function

      def bootstrap(args) do
        Application.start(:nerves_bootstrap)
        Mix.Task.run("loadconfig", args)
      end
    """
  end

  def display(text) do
    Mix.shell().info([IO.ANSI.yellow(), text, IO.ANSI.reset()])
  end
end
