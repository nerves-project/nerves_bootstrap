# nerves_bootstrap

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
mix nerves.new my_new_nerves_project
```

The new project's `mix.exs` contains logic for building for any of the supported
hardware systems. Export the `MIX_TARGET` environment variable to select which
one that you want when you're building the project. If your project only
supports one target, then edit the generated `mix.exs` or specify the `--target`
option to `nerves.new` when running the generator. See `mix help nerves.new` for
all options.

NOTE: Currently you need to ensure that the `MIX_TARGET` environment variable is
set when building Nerves projects. It is used internally to decide whether to
apply hooks into the `mix` build process.

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
  {:nerves_system_rpi0, "~> 1.0", nerves: [compile: true]}
```
