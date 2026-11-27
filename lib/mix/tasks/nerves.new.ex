# SPDX-FileCopyrightText: 2016 Justin Schneck
# SPDX-FileCopyrightText: 2017 Frank Hunleth
# SPDX-FileCopyrightText: 2019 Milton Mazzarri
# SPDX-FileCopyrightText: 2019 Todd Resudek
# SPDX-FileCopyrightText: 2020 TORIFUKU Kaiou
# SPDX-FileCopyrightText: 2022 Jason Axelson
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Mix.Tasks.Nerves.New do
  @shortdoc "Creates a new Nerves application"
  @moduledoc """
  Creates a new Nerves project

      mix nerves.new PATH [--module MODULE] [--app APP] [--target TARGET] [--cookie STRING] [--no-nerves-pack] [--prerelease] [--igniter [--install PACKAGES]]

  The project will be created at PATH. The application name and module name
  will be inferred from PATH unless `--module` or `--app` is given.

  An `--app` option can be given in order to name the OTP application for the
  project.

  A `--module` option can be given in order to name the modules in the
  generated code skeleton.

  A `--target` option can be given to limit support to one or more of the
  [officially Nerves
  systems](https://nerves.hexdocs.pm/supported-targets.html).

  A `--cookie` options can be given to set the Erlang distribution
  cookie in `vm.args`. This defaults to a randomly generated string.

  Generate a project without `nerves_pack` support by passing
  `--no-nerves-pack`.

  Generate a project using the prerelease version of Nerves by passing
  `--prerelease`.

  Generate a project using [Igniter](https://igniter.hexdocs.pm) installers
  instead of the built-in project template by passing `--igniter`.
  See the Igniter section below.

  ## Examples

      mix nerves.new blinky

  Is equivalent to:

      mix nerves.new blinky --module Blinky

  Generate a project that only supports Raspberry Pi 5

      mix nerves.new blinky --target rpi5

  Generate a project that supports Raspberry Pi 5 and Raspberry Pi Zero

      mix nerves.new blinky --target rpi5 --target rpi0

  Generate a project without `nerves_pack`

      mix nerves.new blinky --no-nerves-pack

  Generate a project using the prerelease version of Nerves

      mix nerves.new blinky --prerelease

  ## Igniter

  `--igniter` is an alternative way of creating the project. Rather than
  copying the project template, it runs

      mix igniter.new PATH --install nerves,nerves_ssh,mdns_lite,vintage_net,vintage_net_direct,vintage_net_ethernet,vintage_net_wifi,nerves_time,nerves_motd --sup --no-git --yes

  which creates a plain Elixir project with `mix new` and then has each
  package set itself up by running its installer (`mix nerves.install`, `mix
  nerves_ssh.install`, etc.). Like with the project template, the project
  uses the latest release of Nerves unless `--prerelease` is passed. The
  version of Nerves that gets installed needs to have the `mix nerves.install`
  task.

  `nerves_pack` isn't installed. It has no code of its own, so the libraries
  that it brings into template projects are installed directly instead.

  This requires the `igniter_new` archive:

      mix archive.install hex igniter_new

  The other options work as follows with `--igniter`:

    * `--app`, `--module` and `--target` have the same meaning. When no
      targets are given, `mix nerves.install` adds the default ones.
    * `--no-nerves-pack` only installs `nerves`. The libraries for SSH, mDNS,
      networking and time synchronization are left out. Add the ones that you
      want back with `--install`.
    * `--prerelease` installs the prerelease version of Nerves that this
      version of Nerves Bootstrap knows about rather than the latest release.
    * `--install` adds to or changes the packages that get installed. It can
      be passed more than once or be given a comma-separated list. Packages
      are specified the same way as with `mix igniter.install`. For example,
      `--install nerves_hub_link` adds a package and
      `--install nerves@github:nerves-project/nerves@v2` replaces where
      Nerves comes from. It is only allowed with `--igniter`.
    * `--cookie` isn't supported. Change the cookie in the generated `mix.exs`.

  Create a project for the Raspberry Pi 5 and Raspberry Pi Zero using Igniter:

      mix nerves.new blinky --igniter --target rpi5 --target rpi0
  """

  use Mix.Task
  import Mix.Generator

  alias NervesBootstrap.IgniterNew
  alias NervesBootstrap.Versions

  # The default targets, the target to system mapping below and the Nerves
  # system versions in `NervesBootstrap.Versions` are duplicated in the Nerves
  # library's `Nerves.Igniter` module for use by `mix nerves.install`.
  # test/nerves_bootstrap/nerves_sync_test.exs checks that they match.
  @default_targets [
    :bbb,
    :mangopi_mq_pro,
    :qemu_aarch64,
    :rpi,
    :rpi0,
    :rpi0_2,
    :rpi2,
    :rpi3,
    :rpi4,
    :rpi5,
    :trellis,
    :x86_64
  ]

  # Mapping between easy-to-type target name and the actual Nerves system package
  # It is ok for this list to contain more mappings than what's listed above.
  @target_systems %{
    bbb: :nerves_system_bbb,
    grisp2: :nerves_system_grisp2,
    mangopi_mq_pro: :nerves_system_mangopi_mq_pro,
    npi_imx6ull: :nerves_system_npi_imx6ull,
    osd32mp1: :nerves_system_osd32mp1,
    qemu_aarch64: :nerves_system_qemu_aarch64,
    rpi: :nerves_system_rpi,
    rpi0: :nerves_system_rpi0,
    rpi0_2: :nerves_system_rpi0_2,
    rpi2: :nerves_system_rpi2,
    rpi3: :nerves_system_rpi3,
    rpi3a: :nerves_system_rpi3a,
    rpi4: :nerves_system_rpi4,
    rpi5: :nerves_system_rpi5,
    trellis: :nerves_system_trellis,
    x86_64: :nerves_system_x86_64
  }

  @new [
    {:eex, "new/config/config.exs", "config/config.exs"},
    {:eex, "new/config/host.exs", "config/host.exs"},
    {:eex, "new/config/runtime.exs", "config/runtime.exs"},
    {:eex, "new/config/target.exs", "config/target.exs"},
    {:eex, "new/lib/app_name.ex", "lib/app_name.ex"},
    {:eex, "new/lib/app_name/application.ex", "lib/app_name/application.ex"},
    {:eex, "new/test/test_helper.exs", "test/test_helper.exs"},
    {:eex, "new/test/app_name_test.exs", "test/app_name_test.exs"},
    {:eex, "new/rel/vm.args.eex", "rel/vm.args.eex"},
    {:eex, "new/rootfs_overlay/etc/iex.exs", "rootfs_overlay/etc/iex.exs"},
    {:text, "new/.gitignore", ".gitignore"},
    {:text, "new/.formatter.exs", ".formatter.exs"},
    {:eex, "new/mix.exs", "mix.exs"},
    {:eex, "new/README.md", "README.md"},
    {:keep, "new/rel", "rel"}
  ]

  @new_2 Enum.map(@new, fn {format, source, target} ->
           {format, String.replace_prefix(source, "new/", "new-2/"), target}
         end)

  @reserved_names ~w[nerves]

  # Embed all defined templates
  root = Path.expand("../../../templates", __DIR__)

  for mapping <- [@new, @new_2] do
    for {format, source, _} <- mapping do
      if format != :keep do
        @external_resource Path.join(root, source)
        defp render(unquote(source)), do: unquote(File.read!(Path.join(root, source)))
      end
    end
  end

  @switches [
    app: :string,
    module: :string,
    target: :keep,
    cookie: :string,
    nerves_pack: :boolean,
    prerelease: :boolean,
    source_date_epoch: :integer,
    igniter: :boolean,
    install: :keep
  ]

  # The success typings are the literals, which trips :underspecs
  @dialyzer {:nowarn_function, default_targets: 0, target_systems: 0}

  @doc false
  @spec default_targets() :: [atom()]
  def default_targets(), do: @default_targets

  @doc false
  @spec target_systems() :: %{atom() => atom()}
  def target_systems(), do: @target_systems

  @impl Mix.Task
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Nerves Bootstrap #{Versions.bootstrap_vsn()}")
  end

  def run(argv) do
    # This version check is needed since installing Nerves Bootstrap on an
    # old version of Elixir only results in a warning.
    if not Versions.supported_elixir?() do
      Mix.raise("""
      Nerves Bootstrap #{Versions.bootstrap_vsn()} creates projects that require Elixir #{Versions.elixir_req()}.

      You have Elixir #{System.version()}. Please update your Elixir version or downgrade
      the version of Nerves Bootstrap that you're using.

      See https://nerves.hexdocs.pm/installation.html for more information on
      setting up your environment.
      """)
    end

    {opts, argv} =
      case OptionParser.parse(argv, strict: @switches) do
        {opts, argv, []} ->
          {opts, argv}

        {_opts, _argv, [switch | _]} ->
          Mix.raise("Invalid option: " <> switch_to_string(switch))
      end

    case argv do
      [] ->
        Mix.Task.run("help", ["nerves.new"])

      [path | _] ->
        app = opts[:app] || Path.basename(Path.expand(path))
        check_application_name!(app, !!opts[:app])
        mod = opts[:module] || Macro.camelize(app)
        check_module_name_validity!(mod)
        check_module_name_availability!(mod)

        run(app, mod, path, opts)
    end
  end

  defp run(app, _mod, _path, _opts) when app in @reserved_names,
    do: Mix.raise("New projects cannot be named '#{app}'")

  defp run(app, mod, path, opts) do
    System.delete_env("MIX_TARGET")

    targets = parse_targets!(opts)

    cond do
      opts[:igniter] ->
        run_igniter(path, targets, opts)

      Keyword.has_key?(opts, :install) ->
        Mix.raise("--install is only supported together with --igniter")

      true ->
        run_template(app, mod, path, targets, opts)
    end
  end

  defp parse_targets!(opts) do
    targets = Keyword.get_values(opts, :target)
    known_targets = Map.keys(@target_systems) |> Enum.sort()

    Enum.map(targets, fn target ->
      target = String.to_atom(target)

      if target not in known_targets do
        targets = Enum.join(known_targets, "\n  ")

        Mix.raise("""
        Unknown target #{inspect(target)}

        Known targets:
          #{targets}

        If you don't want any of these targets, one option is to pick one
        and change the references to it in the resulting mix.exs.
        """)
      end

      target
    end)
  end

  defp run_template(app, mod, path, targets, opts) do
    in_umbrella? = in_umbrella?(path)
    nerves_pack? = Keyword.get(opts, :nerves_pack, true)
    targets = if targets == [], do: @default_targets, else: targets
    cookie = opts[:cookie]
    source_date_epoch = Keyword.get(opts, :source_date_epoch, generate_source_date_epoch())
    elixir_version = System.version() |> Version.parse!()

    binding = [
      app_name: app,
      app_module: mod,
      elixir_req: "~> #{elixir_version.major}.#{elixir_version.minor}",
      bootstrap_req: Versions.bootstrap_req(),
      package_reqs: Versions.package_reqs(),
      in_umbrella: in_umbrella?,
      nerves_pack?: nerves_pack?,
      targets: targets,
      target_systems: @target_systems,
      cookie: cookie,
      source_date_epoch: source_date_epoch
    ]

    template = if opts[:prerelease], do: @new_2, else: @new
    copy_from(path, binding, template)

    print_mix_info(path)
  end

  # Options that only make sense for the project template
  @template_only_switches [cookie: "--cookie", source_date_epoch: "--source-date-epoch"]

  defp run_igniter(path, targets, opts) do
    for {key, switch} <- @template_only_switches, Keyword.has_key?(opts, key) do
      Mix.raise("#{switch} is not supported together with --igniter")
    end

    argv =
      IgniterNew.argv(path,
        app: opts[:app],
        module: opts[:module],
        targets: targets,
        nerves_pack?: Keyword.get(opts, :nerves_pack, true),
        prerelease?: Keyword.get(opts, :prerelease, false),
        install: Keyword.get_values(opts, :install)
      )

    project_dir = Path.expand(path)

    # igniter.new changes the current directory to the new project
    case File.cd!(File.cwd!(), fn -> IgniterNew.run(argv) end) do
      :ok ->
        check_nerves_installed!(project_dir, argv)
        print_mix_info(path)

      {:error, :not_installed} ->
        Mix.raise("""
        The --igniter option requires the igniter_new archive. Install it by running:

          mix archive.install hex igniter_new

        Then try again, or run `mix nerves.new` without --igniter to create the
        project from the built-in template.
        """)
    end
  end

  # Igniter adds packages that don't have installers to the dependency list
  # and carries on. If that happened to Nerves, the result is a regular Elixir
  # project.
  defp check_nerves_installed!(project_dir, argv) do
    if !File.regular?(Path.join(project_dir, "config/target.exs")) do
      Mix.raise("""
      The project at #{project_dir} was created, but it wasn't set up for Nerves.

      This happens when the version of Nerves that was installed doesn't have
      the `mix nerves.install` task.

      Remove the project directory and then either run `mix nerves.new` without
      --igniter or use --install to select a version of Nerves that has the
      installer. For example, `--install nerves@github:nerves-project/nerves`.

      The command that was run was:

        mix igniter.new #{Enum.map_join(argv, " ", &quote_arg/1)}
      """)
    end
  end

  defp quote_arg(arg) do
    if String.contains?(arg, " "), do: inspect(arg), else: arg
  end

  defp recompile(regex) do
    if Code.ensure_loaded?(Regex) and function_exported?(Regex, :recompile!, 1) do
      apply(Regex, :recompile!, [regex])
    else
      regex
    end
  end

  defp print_mix_info(path) do
    Mix.shell().info("""
    Your Nerves project was created successfully.

    You should now pick a target. See https://nerves.hexdocs.pm/supported-targets.html
    for supported target tags. If your target is on the list, set `MIX_TARGET`
    to its tag name:

    For example, run the following for the Raspberry Pi 5:

      $ export MIX_TARGET=rpi5

    If you will be using a custom system, update the `mix.exs`
    dependencies to point to the desired system's package.

    Now download the dependencies and build a firmware archive:

      $ cd #{path}
      $ mix deps.get
      $ mix firmware

    If your target boots up using a MicroSD card like a Raspberry Pi 5,
    then insert the card into a reader on your computer and run:

      $ mix burn

    Then plug the MicroSD card into the target and power it up. See target
    documentation above for more information and other targets.
    """)
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp check_application_name!(name, from_app_flag) do
    if !(name =~ recompile(~r/^[a-z][\w_]*$/)) do
      extra =
        if from_app_flag do
          ""
        else
          ". The application name is inferred from the path, if you'd like to " <>
            "explicitly name the application then use the `--app APP` option."
        end

      Mix.raise(
        "Application name must start with a letter and have only lowercase " <>
          "letters, numbers and underscore, got: #{inspect(name)}" <> extra
      )
    end
  end

  defp check_module_name_validity!(name) do
    if !(name =~ recompile(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/)) do
      Mix.raise(
        "Module name must be a valid Elixir alias (for example: Foo.Bar), got: #{inspect(name)}"
      )
    end
  end

  defp check_module_name_availability!(name) do
    name = Module.concat(Elixir, name)

    if Code.ensure_loaded?(name) do
      Mix.raise("Module name #{inspect(name)} is already taken, please choose another name")
    end
  end

  defp copy_from(target_dir, binding, mapping) when is_list(mapping) do
    app_name = Keyword.fetch!(binding, :app_name)

    Enum.each(mapping, fn {format, source, target_path} ->
      target = Path.join(target_dir, String.replace(target_path, "app_name", app_name))

      case format do
        :keep ->
          File.mkdir_p!(target)

        :text ->
          create_file(target, render(source))

        :append ->
          append_to(Path.dirname(target), Path.basename(target), render(source))

        :eex ->
          contents = EEx.eval_string(render(source), binding, file: source, trim: false)
          create_file(target, contents)
      end
    end)
  end

  defp append_to(path, file, contents) do
    file = Path.join(path, file)
    File.write!(file, File.read!(file) <> contents)
  end

  defp in_umbrella?(app_path) do
    umbrella = Path.expand(Path.join([app_path, "..", ".."]))

    File.exists?(Path.join(umbrella, "mix.exs")) &&
      Mix.Project.in_project(:umbrella_check, umbrella, fn _ ->
        path = Mix.Project.config()[:apps_path]
        path && Path.expand(path) == Path.join(umbrella, "apps")
      end)
  catch
    _, _ -> false
  end

  defp generate_source_date_epoch() do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
