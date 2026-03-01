# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Nerves.Bootstrap.UpdateChecker do
  @moduledoc false

  @check_interval_seconds 86400

  @doc """
  Check for a nerves_bootstrap release
  """
  @spec check() :: :ok
  def check() do
    if should_check?() do
      do_check()
      mark_checked()
    else
      :ok
    end
  end

  defp do_check() do
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

  @doc false
  @spec should_check?() :: boolean()
  def should_check?() do
    case File.stat(check_file_path()) do
      {:ok, %{mtime: mtime}} ->
        mtime_unix = mtime |> NaiveDateTime.from_erl!() |> DateTime.from_naive!("Etc/UTC")
        now = DateTime.utc_now()
        seconds_passed = DateTime.diff(now, mtime_unix)

        # Check if time as passed or there's something really off with the time
        seconds_passed >= @check_interval_seconds or seconds_passed < -@check_interval_seconds

      {:error, _} ->
        true
    end
  end

  @doc false
  @spec mark_checked() :: :ok
  def mark_checked() do
    path = check_file_path()
    File.mkdir_p!(Path.dirname(path))
    File.touch!(path)
  end

  defp check_file_path() do
    Path.join(data_dir(), "nerves_bootstrap_update_check")
  end

  # Match Nerves library's handling
  defp data_dir() do
    case System.get_env("XDG_DATA_HOME") do
      directory when is_binary(directory) -> Path.join(directory, "nerves")
      nil -> Path.expand("~/.nerves")
    end
  end
end
