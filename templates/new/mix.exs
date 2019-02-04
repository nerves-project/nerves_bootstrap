defmodule <%= app_module %>.MixProject do
  use Mix.Project

  @all_targets <%= inspect(Enum.map(targets, &elem(&1, 0))) %>

  def project do
    [
      app: :<%= app_name %>,
      version: "0.1.0",
      elixir: "<%= elixir_req %>",
      archives: [nerves_bootstrap: "~> <%= bootstrap_vsn %>"],<%= if in_umbrella do %>
      deps_path: "../../deps",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock",<% end %>
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps()
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {<%= app_module %>.Application, []},
      extra_applications: [:logger, :runtime_tools]
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

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> <%= runtime_vsn %>", targets: @all_targets},<%= if init_gadget? do %>
      {:nerves_init_gadget, "~> <%= init_gadget_vsn %>", targets: @all_targets},<% end %>

      # Dependencies for specific targets
      <%= for {target, vsn} <- targets do %>
      {:<%= "nerves_system_#{target}" %>, "~> <%= vsn %>", runtime: false, targets: :<%= target %>},
      <% end %>
    ]
  end
end
