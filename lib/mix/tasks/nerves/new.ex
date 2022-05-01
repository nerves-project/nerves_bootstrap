defmodule Mix.Tasks.Nerves.New do
  use Mix.Task
  import Mix.Generator

  @nerves Path.expand("../../../..", __DIR__)

  @bootstrap_vsn Mix.Project.config()[:version]
  @bootstrap_vsn_no_patch (
                            v = Version.parse!(@bootstrap_vsn)
                            "#{v.major}.#{v.minor}"
                          )
  @nerves_vsn "1.7.15"
  @nerves_dep ~s[{:nerves, "~> #{@nerves_vsn}", runtime: false}]
  @shoehorn_vsn "0.9.0"
  @runtime_vsn "0.11.6"
  @ring_logger_vsn "0.8.3"
  @nerves_pack_vsn "0.6.0"
  @toolshed_vsn "0.2.13"

  @elixir_vsn "~> 1.11"
  @shortdoc "Creates a new Nerves application"

  @targets [
    {:rpi, "1.18"},
    {:rpi0, "1.18"},
    {:rpi2, "1.18"},
    {:rpi3, "1.18"},
    {:rpi3a, "1.18"},
    {:rpi4, "1.18"},
    {:bbb, "2.13"},
    {:osd32mp1, "0.9"},
    {:x86_64, "1.18"}
  ]

  @new [
    {:eex, "new/config/config.exs", "config/config.exs"},
    {:eex, "new/config/host.exs", "config/host.exs"},
    {:eex, "new/config/target.exs", "config/target.exs"},
    {:eex, "new/lib/app_name.ex", "lib/app_name.ex"},
    {:eex, "new/lib/app_name/application.ex", "lib/app_name/application.ex"},
    {:eex, "new/test/test_helper.exs", "test/test_helper.exs"},
    {:eex, "new/test/app_name_test.exs", "test/app_name_test.exs"},
    {:text, "new/rel/vm.args.eex", "rel/vm.args.eex"},
    {:eex, "new/rootfs_overlay/etc/iex.exs", "rootfs_overlay/etc/iex.exs"},
    {:text, "new/.gitignore", ".gitignore"},
    {:text, "new/.formatter.exs", ".formatter.exs"},
    {:eex, "new/mix.exs", "mix.exs"},
    {:eex, "new/README.md", "README.md"},
    {:keep, "new/rel", "rel"}
  ]

  @reserved_names ~w[nerves]

  # Embed all defined templates
  root = Path.expand("../../../../templates", __DIR__)

  for {format, source, _} <- @new do
    unless format == :keep do
      @external_resource Path.join(root, source)
      defp render(unquote(source)), do: unquote(File.read!(Path.join(root, source)))
    end
  end

  @moduledoc """
  Creates a new Nerves project

      mix nerves.new PATH [--module MODULE] [--app APP] [--target TARGET] [--cookie STRING]

  The project will be created at PATH. The application name and module name
  will be inferred from PATH unless `--module` or `--app` is given.

  An `--app` option can be given in order to name the OTP application for the
  project.

  A `--module` option can be given in order to name the modules in the
  generated code skeleton.

  A `--target` option can be given to limit support to one or more of the
  [officially Nerves
  systems](https://hexdocs.pm/nerves/targets.html#supported-targets-and-systems).

  A `--cookie` options can be given to set the Erlang distribution
  cookie in `vm.args`. This defaults to a randomly generated string.

  Generate a project without `nerves_pack` support by passing
  `--no-nerves-pack`.

  ## Examples

      mix nerves.new blinky

  Is equivalent to:

      mix nerves.new blinky --module Blinky

  Generate a project that only supports Raspberry Pi 3

      mix nerves.new blinky --target rpi3

  Generate a project that supports Raspberry Pi 3 and Raspberry Pi Zero

      mix nerves.new blinky --target rpi3 --target rpi0

  Generate a project without `nerves_pack`

      mix nerves.new blinky --no-nerves-pack
  """

  @switches [
    app: :string,
    module: :string,
    target: :keep,
    cookie: :string,
    nerves_pack: :boolean,
    source_date_epoch: :integer
  ]

  @impl Mix.Task
  def run([version]) when version in ~w(-v --version) do
    Mix.shell().info("Nerves Bootstrap v#{@bootstrap_vsn}")
  end

  def run(argv) do
    unless Version.match?(System.version(), @elixir_vsn) do
      Mix.raise("""
      Nerves Bootstrap v#{@bootstrap_vsn} creates projects that require Elixir #{@elixir_vsn}.

      You have Elixir #{System.version()}. Please update your Elixir version or downgrade
      the version of Nerves Bootstrap that you're using.

      See https://hexdocs.pm/nerves/installation.html for more information on
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

    nerves_path = nerves_path(path, Keyword.get(opts, :dev, false))
    in_umbrella? = in_umbrella?(path)
    nerves_pack? = Keyword.get(opts, :nerves_pack, true)

    targets = Keyword.get_values(opts, :target)
    default_targets = Keyword.keys(@targets)

    targets =
      Enum.map(targets, fn target ->
        target = String.to_atom(target)

        unless target in default_targets do
          targets =
            @targets
            |> Enum.map(&elem(&1, 0))
            |> Enum.join("\n")

          Mix.raise("""
          Unknown target #{inspect(target)}
          Supported targets
          #{targets}
          """)
        end

        Enum.find(@targets, &(elem(&1, 0) == target))
      end)

    targets = if targets == [], do: @targets, else: targets
    cookie = opts[:cookie]
    source_date_epoch = Keyword.get(opts, :source_date_epoch, generate_source_date_epoch())

    binding = [
      app_name: app,
      app_module: mod,
      bootstrap_vsn: @bootstrap_vsn_no_patch,
      shoehorn_vsn: @shoehorn_vsn,
      runtime_vsn: @runtime_vsn,
      ring_logger_vsn: @ring_logger_vsn,
      elixir_req: @elixir_vsn,
      nerves_dep: nerves_dep(nerves_path),
      in_umbrella: in_umbrella?,
      nerves_pack?: nerves_pack?,
      nerves_pack_vsn: @nerves_pack_vsn,
      toolshed_vsn: @toolshed_vsn,
      targets: targets,
      cookie: cookie,
      source_date_epoch: source_date_epoch
    ]

    copy_from(path, binding, @new)
    # Parallel installs
    install? = Mix.shell().yes?("\nFetch and install dependencies?")

    File.cd!(path, fn ->
      if install? && Code.ensure_loaded?(Hex) do
        cmd("mix deps.get")
      end

      print_mix_info(path)
    end)
  end

  defp recompile(regex) do
    if Code.ensure_loaded?(Regex) and function_exported?(Regex, :recompile!, 1) do
      apply(Regex, :recompile!, [regex])
    else
      regex
    end
  end

  defp cmd(cmd) do
    Mix.shell().info([:green, "* running ", :reset, cmd])

    case Mix.shell().cmd(cmd, quiet: true) do
      0 ->
        true

      _ ->
        Mix.shell().error([
          :red,
          "* error ",
          :reset,
          "command failed to execute, " <>
            "please run the following command again after installation: \"#{cmd}\""
        ])

        false
    end
  end

  defp print_mix_info(path) do
    command = ["$ cd #{path}"]

    Mix.shell().info("""
    Your Nerves project was created successfully.

    You should now pick a target. See https://hexdocs.pm/nerves/targets.html#content
    for supported targets. If your target is on the list, set `MIX_TARGET`
    to its tag name:

    For example, for the Raspberry Pi 3 you can either
      $ export MIX_TARGET=rpi3
    Or prefix `mix` commands like the following:
      $ MIX_TARGET=rpi3 mix firmware

    If you will be using a custom system, update the `mix.exs`
    dependencies to point to desired system's package.

    Now download the dependencies and build a firmware archive:
      #{Enum.join(command, "\n")}
      $ mix deps.get
      $ mix firmware

    If your target boots up using an SDCard (like the Raspberry Pi 3),
    then insert an SDCard into a reader on your computer and run:
      $ mix burn

    Plug the SDCard into the target and power it up. See target documentation
    above for more information and other targets.
    """)
  end

  defp switch_to_string({name, nil}), do: name
  defp switch_to_string({name, val}), do: name <> "=" <> val

  defp check_application_name!(name, from_app_flag) do
    unless name =~ recompile(~r/^[a-z][\w_]*$/) do
      extra =
        if !from_app_flag do
          ". The application name is inferred from the path, if you'd like to " <>
            "explicitly name the application then use the `--app APP` option."
        else
          ""
        end

      Mix.raise(
        "Application name must start with a letter and have only lowercase " <>
          "letters, numbers and underscore, got: #{inspect(name)}" <> extra
      )
    end
  end

  defp check_module_name_validity!(name) do
    unless name =~ recompile(~r/^[A-Z]\w*(\.[A-Z]\w*)*$/) do
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

  defp nerves_dep("deps/nerves"), do: @nerves_dep
  defp nerves_dep(path), do: ~s[{:nerves, path: #{inspect(path)}, runtime: false, override: true}]

  defp nerves_path(path, true) do
    absolute = Path.expand(path)
    relative = Path.relative_to(absolute, @nerves)

    if absolute == relative do
      Mix.raise("--dev project must be inside Nerves directory")
    end

    relative
    |> Path.split()
    |> Enum.map(fn _ -> ".." end)
    |> Path.join()
  end

  defp nerves_path(_path, false) do
    "deps/nerves"
  end

  defp copy_from(target_dir, binding, mapping) when is_list(mapping) do
    app_name = Keyword.fetch!(binding, :app_name)

    for {format, source, target_path} <- mapping do
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
    end
  end

  defp append_to(path, file, contents) do
    file = Path.join(path, file)
    File.write!(file, File.read!(file) <> contents)
  end

  defp in_umbrella?(app_path) do
    try do
      umbrella = Path.expand(Path.join([app_path, "..", ".."]))

      File.exists?(Path.join(umbrella, "mix.exs")) &&
        Mix.Project.in_project(:umbrella_check, umbrella, fn _ ->
          path = Mix.Project.config()[:apps_path]
          path && Path.expand(path) == Path.join(umbrella, "apps")
        end)
    catch
      _, _ -> false
    end
  end

  defp generate_source_date_epoch() do
    DateTime.utc_now() |> DateTime.to_unix()
  end
end
