use Mix.Config

# Configure shoehorn to use the default handler in prod.
# The default handler will call `:erlang.halt()` when an 
# OTP application exits.
config :shoehorn,
  handler: Shoehorn.Handler.Default
