<!--
  SPDX-FileCopyrightText: None
  SPDX-License-Identifier: CC0-1.0
-->

# Changelog

## 1.14.2 - 2025-12-25

* Changes
  * Remove question for whether to install deps on `nerves.new` since it
    interfered with scripted use, and you always had to run `mix deps.get` to
    download the Nerves system anyway.

## 1.14.1 - 2025-11-04

* Changes
  * Add guidance in mix.exs for specifying listeners so that they're not
    included in target builds. This mainly affects Phoenix users.

## 1.14.0 - 2025-10-20

* New project generator updates
  * In `vm.args.eex`, use interactive mode rather than embedded mode as a
    default. Interactive mode boot performance has improved and it's generally a
    more user friendly default for those who don't know about it.
  * Replaced `rpi3a` target with `rpi0_2` to encourage Raspberry Pi Zero 2W
    users to prefer it.

* Changes
  * Disable Elixir 1.19 parallel compilation. This is intended to be a temporary
    fix until the Nerves build issue can be fixed.
  * Add REUSE compliance for licensing and copyright info

## 1.13.1 - 2024-09-27

* New project generator updates
  * Fix dialyzer warning in generated project
  * Adjust Erlang doc URLS in `vm.args.eex` to the new locations

## 1.13.0 - 2024-07-05

Adds support for Elixir 1.17 and OTP 27. This now requires
Elixir 1.13 as the minimum supported version

* New project generator updates
  * Adjust `vm.args.eex` to support Elixir 1.17 changes
  * Synchronized to match the Elixir `mix new` generated content
  * Removes the generated `target/0` function in favor of `Nerves.Runtime.mix_target()`
  * Generated `mix.exs` now uses the current Elixir version in use
    as the required version for the newly generated project
  * Various dependency updates

## 1.12.2 - 2024-04-24

* Fixes
  * Targets documentation URL was outdated
  * Simplify searching for SSH keys in the `nerves.new` generated config

* Updates
  * Changes to new Elixir slack URL in template README.md
  * Adds Discord to template README.md

## 1.12.1 - 2023-09-30

* Fixes
  * Nerves.Bootstrap would fail to start in some cases where the dependencies
    had not been fetched and Nerves.Bootstrap would try to warn about the
    `:nerves` version requirement. This check has been moved to
    `deps.precompile` which happens after dependencies are fetched and also
    helps halt the build process if the `:nerves` version requirement is not

## 1.12.0 - 2023-09-27

* Potentially breaking changes
  * `:nerves >= 1.8.0` is now required to use this version of `nerves_bootstrap`.
    If you keep up-to-date, then this won't be an issue for you.

