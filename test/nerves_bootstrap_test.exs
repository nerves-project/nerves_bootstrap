defmodule Nerves.BootstrapTest do
  use ExUnit.Case

  test "aliases are injected properly" do
    deps_loadpaths = ["nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.deps.get"]
 
    aliases = Nerves.Bootstrap.add_aliases([])
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
  end

  test "custom aliases are maintained" do
    custom_aliases = [
      "deps.loadpaths": ["custom", "deps.loadpaths"],
      "deps.get": ["deps.get", "custom"],
      "custom": ["custom"]
    ]
    aliases = Nerves.Bootstrap.add_aliases(custom_aliases)

    assert Keyword.get(aliases, :"deps.loadpaths") == ["nerves.loadpaths", "custom", "deps.loadpaths"]
    assert Keyword.get(aliases, :"deps.get") == ["deps.get", "custom", "nerves.deps.get"]
    assert Keyword.get(aliases, :"custom") == ["custom"]
  end

  test "aliases are dropped if they already exist" do
    deps_loadpaths = ["nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.deps.get"]
 
    nerves_aliases = [
      "deps.loadpaths": deps_loadpaths
    ]

    aliases = Nerves.Bootstrap.add_aliases(nerves_aliases)
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
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
