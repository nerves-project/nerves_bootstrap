defmodule Nerves.Bootstrap.UpdateChecker do
  @moduledoc false

  @doc """
  Check for a nerves_bootstrap release
  """
  @spec check() :: :ok
  def check() do
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

    case select_update(release_versions, current_version) do
      nil ->
        :ok

      latest_version ->
        render_update_message(current_version, latest_version)
    end
  rescue
    _e -> :ok
  end

  @spec select_update([Version.t()], Version.t()) :: Version.t() | nil
  def select_update(releases, current_version) do
    req = Version.parse_requirement!("> #{current_version}")
    allow_pre = current_version.pre != []

    releases
    |> Enum.filter(&Version.match?(&1, req, allow_pre: allow_pre))
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
end
