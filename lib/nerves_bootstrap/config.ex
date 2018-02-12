defmodule Nerves.Bootstrap.Config do
  @config ".bootstrap_config"
  @config_dir "~/.nerves"

  defstruct version: nil

  def create(opts \\ []) do
    %__MODULE__{
      version: Keyword.get(opts, :version, Nerves.Bootstrap.version())
    }
  end

  def read() do
    case File.read(config_file()) do
      {:ok, config} ->
        {:ok, :erlang.binary_to_term(config)}

      error ->
        error
    end
  end

  def write(config) do
    config_file()
    |> Path.basename()
    |> File.mkdir_p()

    File.write(config_file(), :erlang.term_to_binary(config))
  end

  def upgrade() do
    case read() do
      {:ok, config} ->
        if Version.compare(config.version, Nerves.Bootstrap.version()) != :eq do
          config
          |> Map.put(:version, Nerves.Bootstrap.version())
          |> write()
        end

      _ ->
        create()
        |> write()
    end
  end

  def config_file() do
    (System.get_env("NERVES_BOOTSTRAP_CONFIG_DIR") || @config_dir)
    |> Path.join(@config)
    |> Path.expand()
  end
end
