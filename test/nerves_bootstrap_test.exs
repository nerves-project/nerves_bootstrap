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

  test "check for update will exclude pre release" do
    current_version = Version.parse!("0.8.0")

    releases = [
      "0.8.2",
      "1.0.0-rc.0",
      "0.8.1"
    ]

    releases = Enum.map(releases, &Version.parse!/1)
    assert Version.parse!("0.8.2") == Nerves.Bootstrap.check_for_update(releases, current_version)
  end

  test "check for update will include pre release if on pre" do
    current_version = Version.parse!("1.0.0-rc.0")

    releases = [
      "1.1.0-rc.0",
      "1.0.0-rc.1",
      "0.8.2",
      "1.0.0-rc.0",
      "0.8.1"
    ]

    releases = Enum.map(releases, &Version.parse!/1)

    assert Version.parse!("1.0.0-rc.1") ==
             Nerves.Bootstrap.check_for_update(releases, current_version)
  end

  test "check for update moving from pre to stable" do
    current_version = Version.parse!("1.0.0-rc.0")

    releases = [
      "1.0.0",
      "1.0.0-rc.1",
      "0.8.2",
      "1.0.0-rc.0",
      "0.8.1"
    ]

    releases = Enum.map(releases, &Version.parse!/1)

    assert Version.parse!("1.0.0") ==
             Nerves.Bootstrap.check_for_update(releases, current_version)
  end

  test "check for update excluding pre release message" do
    current_version = Version.parse!("0.8.0")
    latest_version = Version.parse!("0.8.1")
    Nerves.Bootstrap.render_update_message(current_version, latest_version)
    assert_receive {:mix_shell, :info, [message]}
    assert message =~ "mix local.nerves"
  end

  test "check for update including pre release message" do
    current_version = Version.parse!("1.0.0-rc.0")
    latest_version = Version.parse!("1.0.0-rc.1")
    Nerves.Bootstrap.render_update_message(current_version, latest_version)
    assert_receive {:mix_shell, :info, [message]}
    assert message =~ "mix archive.install hex nerves_bootstrap 1.0.0-rc.1"
  end

  test "check for update moving from pre to stable message" do
    current_version = Version.parse!("1.0.0-rc.0")
    latest_version = Version.parse!("1.0.0")
    Nerves.Bootstrap.render_update_message(current_version, latest_version)
    assert_receive {:mix_shell, :info, [message]}
    assert message =~ "mix local.nerves"
  end
end
