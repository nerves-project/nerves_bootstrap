defmodule Nerves.Bootstrap do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, _args) do
    Nerves.Bootstrap.Aliases.init()
    {:ok, self()}
  end

  @doc """
  Returns the version of nerves_bootstrap
  """
  @spec version() :: String.t()
  def version(), do: unquote(Mix.Project.config()[:version])

  @doc """
  Read the Nerves dependency version of the bootstrapped project
  """
  @spec nerves_version() :: String.t() | nil
  def nerves_version() do
    if path = Mix.Project.deps_paths()[:nerves] do
      Mix.Project.in_project(:nerves, path, fn _ -> Mix.Project.config()[:version] end)
    end
  catch
    _, _ -> nil
  end

  @doc """
  Add the required Nerves bootstrap aliases to the existing ones
  """
  defdelegate add_aliases(aliases), to: Nerves.Bootstrap.Aliases

  @doc """
  Check the nerves_bootstrap updates from hex
  """
  @spec check_for_update() :: :ok
  def check_for_update() do
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
        :ok

      latest_version ->
        render_update_message(current_version, latest_version)
    end
  rescue
    _e -> :ok
  end

  @spec check_for_update([Version.t()], Version.t()) :: Version.t() | nil
  def check_for_update(releases, current_version) do
    releases
    |> Enum.filter(&(Version.compare(&1, current_version) == :gt))
    |> Enum.filter(pre_release_filter(current_version))
    |> Enum.sort(&(Version.compare(&1, &2) == :gt))
    |> List.first()
  end

  @spec render_update_message(Version.t(), Version.t()) :: :ok
  def render_update_message(current_version, latest_version) do
    upgrade =
      if latest_version.pre == [] do
        "mix local.nerves"
      else
        "mix archive.install hex nerves_bootstrap #{latest_version}"
      end

    Mix.shell().info([
      :yellow,
      """
      A new version of Nerves bootstrap is available (#{current_version} < #{latest_version}).

      You can update by running

        #{upgrade}
      """,
      :reset
    ])
  end

  # Return a function that filters releases based on whether the current version is a pre-release
  defp pre_release_filter(%{pre: []}) do
    &(Map.get(&1, :pre) == [])
  end

  defp pre_release_filter(%{major: major, minor: minor, patch: patch}) do
    fn
      %{pre: []} ->
        true

      %{major: ^major, minor: ^minor, patch: ^patch} ->
        true

      _ ->
        false
    end
  end
end
