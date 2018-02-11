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
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      aliases: ["loadconfig": &loadconfig/1],
      deps: deps()
    ]
  end

  def loadconfig(args) do
    try do
      Mix.Tasks.Nerves.Loadconfig.run(args)
    rescue
      _ ->
      Mix.Tasks.Loadconfig.run(args)
    end
  end

  # Run "mix help compile.app" to learn about applications.
  def application, do: application(@target)

  # Specify target specific application configurations
  # It is common that the application start function will start and supervise
  # applications which could cause the host to fail. Because of this, we only
  # invoke <%= app_module %>.start/2 when running on a target.
  def application("host") do
    [extra_applications: [:logger]]
  end

  def application(_target) do
    [mod: {<%= app_module %>.Application, []}, extra_applications: [:logger]]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [<%= nerves_dep %>] ++ deps(@target)
  end

  # Specify target specific dependencies
  defp deps("host"), do: []

  defp deps(target) do
    [
      {:shoehorn, "~> <%= shoehorn_vsn %>"},
      {:nerves_runtime, "~> <%= runtime_vsn %>"}
    ] ++ system(target)
  end

<%= for target <- targets do %>
  defp system("<%= target %>"), do: [{:<%= "nerves_system_#{target}" %>, ">= 0.0.0", runtime: false}]
<% end %>
  defp system(target), do: Mix.raise "Unknown MIX_TARGET: #{target}"

end
