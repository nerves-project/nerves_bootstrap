IO.puts("""

\e[0m\e[1;34m.NNNa.    \e[36mjAA,\e[0m
\e[1;34m.M|\e[0m \e[1;34m.TMa.\e[0m  \e[1;36m.p:\e[0m
\e[1;34m.M|\e[36m W+.\e[34m.TM`\e[36m.p:\e[0m   N  E  R  V  E  S
\e[1;34m,M|\e[0m  \e[1;36m.7Wa,\e[0m \e[1;36m.p:
\e[34m,MME\e[0m     \e[1;36m7TTY'\e[0m
""")

# Add Toolshed helpers to the IEx session
use Toolshed

if RingLogger in Application.get_env(:logger, :backends, []) do
  IO.puts("""
  RingLogger is collecting log messages from Elixir and Linux. To see the
  messages, either attach the current IEx session to the logger:

    RingLogger.attach

  or print the next messages in the log:

    RingLogger.next
  """)
end
