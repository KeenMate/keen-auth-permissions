import Config

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"

File.regular?("config/.local.exs") && import_config(".local.exs")
