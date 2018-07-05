Mix.shell(Mix.Shell.Process)
File.rm_rf("test/tmp")
ExUnit.start()
