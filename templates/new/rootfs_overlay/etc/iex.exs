# Add Toolshed helpers to the IEx session
use Toolshed

try do
  if RingLogger in Application.get_env(:logger, :backends, []) do
    IO.puts("""
    RingLogger is collecting log messages from Elixir and Linux. To see the
    messages, either attach the current IEx session to the logger:

      RingLogger.attach

    or print the next messages in the log:

      RingLogger.next
    """)
  end
catch
  what, reason ->
    IO.puts("""
    Something was thrown in your iex.exs. It was caught so that it wouldn't
    exit the Erlang VM.

    #{inspect(what)}: #{inspect(reason)}
    """)
end

# Be careful when adding outside of the try...catch. Nearly any error can crash
# the VM and cause a reboot.
