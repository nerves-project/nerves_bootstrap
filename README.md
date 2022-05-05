# Nerves.Bootstrap

[![CircleCI](https://circleci.com/gh/nerves-project/nerves_bootstrap.svg?style=svg)](https://circleci.com/gh/nerves-project/nerves_bootstrap)
[![Hex.pm](https://img.shields.io/hexpm/v/nerves_bootstrap.svg)](https://hex.pm/packages/nerves_bootstrap)

Nerves.Bootstrap is an Elixir archive that brings Nerves support to Elixir's Mix
build tool. It also provides a new project generator, `mix nerves.new`.

We recommend reading the [Nerves Installation
Guide](https://hexdocs.pm/nerves/installation.html) for installing and using
Nerves. Read on for details specific to Nerves.Bootstrap.

## Installation

The first time you use Nerves and whenever you update your Elixir installation,
run the follow to install the official archive:

```bash
mix archive.install hex nerves_bootstrap
```

From then on, Nerves.Bootstrap checks for new versions and will let you know. To
manually upgrade either run the above line or the following:

```bash
mix local.nerves
```

If you need to force a specific version, run:

```bash
mix archive.install hex nerves_bootstrap 1.0.1
```

## Mix tasks

This section provides a high level overview of Mix tasks provided by
Nerves.Bootstrap. For additional details, run `mix help task`.

### mix nerves.new

A mix task for creating new Nerves projects.

```bash
mix nerves.new my_project
```

The generated project will support compilation for all of the officially
supported Nerves devices. Just like the Elixir new project generator,
`nerves.new` supports many options to tweak the output.

Generated projects will boot and provide an IEx prompt over the default console
for the device. Here's a script for creating a new project and building it for a
Raspberry Pi 3:

```bash
mix nerves.new my_project
cd my_project

# Set MIX_TARGET to select Raspberry Pi 3-specific dependencies in the mix.exs
export MIX_TARGET=rpi3

# Download dependencies, build firmware and write it to a MicroSD card
mix deps.get
mix firmware
mix burn
```

Generated projects include [NervesPack](https://hex.pm/packages/nerves_pack) in
their dependency list. NervesPack depends on most of the Nerves-specific
libraries that you'll need at the beginning of your project. This includes those
needed for networking, firmware updates, and various helpful utilities.  If you
want a minimal project that does not include NervesPack, pass
`--no-nerves-pack`:

```bash
mix nerves.new my_new_nerves_project --no-nerves-pack
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
artifact. Building these dependencies can take hours in some cases, so Nerves
will not automatically compile them. It can do this, though, and depending on
your computer, it may even start up Docker to do the builds.

To force compilation to happen, add a `:nerves` option for the desired package
in your top level project:

```elixir
  {:nerves_system_rpi0, "~> 1.5", nerves: [compile: true]}
```

## Local development

If you need to modify Nerves.Bootstrap, here's what you should do to get
the source code, build it and install your changes locally:

```bash
git clone https://github.com/nerves-project/nerves_bootstrap.git
cd nerves_bootstrap
mix do deps.get, archive.build, archive.install
```

## License

Copyright (C) 2017-22 Nerves Project Authors

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/l>

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