* Updates
  * Removed legacy tasks (tooling now maintained in [`:nerves`](https://github.com/nerves-project/nerves))

* New project generator updates
  * Default to regulatory domain (`00`) for WiFi
    * For US users, this means 5GHz won't work anymore since it's disabled in
      `00` (NO-IR = no initiating radiation) until you update your config to
      use `US`
  * Bumped all Nerves systems to latest

## 1.11.5 - 2023-07-07

* Updates
  * Support Elixir 1.15/OTP 26

* New project generator updates
  * Adjust `vm.args.eex` based on Elixir version
  * Fix typo in templates/new/config/host.exs
  * Run formatting as part of `mix nerves.new`
  * Adjust `:nerves_runtime` to be available on host
  * Add `nerves_system_mangopi_mq_pro` system
  * `:ring_logger` 0.10.0

## 1.11.4 - 2023-03-03

* Updates
  * Use Nerves v1.10.0 in new projects
  * Default to adding `-code_path_choice strict` to new projects to skip a few
    unnecessary path searches for archives
  * Default to moving the clock forward in erlinit. This reduces the time jump
    on boot for RTC-less devices.

## 1.11.3 - 2022-11-05

* Updates
  * Allow Nerves v1.9.0 to be used in new projects
  * Use console logger by default in host mode. This is more like the default
    Elixir configuration.

## 1.11.2 - 2022-09-11

* Updates
  * Remove references to `:build_embedded` since that option is planned for
    removal in Elixir 1.15 and it wasn't needed.

## 1.11.1 - 2022-07-07

* Fixes
  * Fixed backwards compatibility issue with building Nerves systems with Nerves
    1.7.x.

## 1.11.0 - 2022-07-06

* Potentially breaking changes
  * Elixir 1.11 or later is now required
  * Move the core `mix` tooling to `:nerves`
    * This is part of a bigger reorganization and adjustment to the bootstrap
      tooling in order to reduce it's footprint. However, these changes have
      been tested and are considered backwards compatible and most should not
      see any impact from it. If you were using `Nerves.Bootstrap.Aliases`
      module directly, you may notice adjusted aliases listed.

* Enhancements
  * Add GRiSP2 to officially supported Nerves devices
  * Improve message when unknown target is selected
  * Add `--no-nerves-pack` to nerves.new options doc

* New project generator updates
  * Remove `system_registry` option from generator
  * toolshed 0.2.26
  * shoehorn 0.9.1
  * nerves_runtime 0.13.0
  * ring_logger 0.8.5

## 1.10.6 - 2022-02-23

* New project generator updates
  * Update deprecated config option to MDNSLite
  * Update references to `mix burn` in new project comments
  * Update dependency versions to latest

## 1.10.5

* New project generator updates
  * Remove old reference to Mix.Config.

## 1.10.4

* New project generator updates
  * Update dependency versions to latest

## 1.10.3

* New project generator updates
  * Update dependency versions to latest
  * Add NervesMOTD to the `iex.exs`
  * Add more comments to commonly edited locations in the `mix.exs`

## 1.10.2

* New project generator updates
  * Strip everything but docs with `MIX_ENV=dev`

    Since most users don't use debug symbols, strip them out of the beams
    even for dev builds. This keeps docs, though. Here's are some firmware
    sizes to see the effect:

    circuits_quickstart_unstripped.fw 43597619
    circuits_quickstart_docs.fw 33595640
    circuits_quickstart_stripped.fw 33016963

    As you can see, this saves ~10 MB and retains docs.

## 1.10.1

* New project generator updates
  * Add `config/host.exs` so that there's a more obvious location for host-only
    configuration
  * Add `rootfs_overlay/etc/iex.exs` to the list of files to format with `mix
    format`

## 1.10.0

* New project generator updates
  * Added `osd32mp1` to default targets in new project generator.
    See [nerves_system_osd32mp1](https://github.com/nerves-project/nerves_system_osd32mp1) for system information.
  * Update formatting to more closely match Elixir 1.11's new project generator
  * Simplify the Nerves/Mix integration (now only an update to `config.exs`)
  * Bump Nerves to `~> 1.7.0`
  * Bump Shoehorn to `~> 0.7.0`
  * Disable busy waiting in the BEAM by default.

## 1.9.0

* New project generator updates
  * Bump [NervesPack to 0.4](https://hexdocs.pm/nerves_pack/changelog.html#v0-4-0)
    which drops `:nerves_firmware_ssh` in favor of `:nerves_ssh` and
    `:ssh_subsystem_fwup` for access and updates.
  * Bump Nerves to `~> 1.6.3`
  * Bump NervesRuntime to `~> 0.11.3`
  * Bump RingLogger to `~> 0.8.1`

## 1.8.1

* New project generator updates
  * Update systems to latest versions.
  * Add an example for overriding erlinit options using Mix config.

## 1.8.0

* New project generator updates
  * Bump Nerves to 1.6 and update systems.
  * Default to use `--nerves-pack`.
  * Remove options for `--init-gadget`.

## 1.7.1

* Enhancements
  * Updated Elixir 1.10 deprecated function calls.

## 1.7.0

* Enhancements
  * Improved support for reproducible builds in new projects by setting
    `source_date_epoch`. Existing projects can add this to the `:nerves` config.

    For example:

    ```elixir
    config :nerves, source_date_epoch: "1577467691"
    ```

  * Added support for generating new projects using `nerves_pack` instead
    of `nerves_init_gadget`. See [nerves_pack](https://github.com/nerves-project/nerves_pack) for more information.

    For example:

    ```bash
    mix nerves.new my_app --nerves-pack
    ```

## 1.6.3

* Enhancements
  * Don't allow projects to be named `nerves`. Those won't work anyway.

## 1.6.2

* Enhancements
  * Synchronize new project files to better match the versions from `mix new`

## 1.6.1

* Enhancements
  * Added `rpi4` to default targets in new project generator.
    See [nerves_system_rpi4](https://github.com/nerves-project/nerves_system_rpi4) for system information.
  * Update release config to only strip beams for `:prod` firmware.

* Bug fixes
  * Fix `--cookie` in new project generator for overriding the cookie.

## 1.6.0

* Enhancements
  * Updated new project generator to use Elixir ~> 1.9

## 1.5.3

* Bug fixes
  * Change distillery to ~> 2.0 in the new project generator.

## 1.5.2

* Bug fixes
  * Add distillery ~> 2.1 to the new project generator.
  * Lock down the `nerves` dependency to ~> 1.4.5 in new projects.

## 1.5.1

* Bug fixes
  * Compile distillery before nerves when included as an optional dependency.

## 1.5.0

* Enhancements
  * New projects include [nerves_init_gadget](https://hex.pm/packages/nerves_init_gadget) by default.
    If you want a minimal project that does not include `nerves_init_gadget`,
    pass `--no-init-gadget`.

## 1.4.3

* Enhancements
  * Create mix.exs files with `build_embedded: true` so that build products
    aren't stored in the source tree. This helps fix a source of confusion when
    switching targets and C/C++ build products don't get rebuilt.
  * Improve the missing ssh key error message in config.exs

## 1.4.2

* Enhancements
  * Added rpi3a to default supported targets list. See [nerves_system_rpi3a](https://github.com/nerves-project/nerves_system_rpi3a).
  * Bumped the minimum versions from 1.5 to 1.6.
  * Improved error message when trying to create new projects that support
    Elixir ~> 1.8 while running a version that is < 1.8.
  * Set required bootstrap archive version to ~> major.minor of the version of
    `nerves_bootstrap` that generated the new project.

## 1.4.1

* Bug fixes
  * Configure nerves_bootstrap to support Elixir ~> 1.7.
    Use ~> 1.8 for new projects.

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
unexpectedly long compilation times when things like the Linux kernel or gcc
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
Rather than requiring your `mix.exs` file to be updated if the Nerves alias
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
