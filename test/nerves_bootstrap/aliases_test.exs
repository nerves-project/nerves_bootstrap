# SPDX-FileCopyrightText: 2018 Justin Schneck
# SPDX-FileCopyrightText: 2022 Jon Carstens
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.AliasTest do
  use ExUnit.Case

  alias NervesBootstrap.Aliases

  test "aliases are injected properly" do
    deps_loadpaths = ["nerves.bootstrap", "nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.bootstrap", "nerves.deps.get"]
    deps_update = [&Aliases.deps_update/1]
    deps_precompile = ["nerves.bootstrap", "deps.precompile"]
    deps_compile = ["nerves.bootstrap", "nerves.loadpaths", "deps.compile"]

    aliases = Aliases.add_aliases([])
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

    aliases = Aliases.add_aliases(custom_aliases)

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
             &Aliases.deps_update/1
           ]

    assert Keyword.get(aliases, :custom) == ["custom"]
  end

  test "aliases are dropped if they already exist" do
    deps_loadpaths = ["nerves.bootstrap", "nerves.loadpaths", "deps.loadpaths"]
    deps_get = ["deps.get", "nerves.bootstrap", "nerves.deps.get"]
    deps_update = [&Aliases.deps_update/1]

    nerves_aliases = [
      "deps.loadpaths": deps_loadpaths
    ]

    aliases = Aliases.add_aliases(nerves_aliases)
    assert Keyword.get(aliases, :"deps.loadpaths") == deps_loadpaths
    assert Keyword.get(aliases, :"deps.get") == deps_get
    assert Keyword.get(aliases, :"deps.update") == deps_update
  end

  test "mix run delegates to Mix.Tasks.Run on host target" do
    # Mix.target() defaults to :host in tests, so this exercises the host branch
    Aliases.run(["-e", "nil"])
  end

  test "mix run prints an error on non-host targets" do
    previous_target = Mix.State.get(:target)
    previous_mix_target_env = System.get_env("MIX_TARGET")

    on_exit(fn ->
      Mix.State.put(:target, previous_target)

      case previous_mix_target_env do
        nil -> System.delete_env("MIX_TARGET")
        value -> System.put_env("MIX_TARGET", value)
      end
    end)

    System.put_env("MIX_TARGET", "rpi3")
    Mix.State.put(:target, :rpi3)

    Aliases.run([])

    assert_receive {:mix_shell, :error, message}

    text = IO.iodata_to_binary(message)
    assert text =~ "You are trying to run code compiled for the 'rpi3' target"
    assert text =~ "Please unset MIX_TARGET to run in host mode."
  end
end
