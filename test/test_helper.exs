config_path = Path.join([File.cwd!(), "test", "tmp"])

config_path
|> File.mkdir_p()

System.put_env("NERVES_BOOTSTRAP_CONFIG_DIR", config_path)

Mix.shell(Mix.Shell.Process)

assert_timeout = String.to_integer(
  System.get_env("ELIXIR_ASSERT_TIMEOUT") || "200"
)

Code.ensure_loaded(Nerves.Bootstrap)

ExUnit.start(assert_receive_timeout: assert_timeout)
