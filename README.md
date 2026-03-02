<!--
  SPDX-FileCopyrightText: 2018 Frank Hunleth
  SPDX-FileCopyrightText: 2019 Justin Schneck
  SPDX-FileCopyrightText: 2020 Jon Carstens
  SPDX-FileCopyrightText: 2022 Jason Axelson
  SPDX-License-Identifier: CC-BY-4.0
-->

# NervesBootstrap

[![Hex version](https://img.shields.io/hexpm/v/nerves_bootstrap.svg "Hex version")](https://hex.pm/packages/nerves_bootstrap)
[![API docs](https://img.shields.io/hexpm/v/nerves_bootstrap.svg?label=hexdocs "API docs")](https://hexdocs.pm/nerves_bootstrap/index.html)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/nerves-project/nerves_bootstrap/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/nerves-project/nerves_bootstrap/tree/main)
[![REUSE status](https://api.reuse.software/badge/github.com/nerves-project/nerves_bootstrap)](https://api.reuse.software/info/github.com/nerves-project/nerves_bootstrap)

NervesBootstrap is an Elixir archive that brings Nerves support to Elixir's Mix
build tool and provides a new project generator, `mix nerves.new`.

We recommend reading the [Nerves Installation
Guide](https://hexdocs.pm/nerves/installation.html) for installing and using
Nerves. Read on for details specific to NervesBootstrap.

## Installation

The first time you use Nerves and whenever you update your Elixir installation,
run the follow to install the official archive:

```bash
mix archive.install hex nerves_bootstrap
```

From then on, NervesBootstrap checks for new versions and will let you know. To
manually upgrade either run the above line or the following:

```bash
mix local.nerves
```

If you need to force a specific version, run:

```bash
mix archive.install hex nerves_bootstrap 1.14.3
```

## Mix tasks

This section provides a high level overview of Mix tasks provided by
NervesBootstrap. For additional details, run `mix help task`.

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

## Integration with your project

NervesBootstrap injects Nerves-specific build tasks into the `mix` build process via
an `Application.start/1` call in your project's `config.exs`. If you use `mix
nerves.new`, your project will be created with these lines and no additional
work is needed.

```elixir
# config/config.exs
import Config

Application.start(:nerves_bootstrap)
```

## Design

While the Nerves tooling provides many features, the two primary ones are the
ability to download pre-compiled build artifacts and then to set environment
variables to make native code compilers (e.g., C, C++, Rust, Zig, etc.) compile
for the right platform.

When Mix compiles a library, it makes sure to compile all of its dependencies
first. It would be easy if every Elixir library depended on Nerves, but no one
does that. Therefore, NervesBootstrap injects Mix aliases into the project being
built so that it's called before any library is built.

It's far easier to lock dependent library versions for regular Mix dependencies
(those listed in your `mix.exs`) than for Mix archives.  NervesBootstrap is a
Mix archive. To address this, as much code as possible is put in the [`Nerves`
library](https://github.com/nerves-project/nerves) which is then listed in the
`mix.exs` and can be version locked via the `mix.lock` file.

Therefore, what NervesBootstrap really does is ensure that Nerves and its
dependencies have been compiled. Then it runs a Mix task in the Nerves library
to instrument the build.

## Local development

If you need to modify NervesBootstrap, here's what you should do to get
the source code, build it and install your changes locally:

```bash
git clone https://github.com/nerves-project/nerves_bootstrap.git
cd nerves_bootstrap
mix do deps.get + archive.build + archive.install
```

## License

All original source code in this project is licensed under Apache-2.0.

This project follows the [REUSE recommendations](https://reuse.software).
