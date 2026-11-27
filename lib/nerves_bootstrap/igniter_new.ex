# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.IgniterNew do
  # Support for `mix nerves.new --igniter`
  #
  # NervesBootstrap is a Mix archive, so it can't depend on Igniter. Instead,
  # it translates the `mix nerves.new` options to a `mix igniter.new`
  # invocation and lets the `igniter_new` archive and the `mix nerves.install`
  # task that ships with Nerves do the work.
  @moduledoc false

  @typedoc """
  The `mix nerves.new` options that affect the Igniter path

  * `:app` - the value of `--app` if it was passed
  * `:module` - the value of `--module` if it was passed
  * `:targets` - the validated `--target` options in the order they were passed
  * `:nerves_pack?` - `false` if `--no-nerves-pack` was passed. The
    networking libraries aren't installed then.
  * `:prerelease?` - `true` if `--prerelease` was passed
  * `:install` - the values of the `--install` options
  """
  @type options() :: [
          app: String.t() | nil,
          module: String.t() | nil,
          targets: [atom()],
          nerves_pack?: boolean(),
          prerelease?: boolean(),
          install: [String.t()]
        ]

  # What the project template gets from `nerves_pack`. Igniter projects list
  # these libraries directly since each has its own installer and
  # `nerves_pack` has no code of its own.
  #
  # The order matters: installers add the configuration for an application
  # that isn't configured yet to the top of `config/target.exs`, so mdns_lite
  # goes before vintage_net to end up below it like in the project template.
  # The network interfaces are in the template's order as well: usb0, eth0,
  # wlan0. nerves_ssh adds its configuration to the end of the file.
  #
  # `mix nerves.install` documents the same list. See
  # test/nerves_bootstrap/nerves_sync_test.exs.
  @networking_packages [
    "nerves_ssh",
    "mdns_lite",
    "vintage_net",
    "vintage_net_direct",
    "vintage_net_ethernet",
    "vintage_net_wifi",
    "nerves_time",
    "nerves_motd"
  ]

  @doc """
  Return the libraries that are installed for networking support

  These are what `nerves_pack` brings into projects that are created from the
  project template.
  """
  @spec networking_packages() :: [String.t()]
  def networking_packages(), do: @networking_packages

  @doc """
  Return whether the `igniter_new` archive is installed
  """
  @spec available?() :: boolean()
  def available?() do
    Mix.Task.get("igniter.new") != nil
  end

  @doc """
  Return the arguments for `mix igniter.new` that create the project
  """
  @spec argv(Path.t(), options()) :: [String.t()]
  def argv(path, opts) do
    module_args = if opts[:module], do: ["--module", opts[:module]], else: []

    # `mix igniter.new` doesn't know about `mix new`'s `--app`, but it can be
    # told to pass it on. The `=` form is required. Otherwise the value looks
    # like another option to igniter.new.
    app_args = if opts[:app], do: ["--with-args=--app #{opts[:app]}"], else: []

    target_args =
      opts |> Keyword.get(:targets, []) |> Enum.flat_map(&["--target", Atom.to_string(&1)])

    # * `--sup`: Nerves projects have an Application module
    # * `--no-git`: `mix nerves.new` has never created Git commits
    # * `--yes`: Nothing to confirm since everything in the project is new
    #
    # Everything after `--yes` isn't known to igniter.new, so it gets passed to
    # the installers.
    [path, "--install", Enum.join(install_specs(opts), ",")] ++
      module_args ++ ["--sup", "--no-git"] ++ app_args ++ ["--yes"] ++ target_args
  end

  @doc """
  Return the packages that Igniter is asked to install

  These are `nerves` and, unless disabled with `--no-nerves-pack`, the
  libraries in `networking_packages/0`. `nerves` is first so that the other
  installers find a Nerves project. `--install` options either replace the
  source for one of those (`nerves@path:/src/nerves`) or get added to the end
  of the list.
  """
  @spec install_specs(options()) :: [String.t()]
  def install_specs(opts) do
    nerves = if opts[:prerelease?], do: "nerves@#{prerelease_version()}", else: "nerves"
    networking = if Keyword.get(opts, :nerves_pack?, true), do: @networking_packages, else: []

    opts
    |> Keyword.get(:install, [])
    |> Enum.flat_map(&String.split(&1, ",", trim: true))
    |> Enum.map(&(&1 |> String.trim() |> expand_path_spec()))
    |> Enum.reject(&(&1 == ""))
    |> Enum.reduce([nerves | networking], &merge_spec/2)
  end

  @doc """
  Create the project by running `mix igniter.new` with the specified arguments
  """
  @spec run([String.t()]) :: :ok | {:error, :not_installed}
  def run(argv) do
    # The runner is replaceable so that the tests don't need the archive and
    # Internet access.
    case Application.get_env(:nerves_bootstrap, :igniter_new_runner) do
      nil ->
        if available?() do
          _ = Mix.Task.run("igniter.new", argv)
          :ok
        else
          {:error, :not_installed}
        end

      runner when is_function(runner, 1) ->
        runner.(argv)
    end
  end

  # "~> 2.0.0-pre.3" -> "2.0.0-pre.3". Igniter pins versions that are fully
  # specified, which is what's wanted for prereleases.
  defp prerelease_version() do
    NervesBootstrap.Versions.package_reqs().nerves_prerelease
    |> String.replace_prefix("~> ", "")
  end

  defp merge_spec(spec, specs) do
    name = package_name(spec)

    case Enum.find_index(specs, &(package_name(&1) == name)) do
      nil -> specs ++ [spec]
      index -> List.replace_at(specs, index, spec)
    end
  end

  defp package_name(spec) do
    spec |> String.split("@", parts: 2) |> hd()
  end

  # igniter.new changes to the new project's directory before it installs
  # anything, so relative paths have to be expanded here.
  defp expand_path_spec(spec) do
    case String.split(spec, "@path:", parts: 2) do
      [package, path] -> "#{package}@path:#{Path.expand(path)}"
      _ -> spec
    end
  end
end
