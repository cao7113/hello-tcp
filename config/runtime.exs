import Config

config :hello_tcp,
  port: System.get_env("PORT", "4000")
