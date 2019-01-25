# Changelog

## 1.4.0

Version v1.4.0 adds support for Elixir 1.8's new built-in support for mix
targets. In Nerves, the `MIX_TARGET` was used to select the appropriate set of
dependencies for a device. This lets you switch between building for different
boards and your host. Elixir 1.8 pulls this support into `mix` and lets you
annotate dependencies for which targets they should be used.

See the [project update guide](https://hexdocs.pm/nerves/updating-projects.html#updating-from-v1-3-x-to-v1-4-x) to learn how to migrate your project.

* Enhancements
  * New projects are generated for Elixir 1.8.
  * Support non-RSA SSH keys in new projects.

## 1.3.4

* New project generator fixes
  * Enable `multi_time_warp` mode by default. This fixes an issue where the
    Erlang system clock wouldn't get updated after the clock was set.

## 1.3.3

* New project generator enhancements
  * Update `ring_logger` to `~> 0.6`.
  * Add `toolshed` `~> 0.2` and update `rootfs_overlay/etc/iex.exs`
  * Enable Erlang Distribution when `Mix.env() != :prod`
  * Remove `ev3` from default supported target list
  * Update `bbb` system version requirement to `~> 2.0`
  * Update all other system version requirements to `~> 1.5`

## 1.3.2

* Enhancements
  * Updated docs for `mix nerves.new`.

* Bug fixes
  * Invoke Nerves environment when calling `deps.compile`.
  * Display warning instead of raising when calling `mix run`.

## 1.3.1

* Enhancements
  * Use `:dhcpd` instead of `:linklocal` for `nerves_init_gadget` defaults.

## 1.3.0

* New features
  * Enable `heart` in the new project generator. This engages both a
    software-based watchdog (Erlang's `heart` feature) and a hardware-based one
    on systems that support it. If the Erlang VM becomes unresponsive, one of
    the watchdogs will reboot the processor. See the Erlang `heart`
    documentation for changing timeouts and adding callbacks to your
    application.
  * Enable `build_embedded`. This ensures that C build products are separated
    based on target and prevents many causes of x86 build products ending up
    on ARM targets unintentionally.

## 1.2.1

* Bug fixes
  * Add RingLogger to all deps in new project generator.
    This fixes an issue that causes new projects generated with `--init-gadget`
    to crash on boot running on the host.

## 1.2.0

Add support for generating new projects with `nerves_init_gadget`.
To generate a new project with `nerves_init_gadget` included,
pass `--init-gadget` to `mix nerves.new`

For example:

  mix nerves.new my_app --init-gadget

## 1.1.0

This release updates the new project generator to create projects that will work
with Elixir 1.7 and Distillery 2.0.

* Enhancements
  * Update new project generator to support `shoehorn` v0.4.
  * Bump minimum deps to latest versions.

## v1.0.1

* Enhancements
  * Update new project generator to target 1.0 systems

## v1.0.0

* Bug Fixes
  * Rename `provider` to `build_runner`. Fixes issues with running
    `mix nerves.system.shell` and `mix nerves.env --info`

## v1.0.0-rc.4

* Updates
  * New project generator no longer conditionally defines `application/0` in
    `mix.exs` depending on target. It is recommended to conditionally choose
    the main supervisors children instead.
  * New project generator moves the dependency `shoehorn` to be included for
    both `host` and `target` environments.


## v1.0.0-rc.3

* Updates
  * Various new project generator code format updates. Include `:runtime_tools`
    in `:extra_applications`.
* Bug fixes
  * Only display Nerves environment helper text when the Nerves environment
    is loaded. Fixes issues with running mix commands like `mix format -` that
    require the I/O to remain clean.

## v1.0.0-rc.2

* Updates
  * Remove `build_embedded` from the mix.exs since it was unnecessary
  * Fix update check in `mix local.nerves`
  * Various changes to align new project generator with the one in Elixir 1.6.
  * Add rootfs_overlay directory and populate it with an iex.exs to load the
    nerves_runtime IEX helpers. This replaces a common manual process of doing
    this or something similar afterwards.
  * Add a commented out reference for enabling Erlang's heartbeat monitor

## v1.0.0-rc.1

* Bug fixes
  * Various `mix format` updates to the template
  * Update template so that projects use v1.0.0-rc system releases so that they
    compile
  * Fix archive update check logic

## v1.0.0-rc.0

Nerves no longer automatically compiles any `nerves_package` that is missing
it's pre-compiled artifact. This turned out to rarely be desired and caused
unexpectantly long compilation times when things like the Linux kernel or gcc
got compiled.

When a pre-compiled artifact is missing, Nerves will now tell you what your
options are to resolve this. It could be retrying `mix deps.get` to download it
again. If you want to force compilation to happen, add a `:nerves` option for
the desired package in your top level project:

```elixir
  {:nerves_system_rpi0, "~> 1.0-rc", nerves: [compile: true]}
```

## v0.8.1

* Bug Fixes
  * `deps.get` and `deps.update` aliases should always be added to the
    project regardless of target.

## v0.8.0

The v0.7.x and earlier releases only required two aliases in your `mix.exs` to
pull in the Nerves enhancements to `mix.exs`. This releases adds more aliases.
Rather than requiring your `mix.exs` file to be updated if the Nerves aliase
hooks change in the future, we recommend updating your `mix.exs` as follows:

```elixir
  # mix.exs

  def project do
    [
      # ...
      aliases: ["loadconfig": [&bootstrap/1]],
    ]
  end

  # Starting nerves_bootstrap pulls in the Nerves hooks to mix, but only
  # if the MIX_TARGET environment variable is set.
  defp bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end
```

This release has the following changes:

* Enhancements
  * `precompile` will compile all Nerves packages instead of only the system and
    its children.
  * Calling `run` while `MIX_TARGET` is set will raise an exception for trying
    to run cross compiled code on the host.
  * `Application.start(:nerves_bootstrap)` will attempt to add aliases to the
    mix project on the top of the stack if `MIX_TARGET` is set.

## v0.7.1

* Enhancements
  * Added alias for `deps.update` to append `nerves.deps.get` to fetch
    artifacts.

## v0.7.0

* Enhancements
  * Added Mix task `nerves.deps.get`
  * `nerves_bootstrap` will check for updates when `nerves.deps.get` is called.
  * Added `Nerves.Bootstrap.add_aliases/1`
    This helper function ensures that your project has the required Nerves
    mix aliases defined and in the correct execution order. The function takes
    the existing aliases as a keyword list and injects the required Nerves aliases.
    You will need to update your `mix.exs` target aliases to use this version of
    `nerves_bootstrap` like this:

    ```elixir
    defp aliases(_target) do
      [
        # Add custom mix aliases here
      ]
      |> Nerves.Bootstrap.add_aliases()
    end
    ```

    You should also update your required dependency for nerves to
    `{:nerves, "~> 0.9", runtime: false}`
* Bug Fixes
  * disable precompiler when calling `mix nerves.clean` to prevent having to
    build the package so we can clean it.
  * Fixes issue where project dependencies that contain calls to `System.get_env`
    in their config or mix file or rebar deps that have `rebar-config.script`
    overrides that make `os:getenv` calls were not being configured for the
    cross compile environment.

## v0.6.4

* Enhancements
  * Changed update location from Github to hex.pm
  * Fixed compiler warning
  * Synchronize new project template with Elixir 1.6 updates (includes formatter)

## v0.6.3

* Enhancements
  * Removed unsupported systems from default targets and added x86_64.
  * Moved to independent hex package.

## v0.6.2

* Enhancements
  * [mix nerves.new] Use the new `rootfs_overlay` option
    rather than the deprecated `rootfs_additions` option and also recommend
    placing the relevant files in a top-level `rootfs_overlay` directory in the
    project root rather than in `config/rootfs_additions`.
  * [mix nerves.new] system dependencies are appended as a list so there is a
    clear location for where system specific dependencies are added.
  * [mix nerves.new] moved the config for bootloader above so that it is
    configured before importing target specific configuration.

## v0.6.1

* Enhancements
  * Improved error messages in `nerves.system.shell` Mix task. In particular,
    it now reminds you to set `MIX_TARGET`.
* Bug Fixes
  * The `nerves.env` Mix task (used internally by Nerves) now checks that your
    deps have been fetched before trying to load.
  * Fix extraneous whitespace in `mix.exs` generated by `mix nerves.new`

## v0.6.0

* Enhancements
  * New `nerves.system.shell` Mix task, which provides a consistent way to
    configure a Buildroot-based Nerves system on both OSX and Linux. This
    replaces the `nerves.shell` Mix task that was provided by the `nerves`
    dependency, which had not been fully implemented.
  * Add an optional `--disabled` flag to the `nerves.env` Mix task, which allows
    the Nerves environment to be compiled and loaded in a disabled state so that
    it doesn't try to actually cross-compile all the dependencies at load time.
    This is primarily used so that Mix tasks like `nerves.system.shell` can run
    on the host without having to wait for dependencies to compile when they
    won't even be used.
  * Related to the previous change, the `nerves.precompile` task does not try to
    compile the toolchain and system when `Nerves.Env` is loaded in a disabled
    state.

## v0.5.1

* Bug Fixes
  * System dependencies were not being built in order when system is the parent project

## v0.5.0

* Enhancements
  * Pass +Bc in vm.args to avoid accidental CTRL+C
  * Update deps and loosen version requirements
  * Include `bootloader` in new projects
* Bug Fixes
  * Choose the right compiler when parent project is a Nerves system package

## v0.4.0

* Enhancements
  * nerves.new
    * lock files are split by target
    * Target dependencies are explicitly broken out in mix.exs through passing
      `--target` to the generator. Defaults to declaring all officially supported
      Nerves Targets.
    * A default cookie is generated and placed in the vm.args. the cookie can
      be set by passing `--cookie`

## v0.3.1

* Bug Fixes
  * Added support for OTP 20: Fixes issue with RegEx producing false positives.

## v0.3.0

* Enhancements
  * nerves.new
    * defaults to Host target env
    * includes nerves_runtime
    * prompt to install deps and run nerves.release.init
    * unset MIX_TARGET when generating a new project
* Bug Fixes
  * removed rel/.gitignore from new project generator

## v0.2.2

* Enhancements
  * Added `mix local.nerves` for updating the bootstrap archive

## v0.2.1

* Bug Fixes
  * update nerves dep in new project generator to 0.4.0
* Enhancements
  * Additional debug output when setting `NERVES_DEBUG=1`
  * Ability to output information about the loaded Nerves env via `mix nerves.env --info`

## v0.2.0

* Enhancements
  * Support for nerves_package compiler

## v0.1.4

* Bug Fixes
  * Do not warn on import Supervisor.Spec
  * Silence alias location messages unless NERVES_DEBUG=1
* Enhancements
  * Support for Elixir 1.3.2

## v0.1.3

* Enhancements
  * Support for elixir ~> 1.3.0-rc.0
