defmodule <%= app_module %>.MixProject do
  use Mix.Project

  @target System.get_env("MIX_TARGET") || "host"

  def project do
    [
      app: :<%= app_name %>,
      version: "0.1.0",
      elixir: "<%= elixir_req %>",
      target: @target,
      archives: [nerves_bootstrap: "~> <%= bootstrap_vsn %>"],<%= if in_umbrella do %>
      deps_path: "../../deps/#{@target}",
      build_path: "../../_build/#{@target}",
      config_path: "../../config/config.exs",
      lockfile: "../../mix.lock.#{@target}",<% else %>
      deps_path: "deps/#{@target}",
      build_path: "_build/#{@target}",
      lockfile: "mix.lock.#{@target}",<% end %>
      start_permanent: Mix.env() == :prod,
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
      <%= nerves_dep %>,
      {:shoehorn, "~> <%= shoehorn_vsn %>"},
      {:ring_logger, "~> <%= ring_logger_vsn %>"}
    ] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host"), do: []

  defp deps(target) do
    [
      {:nerves_runtime, "~> <%= runtime_vsn %>"}<%= if init_gadget? do %>,
      {:nerves_init_gadget, "~> <%= init_gadget_vsn %>"}<% end %>
    ] ++ system(target)
  end

<%= for target <- targets do %>
  defp system("<%= target %>"), do: [{:<%= "nerves_system_#{target}" %>, "~> 1.0", runtime: false}]
<% end %>
  defp system(target), do: Mix.raise("Unknown MIX_TARGET: #{target}")
end
