# nerves_bootstrap

[![Hex.pm](https://img.shields.io/hexpm/v/nerves_bootstrap.svg)](https://hex.pm/packages/nerves_bootstrap)

See the [Nerves Installation Guide](https://hexdocs.pm/nerves/installation.html)
for using Nerves. It includes `nerves_bootstrap` installation instructions.

## Installation

To install for the first time:

```bash
mix archive.install hex nerves_bootstrap
```

To update your `nerves_bootstrap`, you may either run the installation line above or:

```bash
mix local.nerves
```

Finally, if you want the latest and greatest:

```bash
git clone https://github.com/nerves-project/nerves_bootstrap.git
cd nerves_bootstrap
mix deps.get
mix archive.build
mix archive.install
```

## Mix tasks

### mix nerves.new

A mix task for creating new Nerves projects.

```bash
mix nerves.new my_new_nerves_project
```

### nerves.precompile and nerves.loadpaths

Precompile and loadpaths tasks that pull in the code needed to build Nerves projects. These are added to the `aliases` in your `mix.exs`:

```elixir
  def project do
    [
      ...
      aliases: aliases(),
      ...
    ]
  end

  defp aliases do
    [
      "deps.precompile": ["nerves.precompile", "deps.precompile"],
      "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]
    ]
  end
```

Creating your projects with `mix nerves.new` adds these lines for you.
