# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.NervesSyncTest do
  # The official targets, their Nerves systems, the version requirements for
  # new projects and the libraries that provide networking support are listed
  # here for the project template and `mix nerves.new --igniter`, and in the
  # Nerves library for `mix nerves.install`. Neither can depend on the other
  # (NervesBootstrap is an archive and Nerves must not need a particular
  # archive version to compile), so this test compares NervesBootstrap's
  # tables with the ones in the Nerves source code.
  #
  # The Nerves source is found by looking at the `NERVES_PATH` environment
  # variable and then for a checkout next to this one (`../nerves`). The tests
  # are skipped if there isn't one or if it predates `mix nerves.install`.
  #
  #     NERVES_PATH=~/src/nerves mix test test/nerves_bootstrap/nerves_sync_test.exs
  use ExUnit.Case, async: true

  alias NervesBootstrap.Versions

  @nerves_path System.get_env("NERVES_PATH") || Path.expand("../../../nerves", __DIR__)
  @igniter_ex Path.join(@nerves_path, "lib/nerves/igniter.ex")
  @install_ex Path.join(@nerves_path, "lib/mix/tasks/nerves.install.ex")

  if !File.regular?(@igniter_ex) or !File.regular?(@install_ex) do
    @moduletag skip:
                 "No Nerves source with mix nerves.install at #{@nerves_path}. Set NERVES_PATH."
  end

  test "official targets and systems match Nerves.Igniter.official_systems/0" do
    nerves = module_attribute!(@igniter_ex, :official_systems)
    reqs = Versions.package_reqs()

    bootstrap =
      Map.new(Mix.Tasks.Nerves.New.target_systems(), fn {target, system} ->
        {target, {system, Map.fetch!(reqs, system)}}
      end)

    assert bootstrap == nerves, """
    The target tables in nerves_bootstrap and Nerves are different.

    Update `@target_systems` in lib/mix/tasks/nerves.new.ex and
    `NervesBootstrap.Versions.package_reqs/0` in nerves_bootstrap or
    `@official_systems` in #{@igniter_ex}.
    """
  end

  test "every Nerves system with a version requirement has a target" do
    with_reqs =
      for {package, _req} <- Versions.package_reqs(),
          String.starts_with?(Atom.to_string(package), "nerves_system_"),
          do: package

    assert Enum.sort(with_reqs) ==
             Enum.sort(Map.values(Mix.Tasks.Nerves.New.target_systems()))
  end

  test "default targets match Nerves.Igniter.default_targets/0" do
    assert Mix.Tasks.Nerves.New.default_targets() ==
             module_attribute!(@igniter_ex, :default_targets)
  end

  test "versions of the packages in every project match mix nerves.install" do
    reqs = Versions.package_reqs()

    for {package, requirement} <- module_attribute!(@install_ex, :companions) do
      assert {package, requirement} == {package, Map.fetch!(reqs, package)}
    end
  end

  test "networking libraries of --igniter match the ones in the mix nerves.install docs" do
    assert NervesBootstrap.IgniterNew.networking_packages() ==
             module_attribute!(@install_ex, :networking_packages)
  end

  test "the templates have what mix nerves.install adds to config/target.exs" do
    # Advancing the clock at boot used to be tied to nerves_pack. The Igniter
    # installer always adds it, so the comment and setting need to stay the
    # same in both. This is the same for Nerves 1.x and Nerves 2.
    update_clock = module_attribute!(@install_ex, :update_clock)

    for template <- ["new", "new-2"] do
      target_exs =
        Path.expand("../../templates/#{template}/config/target.exs", __DIR__)
        |> File.read!()
        |> String.replace("\r\n", "\n")

      assert target_exs =~ update_clock
    end
  end

  # Return the value of a module attribute that's set to a literal without
  # compiling the file
  defp module_attribute!(path, name) do
    quoted = path |> File.read!() |> Code.string_to_quoted!(file: path)

    {_quoted, values} =
      Macro.prewalk(quoted, [], fn
        {:@, _, [{^name, _, [value]}]} = node, acc -> {node, [value | acc]}
        node, acc -> {node, acc}
      end)

    case values do
      [value] ->
        assert Macro.quoted_literal?(value), "expected @#{name} in #{path} to be a literal"
        {result, _binding} = Code.eval_quoted(value)
        result

      other ->
        flunk("expected one definition of @#{name} in #{path}, but found #{length(other)}")
    end
  end
end
