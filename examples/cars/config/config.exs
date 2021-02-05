use Mix.Config

config :erlang_node_discovery,
  hosts: ["127.0.0.1", "crawlyui.com"],
  node_ports: [
    {:ui, 0}
  ]
