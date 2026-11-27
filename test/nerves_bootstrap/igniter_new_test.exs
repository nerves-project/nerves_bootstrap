# SPDX-FileCopyrightText: 2026 Lars Wikman
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule NervesBootstrap.IgniterNewTest do
  use ExUnit.Case, async: true

  alias NervesBootstrap.IgniterNew

  @networking "nerves_ssh,mdns_lite,vintage_net,vintage_net_direct,vintage_net_ethernet,vintage_net_wifi,nerves_time,nerves_motd"
  @default_install "nerves," <> @networking

  describe "argv/2" do
    test "defaults" do
      assert IgniterNew.argv("my_device", []) ==
               ["my_device", "--install", @default_install, "--sup", "--no-git", "--yes"]
    end

    test "the path is passed as is" do
      assert ["some/where/my_device" | _] = IgniterNew.argv("some/where/my_device", [])
    end

    test "module" do
      assert IgniterNew.argv("my_device", module: "My.Device") ==
               [
                 "my_device",
                 "--install",
                 @default_install,
                 "--module",
                 "My.Device",
                 "--sup",
                 "--no-git",
                 "--yes"
               ]
    end

    test "app is passed on to mix new as one argument" do
      assert IgniterNew.argv("my_device", app: "my_fw") ==
               [
                 "my_device",
                 "--install",
                 @default_install,
                 "--sup",
                 "--no-git",
                 "--with-args=--app my_fw",
                 "--yes"
               ]
    end

    test "targets come last and in order so that they reach the installers" do
      argv = IgniterNew.argv("my_device", targets: [:rpi5, :rpi0])

      assert Enum.take(argv, -5) == ["--yes", "--target", "rpi5", "--target", "rpi0"]
    end

    test "no targets leaves the choice to mix nerves.install" do
      refute "--target" in IgniterNew.argv("my_device", targets: [])
    end

    test "everything" do
      assert IgniterNew.argv("path/to/my_device",
               app: "my_fw",
               module: "MyFw",
               targets: [:rpi4],
               nerves_pack?: false,
               prerelease?: false,
               install: ["nerves_motd"]
             ) ==
               [
                 "path/to/my_device",
                 "--install",
                 "nerves,nerves_motd",
                 "--module",
                 "MyFw",
                 "--sup",
                 "--no-git",
                 "--with-args=--app my_fw",
                 "--yes",
                 "--target",
                 "rpi4"
               ]
    end
  end

  describe "install_specs/1" do
    test "nerves and the networking libraries by default" do
      assert IgniterNew.install_specs([]) == ["nerves" | IgniterNew.networking_packages()]

      assert IgniterNew.install_specs(nerves_pack?: true) ==
               ["nerves" | IgniterNew.networking_packages()]

      assert Enum.join(IgniterNew.install_specs([]), ",") == @default_install
    end

    test "nerves_pack isn't installed" do
      refute "nerves_pack" in IgniterNew.install_specs([])
    end

    test "the order gives the config/target.exs of the project template" do
      # Installers put configuration for a new application at the top of the
      # file, so what's installed later ends up higher.
      packages = IgniterNew.networking_packages()
      index = fn package -> Enum.find_index(packages, &(&1 == package)) end

      assert index.("mdns_lite") < index.("vintage_net")
      assert index.("vintage_net") < index.("vintage_net_direct")
      assert index.("vintage_net_direct") < index.("vintage_net_ethernet")
      assert index.("vintage_net_ethernet") < index.("vintage_net_wifi")
    end

    test "without nerves_pack" do
      assert IgniterNew.install_specs(nerves_pack?: false) == ["nerves"]
    end

    test "prerelease pins the Nerves prerelease version" do
      "~> " <> version = NervesBootstrap.Versions.package_reqs().nerves_prerelease

      assert {:ok, %Version{pre: [_ | _]}} = Version.parse(version)

      assert IgniterNew.install_specs(prerelease?: true) ==
               ["nerves@#{version}" | IgniterNew.networking_packages()]

      assert IgniterNew.install_specs(prerelease?: true, nerves_pack?: false) ==
               ["nerves@#{version}"]
    end

    test "additional packages are appended" do
      assert IgniterNew.install_specs(
               nerves_pack?: false,
               install: ["nerves_hub_link", "alarmist,circuits_gpio@1.0"]
             ) == ["nerves", "nerves_hub_link", "alarmist", "circuits_gpio@1.0"]

      assert IgniterNew.install_specs(install: ["nerves_hub_link"]) ==
               ["nerves"] ++ IgniterNew.networking_packages() ++ ["nerves_hub_link"]
    end

    test "specs for the default packages replace them in place" do
      specs =
        IgniterNew.install_specs(
          install: ["vintage_net@0.13.8", "nerves@github:nerves-project/nerves@v2"]
        )

      assert hd(specs) == "nerves@github:nerves-project/nerves@v2"
      assert Enum.at(specs, 3) == "vintage_net@0.13.8"
      assert length(specs) == 1 + length(IgniterNew.networking_packages())

      assert hd(IgniterNew.install_specs(prerelease?: true, install: ["nerves@2.0.0"])) ==
               "nerves@2.0.0"
    end

    test "networking libraries can be picked with --no-nerves-pack" do
      assert IgniterNew.install_specs(nerves_pack?: false, install: ["nerves_ssh,mdns_lite"]) ==
               ["nerves", "nerves_ssh", "mdns_lite"]
    end

    test "nerves_pack can still be asked for" do
      assert IgniterNew.install_specs(nerves_pack?: false, install: ["nerves_pack"]) ==
               ["nerves", "nerves_pack"]
    end

    test "duplicates and blanks are dropped" do
      assert IgniterNew.install_specs(
               nerves_pack?: false,
               install: ["nerves_motd, nerves_motd,", ""]
             ) == ["nerves", "nerves_motd"]

      assert IgniterNew.install_specs(install: ["nerves_motd"]) ==
               ["nerves" | IgniterNew.networking_packages()]
    end

    test "relative paths are expanded" do
      assert IgniterNew.install_specs(
               nerves_pack?: false,
               install: ["nerves@path:../nerves", "foo@path:/abs/foo"]
             ) == ["nerves@path:#{Path.expand("../nerves")}", "foo@path:/abs/foo"]
    end
  end

  describe "run/1" do
    test "uses the configured runner" do
      Application.put_env(:nerves_bootstrap, :igniter_new_runner, fn argv ->
        send(self(), {:igniter_new, argv})
        :ok
      end)

      on_exit(fn -> Application.delete_env(:nerves_bootstrap, :igniter_new_runner) end)

      assert IgniterNew.run(["my_device"]) == :ok
      assert_received {:igniter_new, ["my_device"]}
    end
  end
end
