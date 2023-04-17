# This file is responsible for configuring your application and its
# dependencies.
#

if Mix.target() != :host do
  # Enable the Nerves integration with Mix
  Application.start(:nerves_bootstrap)

  config :<%= app_name %>, target: Mix.target()
  # Customize non-Elixir parts of the firmware. See
  # https://hexdocs.pm/nerves/advanced-configuration.html for details.

  config :nerves, :firmware, rootfs_overlay: "rootfs_overlay"

  # Set the SOURCE_DATE_EPOCH date for reproducible builds.
  # See https://reproducible-builds.org/docs/source-date-epoch/ for more information

  config :nerves, source_date_epoch: "<%= source_date_epoch %>"
end

if Mix.target() == :host do
  import_config "host.exs"
else
  import_config "target.exs"
end
