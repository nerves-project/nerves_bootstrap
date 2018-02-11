defmodule Nerves.BootstrapTest do
  use ExUnit.Case

  test "aliases are injected properly" do
    deps_loadpaths = ["nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.deps.get"]
    deps_update = [&Nerves.Bootstrap.Aliases.deps_update/1]

    aliases = Nerves.Bootstrap.add_aliases([])
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
    assert Keyword.get(aliases, :"deps.update") == deps_update
  end

  test "custom aliases are maintained" do
    custom_aliases = [
      "deps.loadpaths": ["custom", "deps.loadpaths"],
      "deps.get": ["deps.get", "custom"],
      "deps.update": ["custom"],
      custom: ["custom"]
    ]

    aliases = Nerves.Bootstrap.add_aliases(custom_aliases)

    assert Keyword.get(aliases, :"deps.loadpaths") == [
             "nerves.loadpaths",
             "custom",
             "deps.loadpaths"
           ]

    assert Keyword.get(aliases, :"deps.get") == ["deps.get", "custom", "nerves.deps.get"]

    assert Keyword.get(aliases, :"deps.update") == [
             "custom",
             &Nerves.Bootstrap.Aliases.deps_update/1
           ]

    assert Keyword.get(aliases, :custom) == ["custom"]
  end

  test "aliases are dropped if they already exist" do
    deps_loadpaths = ["nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.deps.get"]
    deps_update = [&Nerves.Bootstrap.Aliases.deps_update/1]

    nerves_aliases = [
      "deps.loadpaths": deps_loadpaths
    ]

    aliases = Nerves.Bootstrap.add_aliases(nerves_aliases)
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
    assert Keyword.get(aliases, :"deps.update") == deps_update
  end

  test "raise if deps.get alias is missing" do
    deps_loadpaths = ["nerves.loadpaths", "deps.loadpaths"]

    nerves_aliases = [
      "deps.loadpaths": deps_loadpaths
    ]

    assert_raise Mix.Error, fn ->
      Mix.Tasks.Nerves.Precompile.check_aliases(nerves_aliases)
    end
  end
end
