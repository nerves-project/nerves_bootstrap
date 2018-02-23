defmodule Nerves.Bootstrap do
  use Application

  @version Mix.Project.config()[:version]

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  def start(_type, _args) do
    Nerves.Bootstrap.Aliases.init()
    {:ok, self()}
  end

  @doc """
  Returns the version of nerves_bootstrap
  """
  def version, do: @version

  @doc """
  Add the required Nerves bootstrap aliases to the existing ones
  """
  defdelegate add_aliases(aliases), to: Nerves.Bootstrap.Aliases

  @doc """
  Check the nerves_bootstrap updates from hex
  """
  def check_for_update() do
    try do
      Hex.start()
      {:ok, {200, resp, _}} = Hex.API.Package.get("hexpm", "nerves_bootstrap")

      current_version =
        Nerves.Bootstrap.version()
        |> Version.parse!()

      release_versions =
        resp
        |> Map.get("releases")
        |> Enum.map(&Map.get(&1, "version"))
        |> Enum.map(&Version.parse!/1)

      case check_for_update(release_versions, current_version) do
        nil ->
          :noop

        latest_version ->
          render_update_message(current_version, latest_version)
      end
    rescue
      _e -> :noop
    end
  end

  def check_for_update(releases, current_version) do
    releases
    |> filter_pre_release(current_version)
    |> Enum.filter(&(Version.compare(&1, current_version) == :gt))
    |> Enum.sort(&(Version.compare(&1, &2) == :gt))
    |> List.first()
  end

  def render_update_message(current_version, %{pre: pre} = latest_version) do
    message =
      "A new version of Nerves bootstrap is available(#{current_version} < #{latest_version}), " <>
        if pre == [] do
          """
          You can update by running
            
            mix local.nerves
          """
        else
          """
          You can update by running
            
            mix archive.install hex nerves_bootstrap #{latest_version}
          """
        end

    Mix.shell().info([
      IO.ANSI.yellow(),
      message,
      IO.ANSI.reset()
    ])
  end

  defp filter_pre_release(releases, %{pre: []}) do
    releases
    |> Enum.filter(&(Map.get(&1, :pre) == []))
  end

  defp filter_pre_release(releases, %{major: major, minor: minor, patch: patch}) do
    releases
    |> Enum.filter(fn
      %{pre: []} ->
        true

      %{major: ^major, minor: ^minor, patch: ^patch} ->
        true

      _ ->
        false
    end)
  end
end
