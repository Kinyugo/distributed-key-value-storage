import Config

config :kv_server, :port, System.fetch_env!("PORT")
