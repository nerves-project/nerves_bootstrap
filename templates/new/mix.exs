defmodule <%= app_module %>.MixProject do
  use Mix.Project

  @app :<%= app_name %>
  @version "0.1.0"
<%= if nerves_pack? do %>  @all_targets <%= inspect(targets) %>
<% end %>
  def project do
    [
      app: @app,
      version: @version,
      elixir: "<%= elixir_req %>",
      archives: [nerves_bootstrap: "<%= bootstrap_req %>"],<%= if in_umbrella do %>
      deps_path: "../../deps",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock",<% end %>
      listeners: listeners(Mix.target(), Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [{@app, release()}]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {<%= app_module %>.Application, []}
    ]
  end

  def cli do
    [preferred_targets: [run: :host, test: :host]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "<%= package_reqs[:nerves] %>", runtime: false},

      {:shoehorn, "<%= package_reqs[:shoehorn] %>"},
      {:ring_logger, "<%= package_reqs[:ring_logger] %>"},
      {:toolshed, "<%= package_reqs[:toolshed] %>"},

      # Allow Nerves.Runtime on host to support development, testing and CI.
      # See config/host.exs for usage.
      {:nerves_runtime, "<%= package_reqs[:nerves_runtime] %>"},<%= if nerves_pack? do %>

      # Dependencies for all targets except :host
      {:nerves_pack, "<%= package_reqs[:nerves_pack] %>", targets: @all_targets},<% end %>

      # Dependencies for specific targets
      # NOTE: It's generally low risk and recommended to follow minor version
      # bumps to Nerves systems. Since these include Linux kernel and Erlang
      # version updates, please review their release notes in case
      # changes to your application are needed.
<%= Enum.map_join(targets, ",\n", &~s|      {:#{target_systems[&1]}, "#{package_reqs[target_systems[&1]]}", runtime: false, targets: :#{&1}}|) %>
    ]
  end

  def release do
    [
      overwrite: true,
<%= if nerves_pack? do %>      # Erlang distribution is not started automatically.
      # See https://nerves-pack.hexdocs.pm/readme.html#erlang-distribution
<% end %>      cookie: <%= if cookie do %>"<%= cookie %>"<% else %>"#{@app}_cookie"<% end %>,
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod or [keep: ["Docs"]]
    ]
  end

  # Uncomment the following line if using Phoenix > 1.8.
  # defp listeners(:host, :dev), do: [Phoenix.CodeReloader]
  defp listeners(_, _), do: []
end
