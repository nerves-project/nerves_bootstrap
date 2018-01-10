defmodule Nerves.BootstrapTest do
  use ExUnit.Case

  test "aliases are injected properly" do
    deps_precompile = ["nerves.precompile", "deps.precompile"]
    deps_loadpaths = ["deps.loadpaths", "nerves.loadpaths"]
    deps_get = ["deps.get", "nerves.deps.get"]
 
    aliases = Nerves.Bootstrap.add_aliases([])
    assert Keyword.get(aliases, :"deps.precompile") == deps_precompile
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
  end

  test "custom aliases are maintained" do
    custom_aliases = [
      "deps.precompile": ["custom", "deps.precompile"],
      "deps.loadpaths": ["custom", "deps.loadpaths"],
      "deps.get": ["deps.get", "custom"],
      "custom": ["custom"]
    ]
    aliases = Nerves.Bootstrap.add_aliases(custom_aliases)

    assert Keyword.get(aliases, :"deps.precompile") == ["nerves.precompile", "custom", "deps.precompile"]
    assert Keyword.get(aliases, :"deps.loadpaths") == ["custom", "deps.loadpaths", "nerves.loadpaths"]
    assert Keyword.get(aliases, :"deps.get") == ["deps.get", "custom", "nerves.deps.get"]
    assert Keyword.get(aliases, :"custom") == ["custom"]
  end
end
