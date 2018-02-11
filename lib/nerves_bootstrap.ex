defmodule Nerves.Bootstrap do
  @version Mix.Project.config()[:version]

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
end
