defmodule Nerves.BootstrapTest do
  use ExUnit.Case

  test "aliases are injected properly" do
    deps_loadpaths = ["nerves.bootstrap", "nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.bootstrap", "nerves.deps.get"]
    deps_update = [&Nerves.Bootstrap.Aliases.deps_update/1]
    deps_precompile = ["nerves.bootstrap", "deps.precompile"]
    deps_compile = ["nerves.bootstrap", "nerves.loadpaths", "deps.compile"]

    aliases = Nerves.Bootstrap.add_aliases([])
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
    assert Keyword.get(aliases, :"deps.update") == deps_update
    assert Keyword.get(aliases, :"deps.precompile") == deps_precompile
    assert Keyword.get(aliases, :"deps.compile") == deps_compile
  end

  test "custom aliases are maintained" do
    custom_aliases = [
      "deps.loadpaths": ["custom", "nerves.bootstrap", "deps.loadpaths"],
      "deps.get": ["deps.get", "nerves.bootstrap", "custom"],
      "deps.update": ["custom"],
      custom: ["custom"]
    ]

    aliases = Nerves.Bootstrap.add_aliases(custom_aliases)

    assert Keyword.get(aliases, :"deps.loadpaths") == [
             "nerves.bootstrap",
             "nerves.loadpaths",
             "custom",
             "deps.loadpaths"
           ]

    assert Keyword.get(aliases, :"deps.get") == [
             "deps.get",
             "custom",
             "nerves.bootstrap",
             "nerves.deps.get"
           ]

    assert Keyword.get(aliases, :"deps.update") == [
             "custom",
             &Nerves.Bootstrap.Aliases.deps_update/1
           ]

    assert Keyword.get(aliases, :custom) == ["custom"]
  end

  test "aliases are dropped if they already exist" do
    deps_loadpaths = ["nerves.bootstrap", "nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.bootstrap", "nerves.deps.get"]
    deps_update = [&Nerves.Bootstrap.Aliases.deps_update/1]

    nerves_aliases = [
      "deps.loadpaths": deps_loadpaths
    ]

    aliases = Nerves.Bootstrap.add_aliases(nerves_aliases)
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
    assert Keyword.get(aliases, :"deps.update") == deps_update
  end
end
