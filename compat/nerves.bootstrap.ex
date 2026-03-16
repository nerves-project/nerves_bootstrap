# SPDX-FileCopyrightText: 2025 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule Nerves.Bootstrap do
  @moduledoc false

  # Do not use!
  # This is kept for compatibility with Nerves v1.4 and earlier. It was called
  # by `mix nerves.info`.
  @spec version() :: String.t()
  def version(), do: unquote(Mix.Project.config()[:version])
end
