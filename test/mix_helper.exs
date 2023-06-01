Mix.shell(Mix.Shell.Process)

defmodule MixHelper do
  @moduledoc false

  import ExUnit.Assertions

  # Much <3 to Phoenix for this code
  @spec tmp_path() :: binary()
  def tmp_path() do
    Path.expand("../../tmp", __DIR__)
  end

  @spec in_tmp(atom(), (-> any())) :: any()
  def in_tmp(which, function) do
    path = Path.join(tmp_path(), to_string(which))
    File.rm_rf!(path)
    File.mkdir_p!(path)
    File.cd!(path, function)
  end

  @spec assert_file(File.t()) :: :ok | no_return()
  def assert_file(file) do
    assert File.regular?(file), "Expected #{file} to exist, but does not"
  end

  @spec refute_file(File.t()) :: :ok | no_return()
  def refute_file(file) do
    refute File.regular?(file), "Expected #{file} to not exist, but it does"
  end

  @spec assert_file(File.t(), (binary() -> :ok)) :: :ok | no_return()
  def assert_file(file, match) when is_function(match, 1) do
    assert_file(file)
    match.(File.read!(file))
  end
end
