# nerves_bootstrap

[![CircleCI](https://circleci.com/gh/nerves-project/nerves_bootstrap.svg?style=svg)](https://circleci.com/gh/nerves-project/nerves_bootstrap)
[![Hex.pm](https://img.shields.io/hexpm/v/nerves_bootstrap.svg)](https://hex.pm/packages/nerves_bootstrap)

`nerves_bootstrap` is an Elixir archive that supplies a new project generator
and enhances `mix` to support downloading or building all of the non-Elixir
things needed for Nerves-based projects. This includes crosscompilers, Linux
kernels, C libraries and more.

Most users should read the [Nerves Installation Guide](https://hexdocs.pm/nerves/installation.html)
for installing and using Nerves. Read on for details specific to
`nerves_bootstrap`.

## Installation

To install for the first time:

```bash
mix archive.install hex nerves_bootstrap
```

To update your `nerves_bootstrap`, you may either run the installation line above or:

```bash
mix local.nerves
```

If you need a specific version, run:

```bash
mix archive.install hex nerves_bootstrap 1.0.1
```

Finally, if you want to install from source:

```bash
git clone https://github.com/nerves-project/nerves_bootstrap.git
cd nerves_bootstrap
mix do deps.get, archive.build, archive.install
```

## Mix integration

By default, Nerves enhancements to `mix` are not included. This means that your
non-Nerves projects will continue to build like they did before. Projects that
use Nerves require additions to their `mix.exs` files. If you used `mix
nerves.new` to create your project, you'll already have those additions.

Nerves uses the `aliases` feature in `mix`. Ensure that the following code is in
your `mix.exs` to pull in the integration:

```elixir
  def project do
    [
      # ...
      aliases: [loadconfig: [&bootstrap/1]],
    ]
  end

  # Starting nerves_bootstrap pulls in the Nerves hooks to mix, but only
  # if the MIX_TARGET environment variable is set.
  defp bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end
```

## Mix tasks

### mix nerves.new

A mix task for creating new Nerves projects.

```bash
mix nerves.new my_new_nerves_project [options]
```

The new project's `mix.exs` contains logic for building any of the supported
hardware systems. The customary way of selecting the specific target is to
export `MIX_TARGET`. Here's a common build script:

```bash
export MIX_TARGET=rpi3
mix deps.get
mix firmware
mix firmware.burn
```

If you look at the generated `mix.exs`, you'll see how `MIX_TARGET` is used.

The generated project is minimal and may be difficult to use especially if
you're getting started with Nerves for the first time. The
[nerves_init_gadget](https://hex.pm/packages/nerves_init_gadget) project
simplifies initial configuration. To generate a skeleton project that uses it,
run:

```bash
mix nerves.new my_new_nerves_project --init-gadget
```

The default configuration for `nerves_init_gadget` is to attach to the `usb0`
interface. This is useful on boards that expose a USB gadget interface such as
the Raspberry Pi Zero and BeagleBone boards. You can change the default interface
by passing `--ifname INTERFACE`.

```bash
mix nerves.new my_new_nerves_project --init-gadget --ifname eth0
```

### mix local.nerves

This task checks [hex.pm](https://hex.pm/packages/nerves_bootstrap) for updates
to the `nerves_bootstrap` archive. If one exists, you'll be prompted to update.

### mix nerves.clean

This task cleans dependencies in a similar way to `mix deps.clean`, but it
additionally erases downloaded artifacts and build products from Nerves
packages.

### mix nerves.system.shell

This task starts up a shell in an environment suitable for modifying Nerves
systems. This allows you to interact with `make menuconfig` in Buildroot,
manually enable and build C libraries, the Linux kernel, bootloaders, and more.
Depending on your system, it may also start up Docker. See the Nerves
documentation for usage.

## Building systems and toolchains

Nerves expects systems and toolchains to include a URL to a precompiled build
artifact. Building these dependences can take hours in some cases, so Nerves
will not automatically compile them. It can do this, though, and depending on
your computer, it may even start up Docker to do the builds.

To force compilation to happen, add a `:nerves` option for the desired package
in your top level project:

```elixir
  {:nerves_system_rpi0, "~> 1.5", nerves: [compile: true]}
```
