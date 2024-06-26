defmodule <%= app_module %>.MixProject do
  use Mix.Project

  @app :<%= app_name %>
  @version "0.1.0"
  @all_targets <%= inspect(Enum.map(targets, &elem(&1, 0))) %>

  def project do
    [
      app: @app,
      version: @version,
      elixir: "<%= elixir_req %>",
      archives: [nerves_bootstrap: "~> <%= bootstrap_vsn %>"],<%= if in_umbrella do %>
      deps_path: "../../deps",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock",<% end %>
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {<%= app_module %>.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      <%= nerves_dep %>,
      {:shoehorn, "~> <%= shoehorn_vsn %>"},
      {:ring_logger, "~> <%= ring_logger_vsn %>"},
      {:toolshed, "~> <%= toolshed_vsn %>"},

      # Allow Nerves.Runtime on host to support development, testing and CI.
      # See config/host.exs for usage.
      {:nerves_runtime, "~> <%= runtime_vsn %>"},<%= if nerves_pack? do %>

      # Dependencies for all targets except :host
      {:nerves_pack, "~> <%= nerves_pack_vsn %>", targets: @all_targets},<% end %>

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
<%= Enum.map_join(targets, ",\n", &~s|      {:nerves_system_#{elem(&1, 0)}, "~> #{elem(&1, 1)}", runtime: false, targets: :#{elem(&1, 0)}}|) %>
    ]
  end

  def release do
    [
      overwrite: true,
<%= if nerves_pack? do %>      # Erlang distribution is not started automatically.
      # See https://hexdocs.pm/nerves_pack/readme.html#erlang-distribution
<% end %>      cookie: <%= if cookie do %>"<%= cookie %>"<% else %>"#{@app}_cookie"<% end %>,
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end
end
